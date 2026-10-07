<!--- A suite with its specs and, recursively, its nested suites. Inputs: arguments.data.suite, arguments.data.bundle --->
<cfset local.suite  = arguments.data.suite>
<cfset local.bundle = arguments.data.bundle>
<cfoutput>
<li class="tb-suite" data-status="#variables.helper.status( local.suite.status ).key#">
	<div class="tb-suite__header">
		<svg class="tb-icon" aria-hidden="true"><use href="##i-layers"/></svg>
		<a
			href="#variables.helper.href( variables.helper.runURL( bundle = local.bundle.path, suite = local.suite.name ) )#"
			title="Run only this suite. Total: #local.suite.totalSpecs# Passed: #local.suite.totalPass# Failed: #local.suite.totalFail# Errors: #local.suite.totalError# Skipped: #local.suite.totalSkipped#"
		>#encodeForHtml( local.suite.name )#</a>
		<span class="tb-spec__ms tb-num">#encodeForHtml( variables.helper.duration( local.suite.totalDuration ) )#</span>
	</div>

	<cfif arrayLen( local.suite.specStats )>
		<ul class="tb-spec-list">
			<cfloop array="#local.suite.specStats#" item="thisSpec">
				<cfset local.status  = variables.helper.status( thisSpec.status )>
				<cfset local.message = variables.helper.specMessage( thisSpec )>
				<li
					class="tb-spec"
					data-spec
					data-status="#local.status.key#"
					data-bundle="#encodeForHtml( local.bundle.id )#"
					data-spec-id="#encodeForHtml( thisSpec.id )#"
					data-search="#encodeForHtml( lCase( "#thisSpec.displayName# #local.suite.name# #local.bundle.path#" ) )#"
				>
					<svg class="tb-icon tb-st-icon" aria-hidden="true"><use href="##i-#local.status.icon#"/></svg>
					<a
						class="tb-spec__name"
						href="#variables.helper.href( variables.helper.runURL( bundle = local.bundle.path, spec = thisSpec.id ) )#"
						title="Run only this spec"
					>#encodeForHtml( thisSpec.displayName )#</a>
					<span class="tb-spec__ms tb-num">#encodeForHtml( variables.helper.duration( thisSpec.totalDuration ) )#</span>
					<cfif len( local.message )>
						<p class="tb-spec__message">
							#encodeForHtml( local.message )#
							<a href="##failure-#encodeForHtml( thisSpec.id )#">Details</a>
						</p>
					</cfif>
				</li>
			</cfloop>
		</ul>
	</cfif>

	<cfif arrayLen( local.suite.suiteStats )>
		<ul class="tb-suite-list">
			<cfloop array="#local.suite.suiteStats#" item="thisNested">
				#renderPartial( "suite", { suite : thisNested, bundle : local.bundle } )#
			</cfloop>
		</ul>
	</cfif>
</li>
</cfoutput>
