<!--- The verdict is the first thing you see: green, or red with the counts. Bundle exceptions sit above it. --->
<cfoutput>
<cfloop array="#variables.helper.exceptions( variables.bundleStats )#" item="thisBundle">
	<div class="alert tb-exception d-flex align-items-start gap-3" role="alert">
		<svg class="tb-icon tb-verdict__icon" style="color: var(--tb-error)" aria-hidden="true"><use href="##i-exclamation-octagon-fill"/></svg>
		<div class="min-w-0">
			<h2 class="mb-1">Bundle exception: #encodeForHtml( thisBundle.name )# could not run</h2>
			<p class="mb-1">#encodeForHtml( thisBundle.globalException.message ?: "" )#</p>
			<a href="##bundle-#encodeForHtml( thisBundle.id )#">Go to the bundle</a>
		</div>
	</div>
</cfloop>

<section
	class="tb-verdict tb-verdict--#( variables.verdict.bad ? "bad" : "good" )#"
	aria-labelledby="tb-verdict-title"
	role="status"
>
	<div class="tb-verdict__main">
		<svg class="tb-icon tb-verdict__icon" aria-hidden="true">
			<use href="##i-#( variables.verdict.bad ? "x-circle-fill" : "check-circle-fill" )#"/>
		</svg>
		<div>
			<h1 id="tb-verdict-title" class="tb-verdict__title">#encodeForHtml( variables.verdict.title )#</h1>
			<p class="tb-verdict__sub tb-num">#encodeForHtml( variables.verdict.subtitle )#</p>
		</div>
	</div>

	<cfif variables.verdict.bad>
		<div class="d-flex flex-wrap gap-2">
			<button type="button" class="btn btn-sm" @click="nextFailure()">
				<svg class="tb-icon" aria-hidden="true"><use href="##i-arrow-repeat"/></svg> Next failure <span class="tb-kbd">F</span>
			</button>
			<cfif variables.helper.getOptions().aiAssist>
				<button type="button" class="btn btn-sm" @click="aiCopyAll()" title="One prompt with every failure and error">
					<svg class="tb-icon" aria-hidden="true"><use href="##i-stars"/></svg> Copy all failures for AI
				</button>
			</cfif>
		</div>
	</cfif>

	<div class="progress-stacked tb-verdict__bar" role="img" aria-label="#encodeForHtml( variables.verdict.subtitle )#">
		<cfloop array="#variables.helper.statusList()#" item="thisStatus">
			<cfif variables.verdict.counts[ thisStatus.key ]>
				<div class="progress" style="width: #variables.verdict.percent[ thisStatus.key ]#%">
					<div class="progress-bar tb-bar--#thisStatus.key#"></div>
				</div>
			</cfif>
		</cfloop>
	</div>

	<div class="tb-verdict__chips" role="group" aria-label="Filter by status">
		<cfloop array="#variables.helper.statusList()#" item="thisStatus">
			<button
				type="button"
				class="tb-chip"
				:aria-pressed="statuses.includes( '#thisStatus.key#' )"
				@click="toggleStatus( '#thisStatus.key#' )"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-#thisStatus.icon#"/></svg>
				#thisStatus.label# <span class="tb-num">#variables.verdict.counts[ thisStatus.key ]#</span>
			</button>
		</cfloop>
		<button type="button" class="tb-chip" x-show="filtering" x-cloak @click="resetFilters()">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-x-lg"/></svg> Reset filters
		</button>
	</div>
</section>

<dl class="tb-meta">
	<div><dt>Bundles</dt> <dd>#variables.results.getTotalBundles()#</dd></div>
	<div><dt>Suites</dt> <dd>#variables.results.getTotalSuites()#</dd></div>
	<div><dt>Specs</dt> <dd>#variables.results.getTotalSpecs()#</dd></div>
	<div>
		<dt><svg class="tb-icon" aria-hidden="true"><use href="##i-stopwatch"/></svg> Duration</dt>
		<dd>#encodeForHtml( variables.helper.duration( variables.results.getTotalDuration() ) )#</dd>
	</div>
	<cfif arrayLen( variables.results.getLabels() )>
		<div>
			<dt><svg class="tb-icon" aria-hidden="true"><use href="##i-tag"/></svg> Labels</dt>
			<dd>#encodeForHtml( arrayToList( variables.results.getLabels(), ", " ) )#</dd>
		</div>
	</cfif>
	<cfif arrayLen( variables.results.getExcludes() )>
		<div><dt>Excludes</dt> <dd>#encodeForHtml( arrayToList( variables.results.getExcludes(), ", " ) )#</dd></div>
	</cfif>
</dl>
</cfoutput>
