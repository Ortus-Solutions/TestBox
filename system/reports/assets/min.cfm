<cfparam name="url.fullPage" default="true">
<cfset ASSETS_DIR=expandPath( "/testbox/system/reports/assets" )>
<cfoutput>
	<cfif url.fullPage>
		<!DOCTYPE html>
		<html>

			<head>
				<meta charset="utf-8">
				<meta name="generator" content="TestBox v#testbox.getVersion()#">
				<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

				<style>
				#fileRead('#ASSETS_DIR#/css/bootstrap.min.css')#
				</style>
				<script>
				#
				fileRead('#ASSETS_DIR#/js/jquery-3.3.1.min.js')#
				</script>
				<script>
				#
				fileRead('#ASSETS_DIR#/js/bootstrap.min.js')#
				</script>
			</head>

			<body>
	</cfif>
	<div class="container-fluid my-3">
		<!-- Header --->
		<p>TestBox v#testbox.getVersion()#</p>

		<!--- Code Coverage Stats --->
		<cfif results.getCoverageEnabled()>
			#testbox.getCoverageService().renderStats( results.getCoverageData(), false )#
		</cfif>

		<div class="list-group">
			<!--- Test Results Stats --->
			<div class="list-group-item list-group-item-info" id="globalStats">

				<div class="buttonBar">
					<a class="m-1 btn btn-sm btn-primary float-right" href="#variables.baseURL#?opt_run=true" title="Run all tests">Run All Tests</a>
				</div>

				<h2>Test Results Stats (#results.getTotalDuration()# ms)</h2>
				<div class="float-right">
					<span class="specStatus m-1 badge badge-success passed" data-status="passed">Pass: #results.getTotalPass()#</span>
					<span class="specStatus m-1 badge badge-warning failed" data-status="failed">Failures: #results.getTotalFail()#</span>
					<span class="specStatus m-1 badge badge-danger error" data-status="error">Errors: #results.getTotalError()#</span>
					<span class="specStatus m-1 badge badge-secondary skipped" data-status="skipped">Skipped: #results.getTotalSkipped()#</span>
					<span class="reset m-1 badge badge-dark" title="Clear status filters">Reset</span>
				</div>
				<h5 class="mt-2">
					<span>Bundles:<span class="badge badge-info ml-1">#results.getTotalBundles()#</span></span>
					<span class="ml-3">Suites:<span class="badge badge-info ml-1">#results.getTotalSuites()#</span></span>
					<span class="ml-3">Specs:<span class="badge badge-info ml-1">#results.getTotalSpecs()#</span></span>
				</h5>
				<cfif arrayLen( results.getLabels() )>
					<h5 class="mt-2 mb-0">
						<span>Labels Applied: <span class="badge badge-info ml-1">#arrayToList( results.getLabels() )#</u></span>
					</h5>
				</cfif>
			</div>
		</div>

		<!--- Debug Panel --->
		<cfloop array="#variables.bundleStats#" index="thisBundle">
			<cfif !isSimpleValue( thisBundle.globalException ) OR arrayLen( thisBundle.debugBuffer )>
				<div class="my-2">
					<div class="card-body p-0">
						<ul class="list-group">
							<!--- Global Error --->
							<cfif !isSimpleValue( thisBundle.globalException )>
								<li class="list-group-item list-group-item-danger">
									<span class="h5">
										<strong>Global Bundle Exception</strong>
									</span>
									<button class="btn btn-link float-right py-0 expand-collapse collapsed" id="btn_globalException_#thisBundle.id#" onclick="toggleDebug( 'globalException_#thisBundle.id#' )" title="Show more information">
										<span class="arrow" aria-hidden="true"></span>
									</button>
									<div class="my-2 pl-4 debugdata" style="display:none;" data-specid="globalException_#thisBundle.id#">
										<cfdump var="#thisBundle.globalException#" />
									</div>
								</li>
							</cfif>

							<!--- Debug Panel --->
							<cfif arrayLen( thisBundle.debugBuffer )>
								<li class="list-group-item list-group-item-info">
									<span class="alert-link h5">
										<strong>Debug Stream: #thisBundle.path#</strong>
									</span>
									<button class="btn btn-link float-right py-0 expand-collapse collapsed" id="btn_#thisBundle.id#" onclick="toggleDebug( '#thisBundle.id#' )" title="Toggle the test debug stream">
										<span class="arrow" aria-hidden="true"></span>
									</button>
									<div class="my-2 pl-4 debugdata" style="display:none;" data-specid="#thisBundle.id#">
										<p>The following data was collected in order as your tests ran via the <em>debug()</em> method:</p>
										<cfloop array="#thisBundle.debugBuffer#" index="thisDebug">
											<h6>#thisDebug.label#</h6>
											<cfdump var="#thisDebug.data#" label="#thisDebug.label# - #dateFormat( thisDebug.timestamp, " short" )# at #timeFormat( thisDebug.timestamp, "full" )#" top="#thisDebug.top#" />
										</cfloop>
									</div>
								</li>
							</cfif>
						</ul>
					</div>
				</div>
			</cfif>
		</cfloop>
	</div>
</cfoutput>
<style>
[data-toggle="collapse"] .arrow:before,
.expand-collapse .arrow:before {
	content: "\2b06";
}

[data-toggle="collapse"].collapsed .arrow:before,
.expand-collapse.collapsed .arrow:before {
	content: "\2b07";
}

code {
	color: black !important;
}
</style>
<script>
$(document).ready(function() {});

function toggleDebug(specid) {
	$("div.debugdata").each(function() {
		var $this = $(this);

		// if bundleid passed and not the same bundle
		if (specid != undefined && $this.attr("data-specid") != specid) {
			return;
		}
		// toggle.
		$this.slideToggle();
	});
}
</script>
<cfif url.fullPage>
	</body>

	</html>
</cfif>