<cfsetting showDebugOutput="false">
<!--- Executes all tests in the 'specs' folder with simple reporter by default --->
<cfparam name="url.reporter" 			default="simple">
<cfparam name="url.directory" 			default="tests.specs">
<cfparam name="url.recurse" 			default="true" type="boolean">
<cfparam name="url.bundles" 			default="">
<cfparam name="url.labels" 				default="">
<cfparam name="url.excludes" 			default="">
<cfparam name="url.reportpath" 			default="#expandPath( "/tests/results" )#">
<cfparam name="url.propertiesFilename" 	default="TEST.properties">
<cfparam name="url.propertiesSummary" 	default="false" type="boolean">

<cfparam name="url.coverageEnabled"					default="true" type="boolean">
<cfparam name="url.coverageSonarQubeXMLOutputPath"	default="">
<cfparam name="url.coveragePathToCapture"			default="#expandPath( '/testbox/system/' )#">
<cfparam name="url.coverageWhitelist"				default="">
<cfparam name="url.coverageBlacklist"				default="/stubs/**,/modules/**,/coverage/**,Application.cfc">
<cfparam name="url.coverageBrowserOutputDir"		default="#expandPath( '/tests/results/coverageReport' )#">

<!--- Include the TestBox HTML Runner --->
<cfinclude template="/testbox/system/runners/HTMLRunner.cfm" >