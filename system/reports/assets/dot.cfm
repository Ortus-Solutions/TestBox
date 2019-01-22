<cfset cDir = getDirectoryFromPath( getCurrentTemplatePath() )>
<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<meta name="generator" content="TestBox v#testbox.getVersion()#">
		<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

		<script
  src="https://code.jquery.com/jquery-3.3.1.min.js"
  integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8="
  crossorigin="anonymous"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.6/umd/popper.min.js" integrity="sha384-wHAiFfRlMFy6i5SRaxvfOCifBUQy1xHdJ/yoi7FRNXMRBu5WHdZYu1hA6ZOblgut" crossorigin="anonymous"></script>
		<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>
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

		<style>
			.dots {
				font-size: 60px;
				line-height: 40px;
			}
		</style>
		<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" integrity="sha384-UHRtZLI+pbxtHCWp1t77Bi1L4ZtiqrqD80Kn4Z8NTSRyMA2Fd33n5dQ8lWUE00s/" crossorigin="anonymous">
		<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
	</head>
	<body>
		<div class="container my-3">
			<!-- Header --->
			<p>TestBox v#testbox.getVersion()#</p>

			<!-- Stats --->
			<div class="border my-1 p-1 bg-light clearfix"id="globalStats">
				<div class="buttonBar">
					<a class="btn btn-primary btn-sm m-1 float-right" href="#variables.baseURL#&opt_run=true&target=#URL.target#" title="Run the tests">Rerun Test</a>
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
					<br>Coverage: #round( results.getCoverageData().stats.percTotalCoverage*100 )#%
				</cfif>
				<br>
				<span class="badge badge-success"	data-status="passed">Pass: #results.getTotalPass()#</span>
				<span class="badge badge-warning"	data-status="failed">Failures: #results.getTotalFail()#</span>
				<span class="badge badge-danger" 	data-status="error">Errors: #results.getTotalError()#</span>
				<span class="badge badge-info"      data-status="skipped">Skipped: #results.getTotalSkipped()#</span>
				</p>
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

			<!--- Debug Panel --->
			<cfloop array="#variables.bundleStats#" index="thisBundle">

				<!-- Global Error --->
				<cfif !isSimpleValue( thisBundle.globalException )>
					<h2>Global Bundle (#thisBundle.name#) Exception<h2>
					<cfdump var="#thisBundle.globalException#" />
				</cfif>

				<!--- Debug Panel --->
				<cfif arrayLen( thisBundle.debugBuffer )>
					<h2>Debug Stream: #thisBundle.path#&nbsp;
						<button class="btn btn-sm btn-primary" onclick="toggleDebug( '#thisBundle.id#' )" title="Toggle the test debug stream">
							<i class="fas fa-plus-square"></i>
						</button>
					</h2>
					<div class="debugdata" style="display:none;" data-specid="#thisBundle.id#">
						<p>The following data was collected in order as your tests ran via the <em>debug()</em> method:</p>
						<cfdump var="#thisBundle.debugBuffer#" />
					</div>
				</cfif>
			</cfloop>
		</div>
	</body>
</html>

<cffunction name="statusPlusBootstrapClass" output="false">
	<cfargument name="status">

	<cfif lcase( arguments.status ) eq "failed">
		<cfset bootstrapClass = "text-warning failed">
	<cfelseif lcase( arguments.status ) eq "error">
		<cfset bootstrapClass = "text-danger error">
	<cfelseif lcase( arguments.status ) eq "passed">
		<cfset bootstrapClass = "text-success passed">
	<cfelseif lcase( arguments.status ) eq "skipped">
		<cfset bootstrapClass = "text-info skipped">
	</cfif>

	<cfreturn bootstrapClass>
</cffunction>

<!--- Recursive Output --->
<cffunction name="genSuiteReport" output="false">
	<cfargument name="suiteStats">
	<cfargument name="bundleStats">

	<cfset var thisSpec = "">

	<cfsavecontent variable="local.report">
		<cfoutput>

			<!--- Iterate over suite specs --->
			<cfloop array="#arguments.suiteStats.specStats#" index="thisSpec">
				<a href="javascript:
					<cfif len(thisSpec.failMessage) OR NOT structIsEmpty( thisSpec.error )>
						showInfo( '#JSStringFormat( thisSpec.failMessage )#', '#thisSpec.id#', '#lcase( NOT structIsEmpty( thisSpec.error ) )#' )
					<cfelse>
						void(0)
					</cfif>
					"
				   title="#encodeForHTML( thisSpec.name )# (#thisSpec.totalDuration# ms)"
				   data-info="#encodeForHTML( thisSpec.failMessage )#"><span class="#statusPlusBootstrapClass( thisSpec.status )#">&middot;</span></a>

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