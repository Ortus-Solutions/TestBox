<cfcomponent name="mxunit.framework.RemoteFacade" hint="Main default interface into MXUnit framework from the MXUnit Ecplise Plugin." wsversion="1">

	<cfset cu = createObject("component","mxunit.framework.ComponentUtils")>
	<cfset cache = createObject("component","mxunit.framework.RemoteFacadeObjectCache")>
	<cfset ConfigManager = createObject("component","mxunit.framework.ConfigManager")>

	<cffunction name="ping" output="false" access="remote" returntype="boolean" hint="returns true">
		<cfreturn true>
	</cffunction>

	<cffunction name="initializeSuitePool" access="remote" returntype="void">
		<cfset cache.initializeSuitePool()>
	</cffunction>

	<cffunction name="purgeSuitePool" access="remote" returntype="numeric">
		<cfreturn cache.purgeSuitePool()>
	</cffunction>

	<cffunction name="getServerType" output="false" access="remote" returntype="String" hint="returns the server type, whether coldfusion or bluedragon">
		<cfreturn server.ColdFusion.ProductName>
	</cffunction>

	<cffunction name="getFrameworkVersion" output="false" access="remote" returntype="String" hint="returns the current framework version in form of major.minor.buildnum">
		<cfreturn "2.4.0" />
	</cffunction>

	<cffunction name="getFrameworkDate" output="false" access="remote" returntype="Date" hint="returns the current framework version date in form of mm/dd/yyyy">
		<cfreturn now() />
	</cffunction>

	<cffunction name="startTestRun" access="remote" returntype="string">
		<cfset var useCache = false>
		<cfset ConfigManager.ConfigManager()>
		<cfset useCache = configManager.getConfigElementValue("pluginControl","UseRemoteFacadeObjectCache")>

		<cfif useCache>
			<cfreturn cache.startTestRun()>
		<cfelse>
			<cfreturn "">
		</cfif>

	</cffunction>

	<cffunction name="getObject" access="package" returntype="any">
		<cfargument name="componentName" type="String" required="true">
		<cfargument name="testRunKey" type="string" required="true" hint="the key returned from startTestRun; used for managing the pool of components">
		<cfreturn cache.getObject(componentName, testRunKey)>
	</cffunction>

	<cffunction name="endTestRun" access="remote" returntype="string" hint="ensures proper cleanup">
		<cfargument name="TestRunKey" type="string" required="true" hint="the key returned from startTestRun; used for managing the pool of components">

		<!---run all components' afterTests() --->
		<cfset var pool = cache.getSuitePool()>
		<cfset var componentName = "">
		<cfset var testCase = "">

		<cfif structKeyExists( pool, testRunKey )>
			<cfloop collection="#pool[testRunKey].components#" item="componentName">
				<cftry>
					<cfset testCase = pool[testRunKey].components[componentName]>
					<cfset testCase.enableAfterTests()>
					<cfset testCase.afterTests()>

				<cfcatch>
					<cflog text="MXUnit afterTests() Exception from Eclipse Remote Facade. Component Name: #componentName#. Error: #cfcatch.message#; #cfcatch.detail#">
				</cfcatch>
				</cftry>
			</cfloop>
		</cfif>
		<cfreturn cache.endTestRun(TestRunKey)>
	</cffunction>

	<cffunction name="executeTestCase" access="remote" returntype="struct">
		<cfargument name="componentName" type="String" required="true">
		<cfargument name="methodNames" type="String" required="true" hint="pass empty string to run all methods. pass list of valid method names to run individual methods">
		<cfargument name="TestRunKey" type="string" required="true" hint="the key returned from startTestRun; used for managing the pool of components">
		<cfset var s_results = structNew()>
		<cfset var key = "">
		<cfset var suite = createObject("component","mxunit.framework.TestSuite").testSuite()>
		<cfset var testResult = "">
		<!--- the "baseTarget" is the actual test case, underneath its layers of test decorators. When we start the test case, we want the pure object, not the decorated object --->
		<cfset var obj = getObject(componentName, TestRunKey).getBaseTarget()>
		<cfset var componentPath = getMetadata(obj).path>
		<cfif NOT structKeyExists(request,"debugBuffer")>
			<cfset request.debugBuffer = [] />
		</cfif>
		<cfset request.debug = requestDebugFunction />

		<cfset actOnTestCase(obj)>

		<!--- disable afterTests... we'll run them all during endTestRun --->
