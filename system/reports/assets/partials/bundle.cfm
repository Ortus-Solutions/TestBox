<!--- One bundle: a collapsible card with its own status filters, a run link and its suites. Input: arguments.data.bundle --->
<cfset local.bundle  = arguments.data.bundle>
<cfset local.id      = encodeForHtml( local.bundle.id )>
<cfset local.jsId    = variables.helper.safeId( local.bundle.id )>
<cfset local.problem = variables.helper.bundleHasProblems( local.bundle )>
<cfset local.counts  = {
	"passed"  : local.bundle.totalPass,
	"failed"  : local.bundle.totalFail,
	"error"   : max( 0, local.bundle.totalError ),
	"skipped" : local.bundle.totalSkipped
}>
<cfoutput>
<section
	class="card tb-bundle#( local.problem ? " tb-bundle--problem" : "" )#"
	id="bundle-#local.id#"
	data-bundle="#local.id#"
	aria-labelledby="bundle-title-#local.id#"
>
	<header class="card-header tb-bundle__header">
		<h3 class="tb-bundle__heading" id="bundle-title-#local.id#">
			<button
				type="button"
				class="tb-bundle__toggle"
				@click="toggle( '#local.jsId#' )"
				:aria-expanded="isOpen( '#local.jsId#' )"
				aria-controls="bundle-body-#local.id#"
			>
				<svg class="tb-icon tb-chevron" :class="{ 'tb-chevron--open': isOpen( '#local.jsId#' ) }" aria-hidden="true"><use href="##i-chevron-right"/></svg>
				<span>#encodeForHtml( local.bundle.name )#</span>
				<cfif local.bundle.name != local.bundle.path>
					<span class="tb-bundle__path">#encodeForHtml( local.bundle.path )#</span>
				</cfif>
			</button>
		</h3>

		<div class="tb-bundle__stats">
			<div class="progress-stacked tb-minibar" aria-hidden="true">
				<cfloop array="#variables.helper.statusList()#" item="thisStatus">
					<cfif local.counts[ thisStatus.key ]>
						<div class="progress" data-status="#thisStatus.key#" style="width: #variables.helper.percentOf( local.counts[ thisStatus.key ], local.bundle.totalSpecs )#%">
							<div class="progress-bar"></div>
						</div>
					</cfif>
				</cfloop>
			</div>
			<cfloop array="#variables.helper.statusList()#" item="thisStatus">
				<cfif local.counts[ thisStatus.key ]>
					<span class="tb-badge tb-num" data-status="#thisStatus.key#">#local.counts[ thisStatus.key ]# #thisStatus.short#</span>
				</cfif>
			</cfloop>
			<span class="small text-body-secondary tb-num">#encodeForHtml( variables.helper.duration( local.bundle.totalDuration ) )#</span>
		</div>
	</header>

	<div id="bundle-body-#local.id#" x-show="isOpen( '#local.jsId#' )" x-cloak>
		<div class="tb-bundle__filters">
			<span>Filter this bundle</span>
			<cfloop array="#variables.helper.statusList()#" item="thisStatus">
				<button
					type="button"
					class="tb-chip tb-chip--plain"
					:aria-pressed="bundleStatus[ '#local.jsId#' ] === '#thisStatus.key#'"
					@click="toggleBundleStatus( '#local.jsId#', '#thisStatus.key#' )"
				>
					<svg class="tb-icon" aria-hidden="true"><use href="##i-#thisStatus.icon#"/></svg> #thisStatus.label#
				</button>
			</cfloop>
			<button type="button" class="btn btn-sm btn-link py-0" x-show="bundleStatus[ '#local.jsId#' ]" x-cloak @click="bundleStatus[ '#local.jsId#' ] = null">Reset</button>
			<a
				class="btn btn-sm btn-outline-secondary ms-auto"
				href="#variables.helper.href( variables.helper.runURL( bundle = local.bundle.path ) )#"
				title="Run only this bundle"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-play-fill"/></svg> Run this bundle
			</a>
		</div>

		<!--- a global exception means the bundle never ran: say it plainly --->
		<cfif !isSimpleValue( local.bundle.globalException )>
			#renderPartial( "exception", { bundle : local.bundle } )#
		</cfif>

		<ul class="tb-suite-list">
			<cfloop array="#local.bundle.suiteStats#" item="thisSuite">
				#renderPartial( "suite", { suite : thisSuite, bundle : local.bundle } )#
			</cfloop>
		</ul>
		<p class="tb-empty" hidden>No specs match the current filters.</p>

		<cfif structKeyExists( local.bundle, "debugBuffer" ) && arrayLen( local.bundle.debugBuffer )>
			#renderPartial( "debug", { bundle : local.bundle } )#
		</cfif>
	</div>
</section>
</cfoutput>
