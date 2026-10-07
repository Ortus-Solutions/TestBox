<!--- Code coverage summary card. Shown when coverage was collected. --->
<cfset local.data    = variables.results.getCoverageData()>
<cfset local.stats   = local.data.stats>
<cfset local.percent = numberFormat( local.stats.percTotalCoverage * 100, "9.9" )>
<cfset local.tone    = variables.helper.coverageTone( local.percent, variables.testbox )>
<cfoutput>
<section class="card tb-coverage mb-3" aria-labelledby="tb-coverage-title" x-data="{ coverageOpen: false }">
	<header class="card-header d-flex flex-wrap align-items-center gap-3">
		<h2 id="tb-coverage-title" class="h6 m-0 d-flex align-items-center gap-2">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-graph-up-arrow"/></svg> Code coverage
		</h2>
		<div
			class="progress tb-coverage__bar"
			role="progressbar"
			aria-label="Total coverage"
			aria-valuenow="#local.percent#"
			aria-valuemin="0"
			aria-valuemax="100"
		>
			<div class="progress-bar bg-#encodeForHtml( local.tone )# tb-num" style="width: #local.percent#%">#local.percent#%</div>
		</div>
		<span class="small text-body-secondary">Files processed <strong class="text-body tb-num">#local.stats.numFiles#</strong></span>
		<button
			type="button"
			class="btn btn-sm btn-outline-secondary ms-auto"
			@click="coverageOpen = !coverageOpen"
			:aria-expanded="coverageOpen"
			aria-controls="tb-coverage-details"
		>
			<svg class="tb-icon tb-chevron" :class="{ 'tb-chevron--open': coverageOpen }" aria-hidden="true"><use href="##i-chevron-right"/></svg> Details
		</button>
	</header>

	<div id="tb-coverage-details" class="card-body" x-show="coverageOpen" x-cloak>
		<cfif len( local.data.sonarQubeResults )>
			<p class="small">SonarQube coverage XML written to <code>#encodeForHtml( local.data.sonarQubeResults )#</code></p>
		</cfif>
		<cfif len( local.data.browserResults )>
			<p class="small">Coverage browser written to <code>#encodeForHtml( local.data.browserResults )#</code></p>
		</cfif>

		<div class="row g-4">
			<cfloop list="Best,Worst" item="thisKind">
				<cfset local.files = local.stats[ "qryFiles#thisKind#Coverage" ]>
				<div class="col-lg-6">
					<h3 class="h6">Files with #lCase( thisKind )# coverage</h3>
					<ol class="list-unstyled d-grid gap-2 mb-0">
						<cfloop query="local.files">
							<cfset local.filePercent = numberFormat( local.files.percCoverage * 100, "9.9" )>
							<li class="d-flex flex-wrap align-items-center gap-2">
								<span class="tb-mono small flex-grow-1 text-break">#encodeForHtml( replaceNoCase( local.files.filePath, variables.testbox.getCoverageService().getCoverageOptions().pathToCapture, "" ) )#</span>
								<div class="progress tb-coverage__bar" role="progressbar" aria-valuenow="#local.filePercent#" aria-valuemin="0" aria-valuemax="100">
									<div class="progress-bar bg-#encodeForHtml( variables.helper.coverageTone( local.filePercent, variables.testbox ) )# tb-num" style="width: #local.filePercent#%">#local.filePercent#%</div>
								</div>
							</li>
						</cfloop>
					</ol>
				</div>
			</cfloop>
		</div>
	</div>
</section>
</cfoutput>
