<cfscript>
param name="url.fullPage" default="true";
ASSETS_DIR = expandPath( "/testbox/system/reports/assets" );

function statusToClass( required status ){
	var statusMap = {
		"failed": "warning",
		"error": "danger",
		"passed": "success",
		"skipped": "secondary"
	};
	return statusMap[ lcase( arguments.status ) ] ?: "info";
}

function statusToIcon( required status ){
	var iconMap = {
		"failed": "fa-exclamation-triangle",
		"error": "fa-times-circle",
		"passed": "fa-check-circle",
		"skipped": "fa-minus-circle"
	};
	return iconMap[ lcase( arguments.status ) ] ?: "fa-question-circle";
}
</cfscript>
<cfoutput>
	<cfif url.fullPage>
		<!DOCTYPE html>
		<html lang="en" data-theme="dark">
			<head>
				<meta charset="utf-8">
				<meta name="viewport" content="width=device-width, initial-scale=1">
				<meta name="generator" content="TestBox v#testbox.getVersion()#">
				<title>TestBox Results - Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

				<!-- Favicon -->
				<link rel="icon" type="image/png" href="data:image/png;base64,#toBase64( fileReadBinary( '#ASSETS_DIR#/images/TestBoxLogo125.png' ) )#">

				<!-- Bootstrap 5.3 -->
				<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">

				<!-- Font Awesome 6 -->
				<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">

				<!-- Custom Styles -->
				<style>#fileRead( "#ASSETS_DIR#/css/default.css" )#</style>
			</head>
			<body>
	</cfif>

	<!-- Alpine.js App Container -->
	<div
		x-data="testBoxApp()"
		x-init="init()"
		class="testbox-app"
		x-cloak
	>
		<!-- Top Navigation Bar -->
		<nav class="navbar navbar-expand-lg sticky-top">
			<div class="container-fluid px-4">
				<!-- Logo & Version -->
				<div class="navbar-brand d-flex align-items-center gap-3">
					<img
						src="data:image/png;base64,#toBase64( fileReadBinary( '#ASSETS_DIR#/images/testbox.png' ) )#"
						height="40"
						alt="TestBox"
					>
					<div class="d-flex flex-column">
						<span class="fs-5 fw-bold">TestBox Testing IDE</span>
						<small class="text-muted">v#testbox.getVersion()#</small>
					</div>
				</div>

				<!-- Actions -->
				<div class="d-flex align-items-center gap-2">
					<!-- Theme Toggle -->
					<button
						@click="toggleTheme()"
						class="btn btn-outline-secondary btn-sm"
						data-bs-toggle="tooltip"
						data-bs-placement="bottom"
						data-bs-title="Toggle Dark/Light Theme"
					>
						<i class="fas" :class="theme === 'dark' ? 'fa-sun' : 'fa-moon'"></i>
					</button>
				</div>
			</div>
		</nav>

		<!-- Main Container with Sidebar Layout -->
		<div class="d-flex main-layout">
			<!-- Left Sidebar -->
			<div class="sidebar" :class="{'collapsed': sidebarCollapsed}">
				<!-- Collapse Toggle -->
				<button
					@click="sidebarCollapsed = !sidebarCollapsed"
					class="sidebar-toggle"
					data-bs-toggle="tooltip"
					data-bs-placement="right"
					:data-bs-title="sidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar'"
				>
					<i class="fas" :class="sidebarCollapsed ? 'fa-chevron-right' : 'fa-chevron-left'"></i>
				</button>

				<div class="sidebar-content" x-show="!sidebarCollapsed">
					<!-- Test Results Overview -->
					<div class="sidebar-section">
						<h5 class="sidebar-title">
							<i class="fas fa-chart-line"></i>
							Test Results
						</h5>
						<div class="sidebar-stat">
							<span class="stat-label">Duration</span>
							<span class="stat-value">#numberFormat( results.getTotalDuration() )# ms</span>
						</div>
					</div>

					<!-- Stats Grid -->
					<div class="sidebar-section">
						<div class="stat-box">
							<div class="stat-label">Bundles</div>
							<div class="stat-value">#results.getTotalBundles()#</div>
						</div>
						<div class="stat-box mt-2">
							<div class="stat-label">Suites</div>
							<div class="stat-value">#results.getTotalSuites()#</div>
						</div>
						<div class="stat-box mt-2">
							<div class="stat-label">Specs</div>
							<div class="stat-value">#results.getTotalSpecs()#</div>
						</div>
					</div>

					<!-- Status Summary -->
					<div class="sidebar-section">
						<h5 class="sidebar-title">
							<i class="fas fa-clipboard-check"></i>
							Status
						</h5>

						<div class="status-summary-sidebar">
							<button
								@click="toggleStatusFilter('passed')"
								:class="{'active': statusFilter === 'passed'}"
								class="status-btn status-passed"
							>
								<i class="fas fa-check-circle"></i>
								<span>Passed</span>
								<strong>#results.getTotalPass()#</strong>
							</button>

							<button
								@click="toggleStatusFilter('failed')"
								:class="{'active': statusFilter === 'failed'}"
								class="status-btn status-failed"
							>
								<i class="fas fa-exclamation-triangle"></i>
								<span>Failed</span>
								<strong>#results.getTotalFail()#</strong>
							</button>

							<button
								@click="toggleStatusFilter('error')"
								:class="{'active': statusFilter === 'error'}"
								class="status-btn status-error"
							>
								<i class="fas fa-times-circle"></i>
								<span>Errors</span>
								<strong>#results.getTotalError()#</strong>
							</button>

							<button
								@click="toggleStatusFilter('skipped')"
								:class="{'active': statusFilter === 'skipped'}"
								class="status-btn status-skipped"
							>
								<i class="fas fa-minus-circle"></i>
								<span>Skipped</span>
								<strong>#results.getTotalSkipped()#</strong>
							</button>

							<button
								@click="statusFilter = ''"
								class="status-btn status-reset mt-2"
								x-show="statusFilter !== ''"
							>
								<i class="fas fa-redo"></i>
								<span>Reset Filter</span>
							</button>
						</div>
					</div>

					<!-- Environment Info -->
					<div class="sidebar-section">
						<h5 class="sidebar-title">
							<i class="fas fa-server"></i>
							Environment
						</h5>
						<div class="sidebar-badges">
							<span class="badge bg-info w-100 mb-2 text-wrap">
								<i class="fas fa-server"></i>
								#results.getCFMLEngine()# #results.getCFMLEngineVersion()#
							</span>
							<cfif arrayLen( results.getLabels() )>
								<span class="badge bg-secondary w-100 mb-2 text-wrap">
									<i class="fas fa-tag"></i>
									Labels: #arrayToList( results.getLabels() )#
								</span>
							</cfif>
							<cfif arrayLen( results.getExcludes() )>
								<span class="badge bg-warning text-dark w-100 text-wrap">
									<i class="fas fa-ban"></i>
									Excludes: #arrayToList( results.getExcludes() )#
								</span>
							</cfif>
						</div>
					</div>
				</div>
			</div>

			<!-- Main Content Area -->
			<div class="main-content">
				<!-- Code Coverage Stats -->
				<cfif results.getCoverageEnabled()>
					<div class="mb-4">
						#testbox.getCoverageService().renderStats( results.getCoverageData(), false )#
					</div>
				</cfif>

				<!-- Bundle Control Bar -->
				<div class="bundle-control-bar mb-4">
					<div class="d-flex gap-3 align-items-center flex-wrap">
						<!-- Search -->
						<div class="flex-grow-1" style="min-width: 300px;">
							<div class="input-group">
								<span class="input-group-text">
									<i class="fas fa-search"></i>
								</span>
								<input
									type="text"
									class="form-control"
									placeholder="Search bundles, suites, or specs..."
									x-model="searchText"
								>
							</div>
						</div>

						<!-- Bundle Controls -->
						<div class="d-flex gap-2">
						<!-- Run All Tests -->
						<a
							class="btn btn-primary"
							href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&opt_run=true"
							data-bs-toggle="tooltip"
							data-bs-placement="bottom"
							data-bs-title="Run all tests (opens in new tab)"
							target="_blank"
						>
							<i class="fas fa-play"></i> Run All
						</a>							<!-- Expand/Collapse All -->
							<button
								@click="expandAll = !expandAll"
								class="btn btn-outline-secondary"
								data-bs-toggle="tooltip"
								data-bs-placement="bottom"
								:data-bs-title="expandAll ? 'Collapse All' : 'Expand All'"
							>
								<i class="fas" :class="expandAll ? 'fa-compress' : 'fa-expand'"></i>
								<span class="d-none d-md-inline" x-text="expandAll ? 'Collapse All' : 'Expand All'"></span>
							</button>
						</div>

						<!-- Filter Stats -->
						<span class="text-muted" x-show="searchText || statusFilter">
							Showing
							<strong x-text="visibleBundleCount"></strong> bundles,
							<strong x-text="visibleSpecCount"></strong> specs
						</span>
					</div>
				</div>

				<!-- Bundle Results -->
				<div class="bundles-container">
					<cfloop array="#variables.bundleStats#" index="thisBundle">
						<!--- Skip if not in the includes list --->
						<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
							<cfcontinue>
						</cfif>

					<!-- Bundle Card -->
					<div
						class="bundle-card mb-3<cfif thisBundle.totalError gt 0> bundle-error<cfelseif thisBundle.totalFail gt 0> bundle-warning</cfif>"
						data-bundle-id="#thisBundle.id#"
						data-bundle-path="#thisBundle.path#"
						data-bundle-name="#thisBundle.name#"
						x-show="isBundleVisible('#thisBundle.id#')"
						x-data="{
							expanded: <cfif thisBundle.totalError gt 0 or thisBundle.totalFail gt 0>true<cfelse>false</cfif>,
							hasIssues: <cfif thisBundle.totalError gt 0 or thisBundle.totalFail gt 0>true<cfelse>false</cfif>
						}"
						x-init="if (!hasIssues) { $watch('$root.expandAll', value => expanded = value) }"
					>
						<!-- Bundle Header -->
						<div class="bundle-header" @click="expanded = !expanded">
								<div class="d-flex justify-content-between align-items-start">
									<div class="flex-grow-1">
										<h5 class="bundle-title mb-2">
											<i class="fas fa-folder-open text-primary"></i>
											#thisBundle.name#
											<span class="text-muted fs-6">(#numberFormat( thisBundle.totalDuration )# ms)</span>
										</h5>

										<div class="bundle-stats">
											<span class="badge badge-neutral">
												<i class="fas fa-layer-group"></i> #thisBundle.totalSuites# Suites
											</span>
											<span class="badge badge-neutral">
												<i class="fas fa-vial"></i> #thisBundle.totalSpecs# Specs
											</span>
											<span class="badge" :class="{
												'bg-success': #thisBundle.totalPass# > 0 && #thisBundle.totalFail# === 0 && #thisBundle.totalError# === 0,
												'bg-danger': #thisBundle.totalError# > 0,
												'bg-warning': #thisBundle.totalFail# > 0 && #thisBundle.totalError# === 0
											}">
												<i class="fas fa-check"></i> #thisBundle.totalPass#
												<i class="fas fa-exclamation-triangle ms-2"></i> #thisBundle.totalFail#
												<i class="fas fa-times ms-2"></i> #thisBundle.totalError#
											</span>
										</div>
									</div>

								<div class="d-flex gap-2 align-items-center">
							<!-- Open in IDE -->
							<a
							href="vscode://file/#expandPath( thisBundle.path )#"
							class="btn btn-sm btn-outline-secondary"
							data-bs-toggle="tooltip"
							data-bs-placement="bottom"
							data-bs-title="Open in VS Code"
						>
								<i class="fas fa-code"></i>
							</a>
						<!-- Run Bundle -->
						<a
								href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&testBundles=#URLEncodedFormat( thisBundle.path )#&opt_run=true&coverageEnabled=false"
								class="btn btn-sm btn-outline-primary"
								data-bs-toggle="tooltip"
								data-bs-placement="bottom"
								data-bs-title="Run this bundle (opens in new tab)"
								target="_blank"
							>
								<i class="fas fa-play"></i>
							</a>										<!-- Expand/Collapse Icon -->
									<i class="fas fa-chevron-down expand-icon" :class="{'rotate': expanded}"></i>
								</div>
								</div>
							</div>

							<!-- Bundle Body -->
							<div class="bundle-body" x-show="expanded" x-collapse>

								<!--- Global Exception --->
								<cfif !isSimpleValue( thisBundle.globalException )>
									<div class="alert alert-danger" role="alert">
										<h6 class="alert-heading">
											<i class="fas fa-exclamation-circle"></i>
											Global Bundle Exception
										</h6>
										<p class="mb-2"><strong>#encodeForHtml( thisBundle.globalException.Message )#</strong></p>
										<cfif arrayLen( thisBundle.globalException.TagContext ) && structKeyExists( thisBundle.globalException.TagContext[ 1 ], "codePrintHTML" )>
											<div class="code-snippet mt-2">
												<code>#thisBundle.globalException.TagContext[ 1 ].codePrintHTML#</code>
											</div>
										</cfif>
										<details class="mt-2">
											<summary class="cursor-pointer">Show Exception Details</summary>
											<div class="mt-2">
												<cfdump var="#thisBundle.globalException#" />
											</div>
										</details>
									</div>
								</cfif>

								<!-- Iterate over bundle suites -->
								<cfloop array="#thisBundle.suiteStats#" index="suiteStats">
									#genSuiteReport( suiteStats, thisBundle )#
								</cfloop>

								<!--- Debug Panel --->
								<cfif thisBundle.keyExists( "debugBuffer" ) && arrayLen( thisBundle.debugBuffer )>
									<div class="debug-panel mt-3" x-data="{ debugExpanded: false }">
										<div class="debug-header" @click="debugExpanded = !debugExpanded">
											<h6 class="mb-0">
												<i class="fas fa-bug text-primary"></i>
												Debug Stream
												<span class="badge bg-info text-dark">#arrayLen( thisBundle.debugBuffer )# items</span>
											</h6>
											<i class="fas fa-chevron-down" :class="{'rotate': debugExpanded}"></i>
										</div>
										<div class="debug-body" x-show="debugExpanded" x-collapse>
											<p class="text-muted mb-3">
												<i class="fas fa-info-circle"></i>
												The following data was collected in order as your tests ran via the <code>debug()</code> method:
											</p>
											<cfloop array="#thisBundle.debugBuffer#" index="thisDebug">
												<cfif !IsNull( thisDebug )>
													<div class="debug-item">
														<h6 class="debug-label">
															<i class="fas fa-tag"></i>
															#thisDebug.label#
															<span class="text-muted fs-7">
																- #dateFormat( thisDebug.timestamp, "short" )# at #timeFormat( thisDebug.timestamp, "full" )#
															</span>
														</h6>
														<cfdump
															var="#thisDebug.data#"
															label="#thisDebug.label#"
															top="#thisDebug.top#"
															showUDfs="#thisDebug.showUDFs#"
														/>
													</div>
												</cfif>
											</cfloop>
										</div>
									</div>
								</cfif>
							</div>
						</div>
					</cfloop>
				</div>
			</div>
		</div>

		<!-- Loading Overlay -->
		<div class="loading-overlay" x-show="loading">
			<div class="spinner-border text-primary" role="status">
				<span class="visually-hidden">Loading...</span>
			</div>
		</div>
	</div>

	<!-- Alpine.js Collapse Plugin (must load before Alpine core) -->
	<script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.13.3/dist/cdn.min.js"></script>

	<!-- Alpine.js Core -->
	<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.13.3/dist/cdn.min.js"></script>

	<!-- Bootstrap 5 JS -->
	<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

	<!-- TestBox App Logic -->
	<script>
		function testBoxApp() {
			return {
				// State
				theme: localStorage.getItem('testbox-theme') || 'dark',
				sidebarCollapsed: false,
				searchText: '',
				statusFilter: '',
				expandAll: false,
				loading: false,
				visibleBundleCount: #arrayLen( variables.bundleStats )#,
				visibleSpecCount: #results.getTotalSpecs()#,

				// Initialize
				init() {
					// Apply theme
					document.documentElement.setAttribute('data-theme', this.theme);

					// Initialize Bootstrap tooltips
					const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
					tooltipTriggerList.forEach(function (tooltipTriggerEl) {
						new bootstrap.Tooltip(tooltipTriggerEl);
					});

					// Set up keyboard shortcuts
					document.addEventListener('keydown', (e) => {
						// Ctrl/Cmd + K for search
						if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
							e.preventDefault();
							document.querySelector('input[placeholder*="Search"]').focus();
						}
						// Ctrl/Cmd + E for expand/collapse
						if ((e.ctrlKey || e.metaKey) && e.key === 'e') {
							e.preventDefault();
							this.expandAll = !this.expandAll;
						}
					});

					// Watch for filter changes
					this.$watch('searchText', () => this.updateVisibility());
					this.$watch('statusFilter', () => this.updateVisibility());
				},

				// Toggle theme
				toggleTheme() {
					this.theme = this.theme === 'dark' ? 'light' : 'dark';
					localStorage.setItem('testbox-theme', this.theme);
					document.documentElement.setAttribute('data-theme', this.theme);
				},

				// Toggle status filter
				toggleStatusFilter(status) {
					this.statusFilter = this.statusFilter === status ? '' : status;
				},

				// Check if bundle is visible
				isBundleVisible(bundleId) {
					const bundleEl = document.querySelector(`[data-bundle-id="${bundleId}"]`);
					if (!bundleEl) return true;

					const bundlePath = bundleEl.dataset.bundlePath?.toLowerCase() || '';
					const bundleName = bundleEl.dataset.bundleName?.toLowerCase() || '';
					const search = this.searchText.toLowerCase();

					// Get all specs in this bundle
					const specs = bundleEl.querySelectorAll('.spec-item');

					// Apply filters to each spec
					let hasVisibleSpec = false;
					specs.forEach(spec => {
						const specName = spec.dataset.specName?.toLowerCase() || '';
						const specStatus = spec.dataset.status?.toLowerCase() || '';

						let visible = true;

						// Check search filter
						if (search) {
							if (!bundlePath.includes(search) && !bundleName.includes(search) && !specName.includes(search)) {
								visible = false;
							}
						}

						// Check status filter
						if (this.statusFilter && specStatus !== this.statusFilter) {
							visible = false;
						}

						// Hide/show spec
						spec.style.display = visible ? '' : 'none';
						if (visible) hasVisibleSpec = true;
					});

					return hasVisibleSpec;
				},

				// Update visibility counts
				updateVisibility() {
					this.$nextTick(() => {
						let visibleBundles = 0;
						let visibleSpecs = 0;

						document.querySelectorAll('.bundle-card').forEach(bundle => {
							const isVisible = this.isBundleVisible(bundle.dataset.bundleId);
							if (isVisible) {
								visibleBundles++;
								const visibleSpecEls = bundle.querySelectorAll('.spec-item:not([style*="display: none"])');
								visibleSpecs += visibleSpecEls.length;
							}
						});

						this.visibleBundleCount = visibleBundles;
						this.visibleSpecCount = visibleSpecs;
					});
				}
			}
		}
	</script>

	<cfif url.fullPage>
			</body>
		</html>
	</cfif>
