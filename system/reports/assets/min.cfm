<cfset cDir = getDirectoryFromPath( getCurrentTemplatePath() )>
<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<meta name="generator" content="TestBox v#testbox.getVersion()#">
		<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

		<style>#fileRead( '#cDir#/css/fontawesome.css' )#</style>
		<style>#fileRead( '#cDir#/css/bootstrap.min.css' )#</style>

		<script>#fileRead( '#cDir#/js/jquery-3.3.1.min.js' )#</script>
		<script>#fileRead( '#cDir#/js/popper.min.js' )#</script>
		<script>#fileRead( '#cDir#/js/bootstrap.min.js' )#</script>
		<script>
		$(document).ready(function() {
		});
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
		<div class="container my-3">
			<!-- Header --->
			<p>TestBox v#testbox.getVersion()#</p>

			<!-- Global Stats --->
			<div class="list-group">
				<div class="list-group-item list-group-item-info" id="globalStats">
					<div class="buttonBar">
						<a class="btn btn-primary btn-sm m-1 float-right" href="#variables.baseURL#&opt_run=true&target=#URL.target#" title="Run the tests">Rerun Test</a>
					</div>

					<h4>Bundles/Suites/Specs: #results.getTotalBundles()#/#results.getTotalSuites()#/#results.getTotalSpecs()#  (#results.getTotalDuration()# ms)</h4>

					<span class="badge badge-success" data-status="passed">Pass: #results.getTotalPass()#</span>
					<span class="badge badge-warning" data-status="failed">Failures: #results.getTotalFail()#</span>
					<span class="badge badge-danger" data-status="error">Errors: #results.getTotalError()#</span>
					<span class="badge badge-info" data-status="skipped">Skipped: #results.getTotalSkipped()#</span>
					<br>
					<cfif arrayLen( results.getLabels() )>
					[ Labels Applied: #arrayToList( results.getLabels() )# ]<br>
					</cfif>
					<cfif results.getCoverageEnabled()>
					[ Coverage: #round( results.getCoverageData().stats.percTotalCoverage*100 )#% ]
					</cfif>

				</div>
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
						<cfloop array="#thisBundle.debugBuffer#" index="thisDebug">
							<h2>#thisDebug.label#</h2>
							<cfdump var="#thisDebug.data#" 		label="#thisDebug.label# - #dateFormat( thisDebug.timestamp, "short" )# at #timeFormat( thisDebug.timestamp, "full")#" top="#thisDebug.top#"/>
							<p>&nbsp;</p>
						</cfloop>
					</div>
				</cfif>
			</cfloop>
		</div>
	</body>
</html>
</cfoutput>