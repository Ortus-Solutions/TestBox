<cfset cDir = getDirectoryFromPath( getCurrentTemplatePath() )>
<cfoutput>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="generator" content="TestBox v#testbox.getVersion()#">
	<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>
	<script>#fileRead( '#cDir#/js/jquery.js' )#</script>

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

<!-- Header --->
<p>TestBox v#testbox.getVersion()#</p>

<!-- Global Stats --->
<div class="border my-1 p-1" id="globalStats">
	<div class="buttonBar">
		<a class="btn btn-primary btn-sm m-1 float-right" href="#variables.baseURL#" title="Run all the tests">Run All</a>
	</div>

	<h3>Bundles/Suites/Specs: #results.getTotalBundles()#/#results.getTotalSuites()#/#results.getTotalSpecs()#  (#results.getTotalDuration()# ms)</h3>

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
			<cfloop array="#thisBundle.debugBuffer#" index="thisDebug">
				<h1>#thisDebug.label#</h1>
				<cfdump var="#thisDebug.data#" 		label="#thisDebug.label# - #dateFormat( thisDebug.timestamp, "short" )# at #timeFormat( thisDebug.timestamp, "full")#" top="#thisDebug.top#"/>
				<p>&nbsp;</p>
			</cfloop>
		</div>
	</cfif>
</cfloop>
</cfoutput>