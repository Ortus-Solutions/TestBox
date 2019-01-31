<cfparam name="url.full_page" default="true">
<cfset ASSETS_DIR=expandPath( "/testbox/system/reports/assets" )>
<cfoutput>
	<cfif url.full_page>
		<!DOCTYPE html>
		<html>
			<head>
				<meta charset="utf-8">
				<meta name="generator" content="TestBox v#testbox.getVersion()#">
				<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

				<link rel="stylesheet" href="#ASSETS_DIR#/css/fontawesome.css">
				<link rel="stylesheet" href="#ASSETS_DIR#/css/bootstrap.min.css">
				<script src="#ASSETS_DIR#/js/jquery-3.3.1.min.js"></script>
				<script src="#ASSETS_DIR#/js/popper.min.js"></script>
				<script src="#ASSETS_DIR#/js/bootstrap.min.js"></script>
				<script src="#ASSETS_DIR#/js/stupidtable.min.js"></script>
			</head>
			<body>
	</cfif>

	<div class="container-fluid my-3">
		<!--- Filter and Coverage Modal--->
		<div class="row mb-3 clearfix">
			<div class="col-5">
				<!--- Header --->
				<p>TestBox v#testbox.getVersion()#</p>
			</div>
			<div class="col-7">

				<input class="d-inline col-7 ml-2 form-control float-right mb-2" type="text" name="bundleFilter" id="bundleFilter" placeholder="Filter Bundles..." size="35">

				<cfif results.getCoverageEnabled()>
					<!-- Button trigger modal -->
					<button type="button" class="btn btn-primary float-right" data-toggle="modal" data-target="##coverageStatsModal">
						View coverage statistics
					</button>

					<!-- Modal -->
					<div class="modal fade" id="coverageStatsModal" tabindex="-1" role="dialog" aria-labelledby="coverageStatsModalLabel" aria-hidden="true">
						<div class="modal-dialog modal-xl" role="document">
							<div class="modal-content">
								<div class="modal-header">
									<h5 class="modal-title" id="coverageStatsModalLabel">Modal title</h5>
									<button type="button" class="close" data-dismiss="modal" aria-label="Close">
										<span aria-hidden="true">&times;</span>
									</button>
								</div>
								<div class="modal-body">
									#testbox.getCoverageService().renderStats( results.getCoverageData() )#
								</div>
								<div class="modal-footer">
									<button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
								</div>
							</div>
						</div>
					</div>
				</cfif>
			</div>

		</div>

		<!--- Stats --->
		<div class="list-group">
			<div class="list-group-item list-group-item-info" id="globalStats">

				<div class="buttonBar">
					<cfif structKeyExists(URL ,"target")>
						<a class=" m-1 btn btn-sm btn-primary float-right" href="#variables.baseURL#&opt_run=true&target=#URL.target#" title="Run the tests">Rerun Tests</a>
					</cfif>
					<span class=" m-1 btn btn-sm btn-primary float-right" onclick="toggleDebug()" title="Toggle the test debug information">Toggle All Debug Information</button>
				</div>

				<h2>Stats (#results.getTotalDuration()# ms)</h2>
				[ Bundles/Suites/Specs: #results.getTotalBundles()#/#results.getTotalSuites()#/#results.getTotalSpecs()# ]
				<div class="float-right">
					<span class="specStatus m-1 btn btn-sm btn-success passed" data-status="passed">Pass: #results.getTotalPass()#</span>
					<span class="specStatus m-1 btn btn-sm btn-warning failed" data-status="failed">Failures: #results.getTotalFail()#</span>
					<span class="specStatus m-1 btn btn-sm btn-danger error" data-status="error">Errors: #results.getTotalError()#</span>
					<span class="specStatus m-1 btn btn-sm btn-secondary skipped" data-status="skipped">Skipped: #results.getTotalSkipped()#</span>
					<span class="reset m-1 btn btn-sm btn-dark" title="Clear status filters">Reset</span>
				</div>
				<br>
				<cfif arrayLen( results.getLabels() )>
					[ Labels Applied: #arrayToList( results.getLabels() )# ]
				</cfif>
			</div>
		</div>

		<div class="accordion" id="bundles">

			<!--- Bundle Info --->
			<cfloop array="#variables.bundleStats#" index="thisBundle">
				<!--- Skip if not in the includes list --->
				<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
					<cfcontinue>
				</cfif>
				<!--- Bundle div --->
				<div class="card bundle" id="#thisBundle.path#" data-bundle="#thisBundle.path#">
					<div class="card-header" id="header_#thisBundle.id#">
						<h4 class="mb-0 clearfix">
							<!--- bundle stats --->
							<a class="alert-link" href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&target=#URLEncodedFormat( thisBundle.path )#&opt_run=true" title="Run only this bundle">
								#thisBundle.path# (#thisBundle.totalDuration# ms)
							</a>
							<button class="btn btn-link float-right py-0" type="button" data-toggle="collapse" data-target="##details_#thisBundle.id#" aria-expanded="false" aria-controls="details_#thisBundle.id#">
								<i class="fa" aria-hidden="true"></i>
							</button>
						</h4>
						[ Suites/Specs: #thisBundle.totalSuites#/#thisBundle.totalSpecs# ]
						<div class="float-right">
							<span class="specStatus  m-1 btn btn-sm btn-success passed" data-status="passed" data-bundleid="#thisBundle.id#">Pass: #thisBundle.totalPass#</span>
							<span class="specStatus  m-1 btn btn-sm btn-warning failed" data-status="failed" data-bundleid="#thisBundle.id#">Failures: #thisBundle.totalFail#</span>
							<span class="specStatus  m-1 btn btn-sm btn-danger error" data-status="error" data-bundleid="#thisBundle.id#">Errors: #thisBundle.totalError#</span>
							<span class="specStatus  m-1 btn btn-sm btn-secondary skipped" data-status="skipped" data-bundleid="#thisBundle.id#">Skipped: #thisBundle.totalSkipped#</span>
							<span class="reset m-1 btn btn-sm btn-dark" title="Clear status filters">Reset</span>
						</div>
					</div>
					<div id="details_#thisBundle.id#" class="collapse" aria-labelledby="header_#thisBundle.id#" data-bundle="#thisBundle.path#">
						<div class="card-body">
							<ul class="suite list-group">
								<!--- Global Error --->
								<cfif !isSimpleValue( thisBundle.globalException )>
									<li class="list-group-item list-group-item-danger">
										<span class="h5">
											<strong>Global Bundle Exception</strong>
										</span>
										<button class="btn btn-link float-right py-0 expand-collapse collapsed" id="btn_globalException_#thisBundle#" onclick="toggleDebug( 'globalException_#thisBundle#' )" title="Show more information">
											<i class="fa" aria-hidden="true"></i>
										</button>
										<div class="my-2 pl-4 debugdata" style="display:none;" data-specid="globalException_#thisBundle#">
											<cfdump var="#thisBundle.globalException#" />
										</div>
									</li>
								</cfif>

								<!-- Iterate over bundle suites -->
								<cfloop array="#thisBundle.suiteStats#" index="suiteStats">
									<ul class="suite list-group #statusPlusBootstrapClass( suiteStats.status )#" data-bundleid="#thisBundle.id#">
										#genSuiteReport( suiteStats, thisBundle )#
									</ul>
								</cfloop>

								<!--- Debug Panel --->
								<cfif arrayLen( thisBundle.debugBuffer )>
									<li class="list-group-item list-group-item-info">
										<span class="alert-link h5">
											<strong>Debug Stream</strong>
										</span>
										<button class="btn btn-link float-right py-0 expand-collapse collapsed" id="btn_#thisBundle.id#" onclick="toggleDebug( '#thisBundle.id#' )" title="Toggle the test debug stream">
											<i class="fa" aria-hidden="true"></i>
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
				</div>
			</cfloop>
		</div>
	</div>
</cfoutput>
<script>
$(document).ready(function() {
	// spec toggler
	$("span.specStatus").click(function() {
		toggleSpecs($(this).attr("data-status"), $(this).attr("data-bundleid"));
	});
	// spec reseter
	$("span.reset").click(function() {
		resetSpecs();
	});
	// Filter Bundles
	$("#bundleFilter").keyup(debounce(function() {
		var targetText = $(this).val().toLowerCase();
		$(".bundle").each(function(index) {
			var bundle = $(this).data("bundle").toLowerCase();
			if (bundle.search(targetText) < 0) {
				// hide it
				$(this).hide();
			} else {
				$(this).show();
			}
		});
	}, 100));

	$("#bundleFilter").focus();
	// Bootstrap Collapse
	$('.collapse').each(function() {
		$(`#${$(this).attr('id')}`).collapse("toggle");
	});

});

function debounce(func, wait, immediate) {
	var timeout;
	return function() {
		var context = this,
			args = arguments;
		var later = function() {
			timeout = null;
			if (!immediate) func.apply(context, args);
		};
		var callNow = immediate && !timeout;
		clearTimeout(timeout);
		timeout = setTimeout(later, wait);
		if (callNow) func.apply(context, args);
	};
};

function resetSpecs() {
	$("li.spec").each(function() {
		$(this).show();
	});
	$("ul.suite").each(function() {
		$(this).show();
	});
}

function toggleSpecs(type, bundleID) {
	$("ul.suite").each(function() {
		handleToggle($(this), bundleID, type);
	});
	$("li.spec").each(function() {
		handleToggle($(this), bundleID, type);
	});
}

function handleToggle(target, bundleID, type) {
	var $this = target;

	// if bundleid passed and not the same bundle, skip
	if (bundleID != undefined && $this.attr("data-bundleid") != bundleID) {
		return;
	}
	// toggle the opposite type
	if (!$this.hasClass(type)) {
		$this.hide();
	} else {
		// show the type you sent
		$this.show();
		$this.parents().show();
	}
}

function toggleDebug(specid) {
	$(`#btn_${specid}`).toggleClass("collapsed");
	$("div.debugdata").each(function() {
		var $this = $(this);

		// if bundleid passed and not the same bundle
		if (specid != undefined && $this.attr("data-specid") != specid) {
			return;
		}
		// toggle.
		$this.fadeToggle();
	});
}
</script>

<style>
[data-toggle="collapse"] .fa:before,
.expand-collapse .fa:before {
	content: "\f139";
}

[data-toggle="collapse"].collapsed .fa:before,
.expand-collapse.collapsed .fa:before {
	content: "\f13a";
}

code {
	color: black !important;
}
</style>


<cfif url.full_page>
		</body>
	</html>
</cfif>
<cffunction name="statusPlusBootstrapClass" output="false">
	<cfargument name="status">

	<cfif lcase( arguments.status ) eq "failed">
		<cfset bootstrapClass="list-group-item-warning failed">
	<cfelseif lcase( arguments.status ) eq "error">
		<cfset bootstrapClass="list-group-item-danger error">
	<cfelseif lcase( arguments.status ) eq "passed">
		<cfset bootstrapClass="list-group-item-success passed">
	<cfelseif lcase( arguments.status ) eq "skipped">
		<cfset bootstrapClass="list-group-item-secondary skipped">
	</cfif>

	<cfreturn bootstrapClass>
</cffunction>

<!--- Recursive Output --->
<cffunction name="genSuiteReport" output="false">
	<cfargument name="suiteStats">
	<cfargument name="bundleStats">

	<cfsavecontent variable="local.report">
		<cfoutput>
			<!--- Suite Results --->
			<li class="list-group-item #statusPlusBootstrapClass( arguments.suiteStats.status )#">
				<a class="alert-link h5" title="Total: #arguments.suiteStats.totalSpecs# Passed:#arguments.suiteStats.totalPass# Failed:#arguments.suiteStats.totalFail# Errors:#arguments.suiteStats.totalError# Skipped:#arguments.suiteStats.totalSkipped#" href="#variables.baseURL#&testSuites=#URLEncodedFormat( arguments.suiteStats.name )#&target=#URLEncodedFormat( arguments.bundleStats.path )#&opt_run=true">
					<strong>+#arguments.suiteStats.name#</strong>
					(#arguments.suiteStats.totalDuration# ms)
				</a>
			</li>
			<cfloop array="#arguments.suiteStats.specStats#" index="local.thisSpec">
				<!--- Spec Results --->
				<cfset thisSpecStatusClass=statusPlusBootstrapClass(local.thisSpec.status)>

				<ul class="list-group">
					<li class="list-group-item #thisSpecStatusClass#" data-bundleid="#arguments.bundleStats.id#" data-specid="#local.thisSpec.id#">
						<div class="clearfix">
							<a class="alert-link" href="#variables.baseURL#&testSpecs=#URLEncodedFormat( local.thisSpec.name )#&target=#URLEncodedFormat( arguments.bundleStats.path )#&opt_run=true" class="pl-4 #thisSpecStatusClass#">
								#local.thisSpec.name#(#local.thisSpec.totalDuration# ms)
							</a>
							<cfif local.thisSpec.status eq "failed">
								<cfset local.thisSpec.message = local.thisSpec.failMessage>
							</cfif>
							<cfif local.thisSpec.status eq "error">
								<cfset local.thisSpec.message = local.thisSpec.error.message>
							</cfif>
							<cfif structKeyExists( local.thisSpec, "message" )>
								- <strong>#encodeForHTML( local.thisSpec.message )#</strong></a>
								<button class="btn btn-link float-right py-0 expand-collapse collapsed" id="btn_#local.thisSpec.id#" onclick="toggleDebug( '#local.thisSpec.id#' )" title="Show more information">
									<i class="fa" aria-hidden="true"></i>
								</button>
							</cfif>
						</div>
						<cfif structKeyExists( local.thisSpec, "message" )>
							<cfif arrayLen( local.thisSpec.failOrigin )>
								<div class="pl-4">#local.thisSpec.failOrigin[ 1 ].raw_trace#</div>
								<div class="pl-5">
									<cfif structKeyExists( local.thisSpec.failOrigin[ 1 ], "codePrintHTML" )>
										<code>#local.thisSpec.failOrigin[ 1 ].codePrintHTML#</code>
									</cfif>
								</div>
							</cfif>

							<div class="my-2 pl-4 debugdata" style="display:none;" data-specid="#local.thisSpec.id#">
								<cfdump var="#local.thisSpec.failorigin#" label="Failure Origin">
							</div>
						</cfif>
					</li>
				</ul>
			</cfloop>

			<!--- Do we have nested suites --->
			<cfif arrayLen( arguments.suiteStats.suiteStats )>
				<cfloop array="#arguments.suiteStats.suiteStats#" index="local.nestedSuite">
					<ul class="suite list-group #statusPlusBootstrapClass( arguments.suiteStats.status )#" data-bundleid="#arguments.bundleStats.id#">
						#genSuiteReport( local.nestedSuite, arguments.bundleStats )#
					</ul>
				</cfloop>
			</cfif>

		</cfoutput>
	</cfsavecontent>

	<cfreturn local.report>
</cffunction>