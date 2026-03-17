<cfsetting enablecfOutputOnly=true>
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
<cfparam name="url.editor" 				default="vscode">
<cfparam name="url.bundlesPattern" 		default="">

<!--- Streaming mode: streams results via Server-Sent Events (SSE) for real-time progress --->
<cfparam name="url.streaming"						default="false" type="boolean">
<cfparam name="url.dryRun"							default="false" type="boolean">

<!--- Code Coverage requires FusionReactor --->
<cfparam name="url.coverageEnabled"					default="false" type="boolean">
<cfparam name="url.coveragePathToCapture"			default="#expandPath( '/testbox/system/' )#">
<cfparam name="url.coverageWhitelist"				default="">
<cfparam name="url.coverageBlacklist"				default="/stubs/**,/modules/**,/coverage/**,Application.cfc,Application.bx">

<!--- FYI the "coverageBrowserOutputDir" folder will be DELETED and RECREATED each time
	  you generate the report. Don't point this setting to a folder that has other important
	  files. Pick a blank, essentially "temp" folder somewhere. Brad may or may not have
	  learned this the hard way. Learn from his mistakes. :) --->
<cfparam name="url.coverageBrowserOutputDir"		default="#expandPath( '/tests/results/coverageReport' )#">

<!--- Include the appropriate runner based on streaming mode --->
<cfif url.streaming && !url.dryRun>
	<!--- Stream results in real-time via SSE --->
	<cfinclude template="/testbox/system/runners/StreamingRunner.cfm">
<cfelse>
	<!--- Traditional batch results --->
	<cfinclude template="/testbox/system/runners/HTMLRunner.cfm">
</cfif>
