<cfset cDir = getDirectoryFromPath( getCurrentTemplatePath() )>
<cfoutput>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="generator" content="TestBox v#testbox.getVersion()#">
	<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

	<script>#fileRead( '#cDir#/js/jquery.js' )#</script>
	<style>
	.dots{ font-size: 60px; }
	</style>
	<script>
	function showInfo( failMessage, specID, isError ){
		if( failMessage.length ){
			alert( "Failure Message: " + failMessage );
		}
		else if( isError || isError == 'yes' || isError == 'true' ){
			$("##error_" + specID).fadeToggle();
		}
	}
	function toggleDebug( specid ){
		$("div.debugdata").each( function(){
			var $this = $( this );

			// if bundleid passed and not the same bundle
			if( specid != undefined && $this.attr( "data-specid" ) != specid ){
				return;
			}
			// toggle.
			$this.fadeToggle();
		});
	}
	</script>
</head>
<body>

	<!-- Header --->
	<p>TestBox v#testbox.getVersion()#</p>

	<!-- Stats --->
	<div class="border my-1 p-1"id="globalStats">
		<div class="buttonBar">
			<a class="btn btn-primary btn-sm m-1 float-right" href="#variables.baseURL#" title="Run all the tests">Run All</a>
		</div>

		<cfif results.getTotalFail() gt 0>
			<cfset totalClass = "text-warning">
		<cfelseif results.getTotalError() gt 0>
			<cfset totalClass = "text-danger">
		<cfelse>
			<cfset totalClass = "text-success">
		</cfif>
		<p>
		<span class="#totalClass#">#results.getTotalSpecs()# test(s) in #results.getTotalSuites()# suite(s) from #results.getTotalBundles()# bundle(s) completed </span> (#results.getTotalDuration()# ms)
		<cfif results.getCoverageEnabled()>
			Coverage: #round( results.getCoverageData().stats.percTotalCoverage*100 )#%
		</cfif>
		</p>
		<span class="badge badge-success"	data-status="passed">Pass: #results.getTotalPass()#</span>
		<span class="badge badge-warning"	data-status="failed">Failures: #results.getTotalFail()#</span>
		<span class="badge badge-danger" 	data-status="error">Errors: #results.getTotalError()#</span>
		<span class="badge badge-info"      data-status="skipped">Skipped: #results.getTotalSkipped()#</span>
	</div>

	<!--- Dots --->
	<div class="dots">
		<!--- Iterate over bundles --->
		<cfloop array="#variables.bundleStats#" index="thisBundle">
			<!-- Iterate over suites -->
			<cfloop array="#thisBundle.suiteStats#" index="suiteStats">
				#genSuiteReport( suiteStats, thisBundle )#
			</cfloop>
		</cfloop>
	</div>

	<div style="clear:both;margin:20px">&nbsp;</div>

	<!--- Debug Panel --->
	<cfloop array="#variables.bundleStats#" index="thisBundle">

		<!-- Global Error --->
		<cfif !isSimpleValue( thisBundle.globalException )>
			<h2>Global Bundle (#thisBundle.name#) Exception<h2>
			<cfdump var="#thisBundle.globalException#" />
		</cfif>

		<!--- Debug Panel --->
		<cfif arrayLen( thisBundle.debugBuffer )>
			<h2>Debug Stream: #thisBundle.path# <button class="btn btn-sm btn-primary" onclick="toggleDebug( '#thisBundle.id#' )" title="Toggle the test debug stream"><i class="fas fa-plus-square"></i></button></h2>
			<div class="debugdata" style="display:none:" data-specid="#thisBundle.id#">
				<p>The following data was collected in order as your tests ran via the <em>debug()</em> method:</p>
				<cfdump var="#thisBundle.debugBuffer#" />
			</div>
		</cfif>
	</cfloop>

	</body>
</html>

<!--- Recursive Output --->
<cffunction name="genSuiteReport" output="false">
	<cfargument name="suiteStats">
	<cfargument name="bundleStats">

	<cfset var thisSpec = "">

	<cfsavecontent variable="local.report">
		<cfoutput>

			<!--- Iterate over suite specs --->
			<cfloop array="#arguments.suiteStats.specStats#" index="thisSpec">
				<a href="javascript:showInfo( '#JSStringFormat( thisSpec.failMessage )#', '#thisSpec.id#', '#lcase( NOT structIsEmpty( thisSpec.error ) )#' )"
				   title="#encodeForHTML( thisSpec.name )# (#thisSpec.totalDuration# ms)"
				   data-info="#encodeForHTML( thisSpec.failMessage )#"><span class="#lcase( thisSpec.status )#">.</span></a>

				<div style="display:none;" id="error_#thisSpec.id#"><cfdump var="#thisSpec.error#"></div>
			</cfloop>

			<!--- Do we have nested suites --->
			<cfif arrayLen( arguments.suiteStats.suiteStats )>
				<cfloop array="#arguments.suiteStats.suiteStats#" index="local.nestedSuite">
					#genSuiteReport( local.nestedSuite, arguments.bundleStats )#
				</cfloop>
			</cfif>

		</cfoutput>
	</cfsavecontent>

	<cfreturn local.report>
</cffunction>
</cfoutput>