<!---
		<cfset obj.disableAfterTests()>
 --->

		<cfif len(methodNames)>
			<cfset suite.add(componentName, methodNames, obj)>
		 <cfelse>
			<cfset suite.addAll(componentName, obj)>
		</cfif>
		<cfset testResult = suite.run()>
		<cfset s_results = testResultToStructs(methodNames,testResult.getResults(), componentPath)>
		<cfreturn s_results>
	</cffunction>

	<cffunction name="requestDebugFunction">
		<cfargument name="var" />
		<cfset arrayAppend( request.debugBuffer, duplicate(arguments.var) ) />
	</cffunction>

	<cffunction name="getComponentMethods" access="remote" returntype="array">
		<cfargument name="componentName" required="true" type="string" hint="">
		<cfset var methods = arrayNew(1)>
		<cfset var obj = "">
		<!--- by doing this instead of letting it throw an error
		we ensure that the error (most likely a parse error)
		continues to show up when they run the test.  --->
		<cftry>
			<cfset obj = createObject("component", ComponentName).TestCase()>
			<cfset methods = obj.getRunnableMethods()>
		<cfcatch>
			<cfset ArrayAppend(methods, listLast(arguments.ComponentName, ".") & " <ERROR: #cfcatch.Message#>")>
		</cfcatch>
		</cftry>

		<cfreturn methods>
	</cffunction>


