<cfparam name="variables.fullPage" default="true">
<cfparam name="variables.ASSETS_DIR" default="#expandPath( '/testbox/system/reports/assets' )#">
<cfparam name="variables.testbox" default="">
<cfparam name="variables.gapReport" default="#structNew()#">
<cfparam name="variables.ran" default="false">
<cfparam name="variables.runnerErrors" default="#[]#">
<cfparam name="variables.gapRunnerSummary" default="#structNew()#">
<cfparam name="variables.gapEmbedCompact" default="false">
<cfparam name="variables.gapRunAnalysisUrl" default="">

<cfscript>
	if ( !structKeyExists( gapReport, "uncovered" ) || !isArray( gapReport.uncovered ) ) {
		gapReport.uncovered = [];
	}
	if ( !structKeyExists( gapReport, "covered" ) || !isArray( gapReport.covered ) ) {
		gapReport.covered = [];
	}
	if ( !structKeyExists( gapReport, "skipped" ) || !isArray( gapReport.skipped ) ) {
		gapReport.skipped = [];
	}
	if ( !structKeyExists( gapReport, "stats" ) || !isStruct( gapReport.stats ) ) {
		gapReport.stats = {};
	}
	variables.byFileMissing = {};
	for ( r in gapReport.uncovered ) {
		if ( !structKeyExists( variables.byFileMissing, r.file ) ) {
			variables.byFileMissing[ r.file ] = [];
		}
		arrayAppend( variables.byFileMissing[ r.file ], r );
	}
	variables.byFileCovered = {};
	for ( r2 in gapReport.covered ) {
		if ( !structKeyExists( variables.byFileCovered, r2.file ) ) {
			variables.byFileCovered[ r2.file ] = [];
		}
		arrayAppend( variables.byFileCovered[ r2.file ], r2 );
	}
	variables.missingFiles = structKeyArray( variables.byFileMissing );
	variables.coveredFiles = structKeyArray( variables.byFileCovered );
	arraySort( variables.missingFiles, "textnocase", "asc" );
	arraySort( variables.coveredFiles, "textnocase", "asc" );
</cfscript>