</cfoutput>

<!--- ****************************************************************************************** --->
<!--- TEMPLATE FUNCTIONS --->
<!--- ****************************************************************************************** --->

<!--- Recursive Suite Generator --->
<cffunction name="genSuiteReport" output="false">
	<cfargument name="suiteStats">
	<cfargument name="bundleStats">
	<cfsavecontent variable="local.report">
		<cfoutput>
			<div
				class="suite-item #arguments.suiteStats.status#"
				data-suite-id="#arguments.suiteStats.id#"
				data-bundle-id="#arguments.bundleStats.id#"
				x-data="{ suiteExpanded: true }"
			>
				<!-- Suite Header -->
				<div class="suite-header" @click="suiteExpanded = !suiteExpanded">
					<div class="d-flex justify-content-between align-items-center">
						<div>
							<i class="fas #statusToIcon( arguments.suiteStats.status )# text-#statusToClass( arguments.suiteStats.status )#"></i>
						<strong>#arguments.suiteStats.name#</strong>
						<span class="text-muted">(#numberFormat( arguments.suiteStats.totalDuration )# ms)</span>
						<span class="badge badge-neutral ms-2">
							#arguments.suiteStats.totalSpecs# specs
						</span>
						</div>
						<div class="d-flex gap-2 align-items-center">
							<a
								href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&testSuites=#URLEncodedFormat( arguments.suiteStats.name )#&testBundles=#URLEncodedFormat( arguments.bundleStats.path )#&opt_run=true&coverageEnabled=false"
								class="btn btn-sm btn-outline-secondary"
								@click.stop
								data-bs-toggle="tooltip"
								data-bs-placement="bottom"
								data-bs-title="Run this suite"
								target="_blank"
							>
								<i class="fas fa-play"></i>
							</a>
							<i class="fas fa-chevron-down" :class="{'rotate': suiteExpanded}"></i>
						</div>
					</div>
				</div>

				<!-- Suite Body with Specs -->
				<div class="suite-body" x-show="suiteExpanded" x-collapse>
					<cfloop array="#arguments.suiteStats.specStats#" index="local.thisSpec">
						#genSpecReport( local.thisSpec, arguments.bundleStats, arguments.suiteStats )#
					</cfloop>

					<!--- Nested Suites --->
					<cfif arrayLen( arguments.suiteStats.suiteStats )>
						<div class="nested-suites">
							<cfloop array="#arguments.suiteStats.suiteStats#" index="local.nestedSuite">
								#genSuiteReport( local.nestedSuite, arguments.bundleStats )#
							</cfloop>
						</div>
					</cfif>
				</div>
			</div>
		</cfoutput>
	</cfsavecontent>
	<cfreturn local.report>
</cffunction>

<!--- Spec Report Generator --->
<cffunction name="genSpecReport" output="false">
	<cfargument name="spec">
	<cfargument name="bundleStats">
	<cfargument name="suiteStats">
	<cfsavecontent variable="local.report">
		<cfoutput>
			<div
				class="spec-item spec-#arguments.spec.status#"
				data-spec-id="#arguments.spec.id#"
				data-spec-name="#arguments.spec.displayName#"
				data-status="#arguments.spec.status#"
				x-data="{ specExpanded: false }"
			>
				<div class="spec-content">
					<div class="d-flex justify-content-between align-items-start">
						<div class="flex-grow-1">
							<!-- Spec Name -->
							<div class="spec-name">
								<i class="fas #statusToIcon( arguments.spec.status )# spec-icon-#arguments.spec.status#"></i>
								<span class="spec-title">#arguments.spec.displayName#</span>
								<span class="spec-duration">(#numberFormat( arguments.spec.totalDuration )# ms)</span>
							</div>

							<!-- Spec Message (for failures/errors) -->
							<cfif arguments.spec.status eq "failed">
								<div class="spec-message spec-message-failed">
									<i class="fas fa-exclamation-triangle"></i>
									<strong>#encodeForHTML( arguments.spec.failMessage )#</strong>
								</div>
							<cfelseif arguments.spec.status eq "error">
								<div class="spec-message spec-message-error">
									<i class="fas fa-times-circle"></i>
									<strong>#encodeForHTML( arguments.spec.error.message & " " & arguments.spec.error.detail )#</strong>
								</div>
							</cfif>

							<!-- Stack Trace Preview (first occurrence) -->
							<cfif arguments.spec.status eq "failed" && isArray( arguments.spec.failOrigin ) && arrayLen( arguments.spec.failOrigin )>
								<cfloop array="#arguments.spec.failOrigin#" item="thisContext">
									<cfif findNoCase( arguments.bundleStats.path, reReplace( thisContext.template, "(/|\\)", ".", "all" ) )>
										<div class="stack-trace-preview">
											<i class="fas fa-file-code"></i>
											<a href="#openInEditorURL( thisContext.template, thisContext.line, url.editor )#" target="_blank">
												#thisContext.template#:#thisContext.line#
											</a>
										</div>
										<cfif structKeyExists( thisContext, "codePrintHTML" )>
											<div class="code-snippet">
												<code>#thisContext.codePrintHTML#</code>
											</div>
										</cfif>
										<cfbreak>
									</cfif>
								</cfloop>
							<cfelseif arguments.spec.status eq "error" && !isNull( arguments.spec.error.tagContext ) && arrayLen( arguments.spec.error.tagContext )>
								<cfset var thisContext = arguments.spec.error.tagContext[ 1 ]>
								<div class="stack-trace-preview">
									<i class="fas fa-file-code"></i>
									<a href="#openInEditorURL( thisContext.template, thisContext.line, url.editor )#" target="_blank">
										#thisContext.template#:#thisContext.line#
									</a>
								</div>
								<cfif structKeyExists( thisContext, "codePrintHTML" )>
									<div class="code-snippet">
										<code>#thisContext.codePrintHTML#</code>
									</div>
								</cfif>
							</cfif>
						</div>

						<!-- Actions -->
						<div class="spec-actions">
							<cfif arguments.spec.status neq "skipped">
								<a
									href="#variables.baseURL#&directory=#URLEncodedFormat( URL.directory )#&testSpecs=#URLEncodedFormat( arguments.spec.id )#&testBundles=#URLEncodedFormat( arguments.bundleStats.path )#&opt_run=true&coverageEnabled=false"
									class="btn btn-sm btn-outline-secondary"
									data-bs-toggle="tooltip"
									data-bs-placement="bottom"
									data-bs-title="Run this spec"
								>
									<i class="fas fa-play"></i>
								</a>
							</cfif>

						<cfif arguments.spec.status eq "failed" or arguments.spec.status eq "error">
							<button
								@click="specExpanded = !specExpanded"
								class="btn btn-sm btn-outline-secondary"
								data-bs-toggle="tooltip"
								data-bs-placement="bottom"
								data-bs-title="View full stack trace"
							>
									<i class="fas fa-code"></i>
								</button>
							</cfif>
						</div>
					</div>

					<!-- Detailed Stack Trace (collapsed by default) -->
					<cfif arguments.spec.status eq "failed" or arguments.spec.status eq "error">
						<div class="spec-details" x-show="specExpanded" x-collapse>
							<div class="stack-trace-full">
								<h6>
									<i class="fas fa-layer-group"></i>
									Full Stack Trace
								</h6>

								<!-- Failure Origin -->
								<cfif arguments.spec.status eq "failed" && isArray( arguments.spec.failOrigin )>
									<cfloop array="#arguments.spec.failOrigin#" index="thisStack">
										<div class="stack-frame">
											<a href="#openInEditorURL( thisStack.template, thisStack.line, url.editor )#" target="_blank">
												<i class="fas fa-external-link-alt"></i>
												#thisStack.template#:#thisStack.line#
											</a>
											<cfif !isNull( thisStack.codePrintPlain )>
												<pre class="mt-2"><code>#thisStack.codePrintPlain#</code></pre>
											</cfif>
										</div>
									</cfloop>
								</cfif>

								<!-- Error Stack Trace -->
								<cfif arguments.spec.status eq "error" && !isNull( arguments.spec.error.stackTrace )>
									<div class="mt-3">
										<h6>Raw Stack Trace</h6>
										<pre class="stack-trace-raw"><code>#encodeForHTML( arguments.spec.error.stackTrace )#</code></pre>
									</div>
								</cfif>

								<!-- Failure Details -->
								<cfif arguments.spec.status eq "failed" && len( arguments.spec.failDetail )>
									<div class="mt-3">
										<h6>Failure Details</h6>
										<cfdump var="#arguments.spec.failDetail#">
									</div>
								</cfif>

								<!-- Extended Info -->
								<cfif arguments.spec.status eq "failed" && len( arguments.spec.failExtendedInfo )>
									<div class="mt-3">
										<h6>Extended Information</h6>
										<cfdump var="#arguments.spec.failExtendedInfo#">
									</div>
								</cfif>
							</div>
						</div>
					</cfif>
				</div>
			</div>
		</cfoutput>
	</cfsavecontent>
	<cfreturn local.report>
</cffunction>
