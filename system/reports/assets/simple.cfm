<cfparam name="url.fullPage" default="true">
<cfset ASSETS_DIR = expandPath( "/testbox/system/reports/assets" )>
<cfoutput>
	<cfif url.fullPage>
		<!DOCTYPE html>
		<html>
			<head>
				<meta charset="utf-8">
				<meta name="generator" content="TestBox v#testbox.getVersion()#">
				<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>
				<style>#fileRead( "#ASSETS_DIR#/css/main.css" )#</style>
				<script>#fileRead( "#ASSETS_DIR#/js/jquery-3.3.1.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/popper.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/bootstrap.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/stupidtable.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/fontawesome.js" )#</script>
			</head>
			<body>
	</cfif>
				<div class="container-fluid my-3">
					<!--- Filter--->
					<div class="d-flex justify-content-between align-items-end">
						<div>
							<!--- Header --->
							<div>
								<img src="data:image/png;base64, #toBase64( fileReadBinary( '#ASSETS_DIR#/images/TestBoxLogo125.png' ) )#" height="75">
								<span class="badge badge-info">v#testbox.getVersion()#</span>
							</div>
						</div>
						<div>
							<input class="d-inline col-7 ml-2 form-control float-right mb-1" type="text" name="bundleFilter" id="bundleFilter" placeholder="Filter Bundles..." size="35">
							<div class="buttonBar mb-1 float-right">
								<a 	class="ml-1 btn btn-sm btn-primary float-right"
									href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&opt_run=true"
									title="Run all tests"
								>
									<i class="fas fa-running"></i> Run All Tests
								</a>
								<button
									id="collapse-bundles"
									class="ml-1 btn btn-sm btn-primary float-right"
									title="Collapse all bundles"
									>
										<i class="fas fa-minus-square"></i> Collapse All Bundles
								</button>
								<button
									id="expand-bundles"
									class="ml-1 btn btn-sm btn-primary float-right"
									title="Expand all bundles"
									>
										<i class="fas fa-plus-square"></i> Expand All Bundles
								</button>
							</div>
						</div>
					</div>

					<!--- Code Coverage Stats --->
					<cfif results.getCoverageEnabled()>
						#testbox.getCoverageService().renderStats( results.getCoverageData(), false )#
					</cfif>

					<!--- Global Stats --->
					<div class="list-group">

						<!--- Test Results Stats --->
						<div class="list-group-item list-group-item-info p-2 d-flex justify-content-between align-items-end" id="globalStats">
							<div>
								<h3><i class="fas fa-chart-line"></i> Test Results Stats (#numberFormat( results.getTotalDuration() )# ms)</h3>
								<div>
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
									<cfif arrayLen( results.getExcludes() )>
										<h5 class="mt-2 mb-0">
											<span>Excludes Applied: <span class="badge badge-info ml-1">#arrayToList( results.getExcludes() )#</u></span>
										</h5>
									</cfif>
								</div>
							</div>

							<div>
								<span
									class="specStatus btn btn-sm btn-success Passed"
									data-status="passed"
								>
									<i class="fas fa-check"></i> Pass: #results.getTotalPass()#
								</span>
								<span
									class="specStatus btn btn-sm btn-warning Failed"
									data-status="failed"
								>
									<i class="fas fa-exclamation-triangle"></i> Failures: #results.getTotalFail()#
								</span>
								<span
									class="specStatus btn btn-sm btn-danger Error"
									data-status="error"
								>
									<i class="fas fa-times"></i> Errors: #results.getTotalError()#
								</span>
								<span
									class="specStatus btn btn-sm btn-secondary Skipped"
									data-status="skipped"
								>
									<i class="fas fa-minus-circle"></i> Skipped: #results.getTotalSkipped()#
								</span>
								<span
									class="reset btn btn-sm btn-dark"
									title="Clear status filters"
								>
									<i class="fas fa-broom"></i> Reset
								</span>
							</div>
						</div>
						<div class="list-group-item accordion pl-0" id="bundles">
							<!--- Bundle Info --->
							<cfloop array="#variables.bundleStats#" index="thisBundle">

								<!--- Skip if not in the includes list --->
								<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
									<cfcontinue>
								</cfif>

								<!--- Bundle div --->
								<div class="bundle card" id="#thisBundle.path#" data-bundle="#thisBundle.path#">
									<div
										class="card-header"
										id="header_#thisBundle.id#"
										data-toggle="collapse"
										data-target="##details_#thisBundle.id#"
									>
										<h5 class="mb-0 clearfix">
											<!--- bundle stats --->
											<a
												class="alert-link h5"
												href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&testBundles=#URLEncodedFormat( thisBundle.path )#&opt_run=true"
												title="Run only this bundle"
											>
												#thisBundle.path# (#numberFormat( thisBundle.totalDuration )# ms)
											</a>
											<button
													class="btn btn-link float-right py-0 expand-collapse"
													style="text-decoration: none;"
													type="button"
													data-toggle="collapse"
													data-target="##details_#thisBundle.id#"
													aria-expanded="false"
													aria-controls="details_#thisBundle.id#"
												>
												<i class="fas fa-minus-square"></i>
											</button>
										</h5>
										<div class="float-right">
											<span
												class="specStatus btn btn-sm btn-success Passed"
												data-status="passed" data-bundleid="#thisBundle.id#"
											>
												<i class="fas fa-check"></i> Pass: #thisBundle.totalPass#
											</span>
											<span
												class="specStatus btn btn-sm btn-warning Failed"
												data-status="failed" data-bundleid="#thisBundle.id#"
											>
												<i class="fas fa-exclamation-triangle"></i> Failures: #thisBundle.totalFail#
											</span>
											<span
												class="specStatus btn btn-sm btn-danger Error"
												data-status="error" data-bundleid="#thisBundle.id#"
											>
												<i class="fas fa-times"></i> Errors: #thisBundle.totalError#
											</span>
											<span
												class="specStatus btn btn-sm btn-secondary Skipped"
												data-status="skipped" data-bundleid="#thisBundle.id#"
											>
												<i class="fas fa-minus-circle"></i> Skipped: #thisBundle.totalSkipped#
											</span>
											<span
												class="reset btn btn-sm btn-dark"
												title="Clear status filters"
											>
												<i class="fas fa-broom"></i> Reset
											</span>
										</div>
										<h5 class="d-inline-block">
											<span>Suites:<span class="badge badge-info ml-1">#thisBundle.totalSuites#</span></span>
											<span class="ml-3">Specs:<span class="badge badge-info ml-1">#thisBundle.totalSpecs#</span></span>
										</h5>
									</div>

									<div
										id="details_#thisBundle.id#"
										class="collapse details-panel show"
										aria-labelledby="header_#thisBundle.id#"
										data-bundle="#thisBundle.path#"
									>
										<div class="card-body">
											<ul class="suite list-group">

												<!--- Global Exception --->
												<cfif !isSimpleValue( thisBundle.globalException )>
													<li class="list-group-item list-group-item-danger">
														<span class="h5">
															<strong>
																<i class="fas fa-times"></i> Global Bundle Exception
															</strong>(#numberFormat( thisBundle.totalDuration )# ms)
														</span>
														<button
															class="btn btn-link float-right py-0 expand-collapse collapsed"
															style="text-decoration: none;"
															id="btn_globalException_#thisBundle.id#"
															onclick="toggleDebug( 'globalException_#thisBundle.id#' )"
															title="Show more information"
														>
															<i class="fas fa-plus-square"></i>
														</button>
														<div>#thisBundle.globalException.Message#</div>
														<div class="pl-5 bg-light">
															<cfif structKeyExists( thisBundle.globalException.TagContext[ 1 ], "codePrintHTML" )>
																<code>#thisBundle.globalException.TagContext[ 1 ].codePrintHTML#</code>
															</cfif>
														</div>
														<div class="my-2 debugdata" style="display:none;" data-specid="globalException_#thisBundle.id#">
															<cfdump var="#thisBundle.globalException#" />
														</div>
													</li>
												</cfif>

												<!-- Iterate over bundle suites -->
												<cfloop array="#thisBundle.suiteStats#" index="suiteStats">
													#genSuiteReport( suiteStats, thisBundle )#
												</cfloop>

												<!--- Debug Panel --->
												<cfif arrayLen( thisBundle.debugBuffer )>
													<li
														class="list-group-item list-group-item-primary pt-2 pb-1 mt-4"
														onclick="toggleDebug( '#thisBundle.id#' )"
														style="cursor:pointer"
														title="Toggle Debug Stream"
													>
														<span class="alert-link h5 text-info">
															<strong><i class="fas fa-bug"></i> Debug Stream</strong>
														</span>

														<button
															class="btn btn-link float-right py-0 expand-collapse collapsed"
															style="text-decoration: none;"
															id="btn_#thisBundle.id#"
															onclick="toggleDebug( '#thisBundle.id#' )"
															title="Toggle the test debug stream"
														>
															<i class="fas fa-plus-square"></i>
														</button>

														<div class="my-2 debugdata bg-light border border-success p-2" style="display:none;" data-specid="#thisBundle.id#">
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
				</div>
</cfoutput>
<script>
$( document ).ready( function() {
	// spec toggler
	$( "span.specStatus" ).click( function() {
		$( this ).parent().children().removeClass( "active" );
		$( this ).addClass( "active" );
		toggleSpecs( $( this ).attr( "data-status" ), $( this ).attr( "data-bundleid" ) );
	});

	// spec reseter
	$( "span.reset" ).click(function() {
		resetSpecs();
	});

	// Filter Bundles
	$( "#bundleFilter" ).keyup( debounce( function() {
		var targetText = $( this ).val().toLowerCase();
		$( ".bundle" ).each( function( index ) {
			var bundle = $( this ).data( "bundle" ).toLowerCase();
			if ( bundle.search( targetText ) < 0 ) {
				// hide it
				$( this ).hide();
			} else {
				$( this ).show();
			}
		});
	}, 100));

	$( "#bundleFilter" ).focus();

	// Bootstrap Collapse
	$( "#collapse-bundles" ).click( function() {
		$( ".details-panel.show" ).collapse( "hide" );
	});

	$( "#expand-bundles" ).click(function() {
		$( ".details-panel:not(.show)" ).collapse( "show" );
	});

	$(".expand-collapse").click(function (event) {
		let icon = $(this).children(".svg-inline--fa");
		var icon_fa_icon = icon.attr('data-icon');

		if (icon_fa_icon === "minus-square") {
				icon.attr('data-icon', 'plus-square');
		} else if (icon_fa_icon === "plus-square") {
				icon.attr('data-icon', 'minus-square');
		}
	});

});

function debounce( func, wait, immediate ) {
	var timeout;
	return function() {
		var context = this,
			args = arguments;
		var later = function() {
			timeout = null;
			if ( !immediate ) {
				func.apply( context, args );
			}
		};
		var callNow = immediate && !timeout;
		clearTimeout( timeout );
		timeout = setTimeout( later, wait );
		if ( callNow ) {
			func.apply( context, args );
		}
	};
};

function resetSpecs() {
	$( "li.spec" ).each( function() {
		$( this ).show();
	});
	$( "ul.suite" ).each(function() {
		$( this ).show();
	});
}

function toggleSpecs( type, bundleID ) {
	$( "ul.suite" ).each( function() {
		handleToggle( $( this ), bundleID, type );
	});
	$( "li.spec" ).each( function() {
		handleToggle( $( this ), bundleID, type );
	});
}

function handleToggle( target, bundleID, type ) {
	type = capitalizeFirstLetter( type );
	var $this = target;

	// if bundleid passed and not the same bundle, skip
	if ( bundleID != undefined && $this.attr( "data-bundleid" ) != bundleID ) {
		return;
	}
	// toggle the opposite type
	if ( !$this.hasClass( type ) ) {
		$this.hide();
	} else {
		// show the type you sent
		$this.show();
		$this.parents().show();
	}
}

function toggleDebug( specid ) {
	$( `#btn_${specid}` ).toggleClass( "collapsed" );
	$( "div.debugdata" ).each(function() {
		var $this = $( this );

		// if bundleid passed and not the same bundle
		if ( specid != undefined && $this.attr("data-specid") != specid ) {
			return;
		}
		// toggle.
		$this.slideToggle();
	});
}

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}
</script>
<style>
code {
	color: black !important;
}
</style>
<cfif url.fullPage>
			</body>
		</html>
</cfif>

<cffunction name="statusToBootstrapClass" output="false">
	<cfargument name="status">
	<cfset bootstrapClass = "">
	<cfif lcase( arguments.status ) eq "failed">
		<cfset bootstrapClass = "warning">
	<cfelseif lcase( arguments.status ) eq "error">
		<cfset bootstrapClass = "danger">
	<cfelseif lcase( arguments.status ) eq "passed">
		<cfset bootstrapClass = "success">
	<cfelseif lcase( arguments.status ) eq "skipped">
		<cfset bootstrapClass = "secondary">
	</cfif>
	<cfreturn bootstrapClass>
</cffunction>

<cffunction name="statusToIcon" output="false">
	<cfargument name="status">
	<cfset icon = "">
	<cfif lcase( arguments.status ) eq "failed">
		<cfset icon = '<i class="fas fa-exclamation-triangle"></i>'>
	<cfelseif lcase( arguments.status ) eq "error">
		<cfset icon = '<i class="fas fa-times"></i>'>
	<cfelseif lcase( arguments.status ) eq "passed">
		<cfset icon = '<i class="fas fa-check"></i>'>
	<cfelseif lcase( arguments.status ) eq "skipped">
		<cfset icon = '<i class="fas fa-minus-circle"></i>'>
	</cfif>
	<cfreturn icon>
</cffunction>

<!--- Recursive Output --->
<cffunction name="genSuiteReport" output="false">
	<cfargument name="suiteStats">
	<cfargument name="bundleStats">
	<cfsavecontent variable="local.report">
		<cfoutput>
			<li class="list-group-item #suiteStats.status#" data-bundleid="#suiteStats.bundleID#">
				<!--- Suite Results --->
				<a
					class="alert-link text-#statusToBootstrapClass( suiteStats.status )#"
					title="Total: #arguments.suiteStats.totalSpecs# Passed:#arguments.suiteStats.totalPass# Failed:#arguments.suiteStats.totalFail# Errors:#arguments.suiteStats.totalError# Skipped:#arguments.suiteStats.totalSkipped#"
					href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&testSuites=#URLEncodedFormat( arguments.suiteStats.name )#&testBundles=#URLEncodedFormat( arguments.bundleStats.path )#&opt_run=true"
				>
					#statusToIcon( arguments.suiteStats.status )# <strong>#arguments.suiteStats.name#</strong>
					(#numberFormat( arguments.suiteStats.totalDuration )# ms)
				</a>
				<ul class="list-group">
					<cfloop array="#arguments.suiteStats.specStats#" index="local.thisSpec">
						<!--- Spec Results --->

						<li class="spec list-group-item #local.thisSpec.status#" data-bundleid="#arguments.bundleStats.id#" data-specid="#local.thisSpec.id#">
							<div class="clearfix">
								<a
									class="alert-link text-#statusToBootstrapClass( local.thisSpec.status )#"
									href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&testSpecs=#URLEncodedFormat( local.thisSpec.name )#&testBundles=#URLEncodedFormat( arguments.bundleStats.path )#&opt_run=true"
								>
									#statusToIcon( local.thisSpec.status )# #local.thisSpec.name# (#numberFormat( local.thisSpec.totalDuration )# ms)
								</a>
								<cfif local.thisSpec.status eq "failed">
									<cfset local.thisSpec.message = local.thisSpec.failMessage>
								</cfif>
								<cfif local.thisSpec.status eq "error">
									<cfset local.thisSpec.message = local.thisSpec.error.message>
								</cfif>
								<cfif structKeyExists( local.thisSpec, "message" )>
									- <strong>#encodeForHTML( local.thisSpec.message )#</strong></a>
									<button
										class="btn btn-link float-right py-0 expand-collapse collapsed"
										style="text-decoration: none;"
										id="btn_#local.thisSpec.id#"
										onclick="toggleDebug( '#local.thisSpec.id#' )"
										title="Show more information"
									>
										<i class="fas fa-plus-square"></i>
									</button>
								</cfif>
							</div>
							<cfif structKeyExists( local.thisSpec, "message" )>
								<div
									onclick="toggleDebug( '#local.thisSpec.id#' )"
								>
									<cfif arrayLen( local.thisSpec.failOrigin )>
										<div><pre>#local.thisSpec.failOrigin[ 1 ].raw_trace#</pre></div>
										<div class="pl-5 mb-2 bg-light">
											<cfif structKeyExists( local.thisSpec.failOrigin[ 1 ], "codePrintHTML" )>
												<code>#local.thisSpec.failOrigin[ 1 ].codePrintHTML#</code>
											</cfif>
										</div>
									</cfif>
									<div class="my-2 debugdata" style="display:none;" data-specid="#local.thisSpec.id#">
										<cfdump var="#local.thisSpec.failorigin#" label="Failure Origin">
									</div>
								</div>
							</cfif>
						</li>
					</cfloop>
					<!--- Do we have nested suites --->
					<cfif arrayLen( arguments.suiteStats.suiteStats )>
						<li class="spec list-group-item" data-bundleid="#arguments.bundleStats.id#">
							<ul class="suite list-group" data-bundleid="#arguments.bundleStats.id#">
								<cfloop array="#arguments.suiteStats.suiteStats#" index="local.nestedSuite">
									#genSuiteReport( local.nestedSuite, arguments.bundleStats )#
								</cfloop>
							</ul>
						</li>
					</cfif>
				</ul>
			</li>
		</cfoutput>
	</cfsavecontent>
	<cfreturn local.report>
</cffunction>