<cfoutput>
	<cfif variables.fullPage>
		<!DOCTYPE html>
		<html>
			<head>
				<meta charset="utf-8">
				<meta name="generator" content="TestBox v#testbox.getVersion()#">
				<title>Gap analysis (heuristic) — TestBox</title>
				<style>#fileRead( "#ASSETS_DIR#/css/main.css" )#</style>
				<script>#fileRead( "#ASSETS_DIR#/js/jquery-3.3.1.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/popper.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/bootstrap.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/fontawesome.js" )#</script>
			</head>
			<body>
	</cfif>

	<div class="<cfif variables.gapEmbedCompact && !variables.fullPage>mb-3<cfelse>container-fluid my-3</cfif>">

		<cfif variables.gapEmbedCompact && !variables.fullPage>
			<div class="d-flex justify-content-between align-items-end mb-3 flex-wrap">
				<div class="mb-2 mb-md-0">
					<h5 class="mb-1"><span class="badge badge-secondary">Gap analysis</span></h5>
					<p class="text-muted small mb-0 mt-1">
						Heuristic: public/remote function names are searched as substrings in test/spec <code>.cfc</code>/<code>.cfm</code> text.
						This is not line coverage and not proof a test exercises a function.
					</p>
				</div>
				<div class="text-nowrap">
					<cfif len( variables.gapRunAnalysisUrl )>
						<a class="btn btn-sm btn-primary mr-1" href="#htmlEditFormat( variables.gapRunAnalysisUrl )#"><i class="fas fa-search"></i> Run gap analysis</a>
					</cfif>
					<cfif structKeyExists( gapRunnerSummary, "testsUrl" ) && len( gapRunnerSummary.testsUrl )>
						<a class="btn btn-sm btn-outline-primary mr-1" href="#htmlEditFormat( gapRunnerSummary.testsUrl )#"><i class="fas fa-vial"></i> Run tests (same URL)</a>
					</cfif>
				</div>
			</div>
		<cfelse>
			<div class="d-flex justify-content-between align-items-end mb-3">
				<div>
					<div>
						<img src="data:image/png;base64, #toBase64( fileReadBinary( '#ASSETS_DIR#/images/TestBoxLogo125.png' ) )#" height="75">
						<span class="badge badge-info">v#testbox.getVersion()#</span>
						<span class="badge badge-secondary">Gap analysis</span>
					</div>
					<p class="text-muted small mb-0 mt-2">
						Heuristic: public/remote function names are searched as substrings in test/spec <code>.cfc</code>/<code>.cfm</code> text.
						This is not line coverage and not proof a test exercises a function.
					</p>
				</div>
				<div>
					<cfif len( variables.gapRunAnalysisUrl )>
						<a class="btn btn-sm btn-primary mr-1" href="#htmlEditFormat( variables.gapRunAnalysisUrl )#"><i class="fas fa-search"></i> Run gap analysis</a>
					</cfif>
					<cfif structKeyExists( gapRunnerSummary, "testsUrl" ) && len( gapRunnerSummary.testsUrl )>
						<a class="btn btn-sm btn-outline-primary mr-1" href="#htmlEditFormat( gapRunnerSummary.testsUrl )#"><i class="fas fa-vial"></i> Run tests (same URL)</a>
					</cfif>
				</div>
			</div>
		</cfif>

		<cfif !( variables.gapEmbedCompact && !variables.fullPage )>
			<div class="card mb-3">
				<div class="card-header list-group-item-info">
					<strong><i class="fas fa-link"></i> TestBox runner parameters (same as a normal HTML run)</strong>
				</div>
				<div class="card-body small">
					<p class="mb-2">Add <code>gapAnalysis=true</code> to the same query string you use for the TestBox HTML runner. Source roots use <code>coveragePathToCapture</code>; test corpus uses <code>directory</code> (resolved like <code>addDirectories</code>).</p>
					<dl class="row mb-0">
						<dt class="col-sm-3">directory</dt>
						<dd class="col-sm-9"><code>#structKeyExists( gapRunnerSummary, "directory" ) ? encodeForHtml( toString( gapRunnerSummary.directory ) ) : ""#</code></dd>
						<dt class="col-sm-3">recurse</dt>
						<dd class="col-sm-9"><code>#structKeyExists( gapRunnerSummary, "recurse" ) ? encodeForHtml( toString( gapRunnerSummary.recurse ) ) : ""#</code></dd>
						<dt class="col-sm-3">bundles</dt>
						<dd class="col-sm-9"><code>#structKeyExists( gapRunnerSummary, "bundles" ) ? encodeForHtml( toString( gapRunnerSummary.bundles ) ) : ""#</code></dd>
						<dt class="col-sm-3">coveragePathToCapture</dt>
						<dd class="col-sm-9 text-monospace">#structKeyExists( gapRunnerSummary, "coveragePathToCapture" ) ? encodeForHtml( toString( gapRunnerSummary.coveragePathToCapture ) ) : ""#</dd>
						<dt class="col-sm-3">source (resolved)</dt>
						<dd class="col-sm-9 text-monospace">#structKeyExists( gapRunnerSummary, "sourceRootAbs" ) ? encodeForHtml( toString( gapRunnerSummary.sourceRootAbs ) ) : ""#</dd>
						<dt class="col-sm-3">component prefix</dt>
						<dd class="col-sm-9"><code>#structKeyExists( gapRunnerSummary, "componentPrefix" ) ? encodeForHtml( toString( gapRunnerSummary.componentPrefix ) ) : ""#</code></dd>
						<dt class="col-sm-3">test roots (resolved)</dt>
						<dd class="col-sm-9">
							<cfif structKeyExists( gapRunnerSummary, "testRootAbs" ) && isArray( gapRunnerSummary.testRootAbs )>
								<cfloop array="#gapRunnerSummary.testRootAbs#" index="trp">
									<div class="text-monospace">#encodeForHtml( trp )#</div>
								</cfloop>
							</cfif>
						</dd>
					</dl>
				</div>
			</div>
		</cfif>

		<cfif arrayLen( runnerErrors )>
			<div class="alert alert-danger">
				<strong>Could not run analysis</strong>
				<ul class="mb-0">
					<cfloop array="#runnerErrors#" index="em">
						<li>#encodeForHtml( em )#</li>
					</cfloop>
				</ul>
			</div>
		</cfif>

		<cfif ran && !arrayLen( runnerErrors )>

			<div class="list-group-item list-group-item-info p-2 d-flex justify-content-between align-items-end mb-2" id="gapGlobalStats">
				<div>
					<h3 class="mb-1"><i class="fas fa-chart-line"></i> Summary</h3>
					<h5 class="mt-2 mb-0">
						<span>Functions:<span class="badge badge-info ml-1"><cfif structKeyExists( gapReport.stats, "totalFunctions" )>#gapReport.stats.totalFunctions#<cfelse>0</cfif></span></span>
						<span class="ml-3">Heuristic match:<span class="badge badge-success ml-1"><cfif structKeyExists( gapReport.stats, "coveredHeuristic" )>#gapReport.stats.coveredHeuristic#<cfelse>0</cfif></span></span>
						<span class="ml-3">Missing mention:<span class="badge badge-danger ml-1"><cfif structKeyExists( gapReport.stats, "missingHeuristic" )>#gapReport.stats.missingHeuristic#<cfelse>0</cfif></span></span>
					</h5>
				</div>
			</div>

			<div class="d-flex justify-content-end mb-2 flex-wrap">
				<cfif arrayLen( gapReport.skipped )>
					<button type="button" id="gap-expand-skipped" class="btn btn-sm btn-primary mr-1 mb-1"><i class="fas fa-plus-square"></i> Expand skipped</button>
					<button type="button" id="gap-collapse-skipped" class="btn btn-sm btn-primary mr-1 mb-1"><i class="fas fa-minus-square"></i> Collapse skipped</button>
				</cfif>
				<button type="button" id="gap-expand-missing" class="btn btn-sm btn-primary mr-1 mb-1"><i class="fas fa-plus-square"></i> Expand missing</button>
				<button type="button" id="gap-collapse-missing" class="btn btn-sm btn-primary mr-1 mb-1"><i class="fas fa-minus-square"></i> Collapse missing</button>
				<button type="button" id="gap-expand-covered" class="btn btn-sm btn-primary mr-1 mb-1"><i class="fas fa-plus-square"></i> Expand covered</button>
				<button type="button" id="gap-collapse-covered" class="btn btn-sm btn-primary mb-1"><i class="fas fa-minus-square"></i> Collapse covered</button>
			</div>

			<cfif arrayLen( gapReport.skipped )>
				<div class="card mb-3 border-warning">
					<div
						class="card-header list-group-item-warning expand-collapse py-3"
						data-toggle="collapse"
						data-target="##gapSectionSkipped"
						aria-expanded="true"
						aria-controls="gapSectionSkipped"
						style="cursor: pointer;"
					>
						<h5 class="mb-0">
							<i class="fas fa-minus-circle"></i>
							Skipped (metadata could not be read)
							<span class="badge badge-warning">#arrayLen( gapReport.skipped )#</span>
							<button class="btn btn-link float-right py-0" type="button" style="text-decoration: none;">
								<i class="fas fa-minus-square plus-minus"></i>
							</button>
						</h5>
					</div>
					<div id="gapSectionSkipped" class="collapse show">
						<div class="card-body p-0">
							<ul class="list-group list-group-flush">
								<cfloop array="#gapReport.skipped#" index="sk">
									<li class="list-group-item list-group-item-warning py-3">
										<div class="d-flex justify-content-between align-items-start flex-wrap">
											<span class="h6 mb-1">
												<strong><i class="fas fa-times"></i> #encodeForHtml( sk.componentId )#</strong>
											</span>
											<code class="small text-monospace ml-2">#encodeForHtml( structKeyExists( sk, "file" ) ? sk.file : "" )#</code>
										</div>
										<div class="mt-2 text-danger">
											#encodeForHtml( structKeyExists( sk, "message" ) ? sk.message : "" )#
										</div>
										<cfif structKeyExists( sk, "detail" ) && len( trim( toString( sk.detail ) ) )>
											<div class="bg-light p-2 mt-2 small text-monospace overflow-auto">
												#encodeForHtml( toString( sk.detail ) )#
											</div>
										</cfif>
									</li>
								</cfloop>
							</ul>
						</div>
					</div>
				</div>
			</cfif>

			<div class="card mb-3 border-danger">
				<div
					class="card-header list-group-item-danger expand-collapse py-3"
					data-toggle="collapse"
					data-target="##gapSectionMissing"
					aria-expanded="true"
					aria-controls="gapSectionMissing"
					style="cursor: pointer;"
				>
					<h5 class="mb-0">
						<i class="fas fa-exclamation-triangle"></i>
						Missing heuristic mention
						<span class="badge badge-danger">#arrayLen( gapReport.uncovered )#</span>
						<button class="btn btn-link float-right py-0" type="button" style="text-decoration: none;">
							<i class="fas fa-minus-square plus-minus"></i>
						</button>
					</h5>
				</div>
				<div id="gapSectionMissing" class="collapse show">
					<div class="card-body">
						<input class="form-control mb-2" type="text" id="gapFilterMissing" placeholder="Filter rows (component, file, function)...">
						<div id="gapMissingInner">
							<cfif !arrayLen( variables.missingFiles )>
								<p class="text-success mb-0"><i class="fas fa-check"></i> None — all scanned functions had a name mention in the test corpus.</p>
							<cfelse>
								<cfloop array="#variables.missingFiles#" index="fpath">
									<div class="card mb-2 border-secondary">
										<div
											class="card-header py-2 expand-collapse"
											data-toggle="collapse"
											data-target="##fid_missing_#hash( fpath )#"
											aria-expanded="true"
											style="cursor: pointer;"
										>
											<small class="text-monospace">#encodeForHtml( fpath )#</small>
											<span class="badge badge-secondary ml-1">#arrayLen( variables.byFileMissing[ fpath ] )#</span>
											<button class="btn btn-link float-right py-0" type="button" style="text-decoration: none;">
												<i class="fas fa-minus-square plus-minus"></i>
											</button>
										</div>
										<div id="fid_missing_#hash( fpath )#" class="collapse show">
											<table class="table table-sm table-striped mb-0 gap-table" data-gap-section="missing">
												<thead>
													<tr>
														<th>Function</th>
														<th>Component</th>
														<th>Access</th>
													</tr>
												</thead>
												<tbody>
													<cfloop array="#variables.byFileMissing[ fpath ]#" index="row">
														<tr>
															<td><code>#encodeForHtml( row.function )#</code></td>
															<td class="small text-monospace">#encodeForHtml( row.componentId )#</td>
															<td>#encodeForHtml( row.access )#</td>
														</tr>
													</cfloop>
												</tbody>
											</table>
										</div>
									</div>
								</cfloop>
							</cfif>
						</div>
					</div>
				</div>
			</div>

			<div class="card mb-3 border-success">
				<div
					class="card-header list-group-item-success expand-collapse py-3"
					data-toggle="collapse"
					data-target="##gapSectionCovered"
					aria-expanded="false"
					aria-controls="gapSectionCovered"
					style="cursor: pointer;"
				>
					<h5 class="mb-0">
						<i class="fas fa-check-circle"></i>
						Heuristic mention found
						<span class="badge badge-success">#arrayLen( gapReport.covered )#</span>
						<button class="btn btn-link float-right py-0" type="button" style="text-decoration: none;">
							<i class="fas fa-plus-square plus-minus"></i>
						</button>
					</h5>
				</div>
				<div id="gapSectionCovered" class="collapse">
					<div class="card-body">
						<input class="form-control mb-2" type="text" id="gapFilterCovered" placeholder="Filter rows (component, file, function)...">
						<div id="gapCoveredInner">
							<cfif !arrayLen( variables.coveredFiles )>
								<p class="text-muted mb-0">No functions matched the corpus (empty source scan or all names missing).</p>
							<cfelse>
								<cfloop array="#variables.coveredFiles#" index="fpath2">
									<div class="card mb-2 border-secondary">
										<div
											class="card-header py-2 expand-collapse"
											data-toggle="collapse"
											data-target="##fid_covered_#hash( fpath2 )#"
											aria-expanded="false"
											style="cursor: pointer;"
										>
											<small class="text-monospace">#encodeForHtml( fpath2 )#</small>
											<span class="badge badge-secondary ml-1">#arrayLen( variables.byFileCovered[ fpath2 ] )#</span>
											<button class="btn btn-link float-right py-0" type="button" style="text-decoration: none;">
												<i class="fas fa-plus-square plus-minus"></i>
											</button>
										</div>
										<div id="fid_covered_#hash( fpath2 )#" class="collapse">
											<table class="table table-sm table-striped mb-0 gap-table" data-gap-section="covered">
												<thead>
													<tr>
														<th>Function</th>
														<th>Component</th>
														<th>Access</th>
													</tr>
												</thead>
												<tbody>
													<cfloop array="#variables.byFileCovered[ fpath2 ]#" index="row2">
														<tr>
															<td><code>#encodeForHtml( row2.function )#</code></td>
															<td class="small text-monospace">#encodeForHtml( row2.componentId )#</td>
															<td>#encodeForHtml( row2.access )#</td>
														</tr>
													</cfloop>
												</tbody>
											</table>
										</div>
									</div>
								</cfloop>
							</cfif>
						</div>
					</div>
				</div>
			</div>

		</cfif>
	</div>