<!---	<cffunction name="getComponentMethodsRich2" access="remote" returntype="array">
		<cfset var bean = {dataprovidertype="excel", rows=50}>
		<cfreturn [bean]>
	</cffunction>--->

	<cffunction name="actOnTestCase" access="public" hint="an 'Interceptor' for custom remote facades. This will enable you to act on each test case object, possibly injecting additional data, etc" output="false">
		<cfargument name="testCase" required="true" hint="">

	</cffunction>

	<cffunction name="testResultToStructs" hint="turns the TestResult item into a struct for passing to eclipse. It will only ever process a single component under test, although I did build it to loop over the array of tests returned from the TestResult, although currently there is no condition under which that will ever be more than a single-element array" access="public">
		<cfargument name="methodNames" required="true">
		<cfargument name="testResult" required="true">
		<cfargument name="componentPath" required="true" hint="the full filesystem path to the component under test">

		<cfset var bundleStats = testResult.getBundleStats() />
		<cfset var s_results = structNew()>
		<cfset var s_test = structNew()>
		<cfset var test = 1>
		<cfset var tag = 1>
		<cfset var i = 1>
		<cfset var t = "">
		<cfset var iDebug = 1>
		<cfset var debugString = "">
		<cfset var isFrameworkTest = cu.isFrameworkTemplate(ComponentPath)>
    <cfif arrayLen(bundleStats[1].suiteStats)>
  		<cfset var a_tests = bundleStats[1].suiteStats[1].specStats>
    <cfelse>
      <cfset s_test = {name=listFirst(methodNames),status="failure",totalduration=0,failmessage="fail",failorigin="here",error=bundleStats[1].GLOBALEXCEPTION}>
      <cfset a_tests[1] = s_test />
    </cfif>
		<cfif ArrayLen(bundleStats[1].debugbuffer)>
			<cfsavecontent variable="debugString">
				<cfloop from="1" to="#ArrayLen(request.debugbuffer)#" index="iDebug">
					<cfdump var="#request.debugbuffer[iDebug]#">
				</cfloop>
				<cfloop from="1" to="#ArrayLen(bundleStats[1].debugbuffer)#" index="iDebug">
					<cfdump var="#bundleStats[1].debugbuffer[iDebug]#">
				</cfloop>
			</cfsavecontent>
		<cfelseif ArrayLen(request.debugbuffer)>
			<cfsavecontent variable="debugString">
				<cfloop from="1" to="#ArrayLen(request.debugbuffer)#" index="iDebug">
					<cfdump var="#request.debugbuffer[iDebug]#">
				</cfloop>
			</cfsavecontent>
		<cfelse>
			<cfset debugString = "<p class='nodebugresults'>No calls made to debug().</p> ">
		</cfif>

		<cfloop from="1" to="#ArrayLen(a_tests)#" index="test">
			<cfset s_test = a_tests[test]>
			<cfif not StructKeyExists(s_results,bundleStats[1].path)>
				<cfset s_results[bundleStats[1].path] = structNew()>
			</cfif>
			<cfset s_results[bundleStats[1].path][s_test.name] = structNew()>

			<cfset t = s_results[bundleStats[1].path][s_test.name]>

			<cfset t.OUTPUT = debugString>
			<cfset t.MESSAGE = "">
			<cfset t.RESULT = s_test.status>
			<cfset t.TIME = javacast("int",s_test.totalduration)>
			<cfset t.EXPECTED = "">
			<cfset t.ACTUAL = s_test.FAILMESSAGE>
			<!--- <cfset t.httprequestdata = getHTTPRequestData()> --->
			<cfif isArray(s_test.FAILORIGIN) && arrayLen(s_test.FAILORIGIN)>
				<cfset t.EXCEPTION = formatExceptionKey(s_test.FAILORIGIN[1].type)>
				<cfset t.MESSAGE = s_test.failmessage>
				<!--- <cfset t.TagContext = s_test.error.tagcontext>	 --->
				<cfset t.TAGCONTEXT = ArrayNew(1)>
				<cfset i = 1>
				<cfloop from="1" to="#ArrayLen(s_test.failorigin)#" index="tag">
					<cfif FileExists(s_test.failorigin[tag].template)>
						<!---<cflog text=" #s_test.error.tagcontext[tag].template# #isFrameworkTest# OR NOT #cu.isFrameworkTemplate(s_test.error.tagcontext[tag].template)#" >--->
						<cfif isFrameworkTest OR NOT cu.isFrameworkTemplate(s_test.failorigin[tag].template)>
							<cfset t.TAGCONTEXT[i] = structNew()>
							<cfset t.TAGCONTEXT[i].FILE = s_test.failorigin[tag].template>
							<cfset t.TAGCONTEXT[i].LINE = javacast("int",s_test.failorigin[tag].line)>
							<cfset i = i + 1>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
			<cfif structKeyList(s_test.error) NEQ "">
				<cfset t.EXCEPTION = formatExceptionKey(s_test.error.type)>
				<cfset t.MESSAGE = s_test.error.message>
				<cfif len(s_test.error.detail)>
					<cfset t.MESSAGE = t.MESSAGE & " " & s_test.error.detail>
				</cfif>
				<!--- <cfset t.TagContext = s_test.error.tagcontext>	 --->
				<cfset t.TAGCONTEXT = ArrayNew(1)>
				<cfset i = 1>
					<!---		 --->
				<cfloop from="1" to="#ArrayLen(s_test.error.tagcontext)#" index="tag">
					<cfif FileExists(s_test.error.tagcontext[tag].template)>
						<!---<cflog text=" #s_test.error.tagcontext[tag].template# #isFrameworkTest# OR NOT #cu.isFrameworkTemplate(s_test.error.tagcontext[tag].template)#" >--->
						<cfif isFrameworkTest OR NOT cu.isFrameworkTemplate(s_test.error.tagcontext[tag].template)>
							<cfset t.TAGCONTEXT[i] = structNew()>
							<cfset t.TAGCONTEXT[i].FILE = s_test.error.tagcontext[tag].template>
							<cfset t.TAGCONTEXT[i].LINE = javacast("int",s_test.error.tagcontext[tag].line)>
							<cfset i = i + 1>
						</cfif>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>

		<cfreturn s_results>
	</cffunction>

	<cffunction name="formatExceptionKey" access="package" hint="ensures a string in the EXCEPTION key. This is necessitated by a weirdo bug in CF with NonArrayExceptions" returntype="string">
		<cfargument name="ErrorType" required="true" type="any" hint="the TYPE key from the cfcatch struct">

		<cfif isSimpleValue(ErrorType)>
			<cfreturn ErrorType>
		<cfelse>
			<cfreturn "Exception[ComplexValue]: " & ErrorType.toString()>
		</cfif>
	</cffunction>

</cfcomponent>