</cfoutput>
<cfif variables.fullPage>
	<script>
	$( document ).ready( function() {
		$( ".expand-collapse" ).on( "click", function( e ) {
			if ( $( e.target ).closest( "a" ).length ) {
				return;
			}
			var $t = $( this ).find( ".plus-minus" ).last();
			var $panel = $( $( this ).data( "target" ) );
			$panel.on( "shown.bs.collapse hidden.bs.collapse", function() {
				$t.toggleClass( "fa-plus-square fa-minus-square", $panel.hasClass( "show" ) );
			} );
		} );

		function bindFilter( inputSel, wrapSel ) {
			$( inputSel ).on( "keyup", function() {
				var v = $( this ).val().toLowerCase();
				$( wrapSel ).find( "tbody tr" ).each( function() {
					$( this ).toggle( $( this ).text().toLowerCase().indexOf( v ) >= 0 );
				} );
				$( wrapSel ).find( ".card" ).each( function() {
					var any = $( this ).find( "tbody tr:visible" ).length > 0;
					$( this ).toggle( any || v === "" );
				} );
			} );
		}
		bindFilter( "#gapFilterMissing", "#gapMissingInner" );
		bindFilter( "#gapFilterCovered", "#gapCoveredInner" );

		$( "#gap-expand-missing" ).click( function() {
			$( "#gapSectionMissing .collapse" ).collapse( "show" );
		} );
		$( "#gap-collapse-missing" ).click( function() {
			$( "#gapSectionMissing .collapse" ).collapse( "hide" );
		} );
		$( "#gap-expand-covered" ).click( function() {
			$( "#gapSectionCovered .collapse" ).collapse( "show" );
		} );
		$( "#gap-collapse-covered" ).click( function() {
			$( "#gapSectionCovered .collapse" ).collapse( "hide" );
		} );
		$( "#gap-expand-skipped" ).click( function() {
			$( "#gapSectionSkipped" ).collapse( "show" );
		} );
		$( "#gap-collapse-skipped" ).click( function() {
			$( "#gapSectionSkipped" ).collapse( "hide" );
		} );
	} );
	</script>
	</body>
	</html>
</cfif>
