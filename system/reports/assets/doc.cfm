<!---
	Doc reporter layout: the run as a document. A bundle is a section, a suite a nested section,
	a spec an entry in a description list. Reads well on screen and on paper.
--->
<cfsavecontent variable="local.content">
<cfoutput>
#renderPartial( "toolbar", { expand : false } )#

<div class="tb-doc">
	<nav class="tb-doc-nav" aria-label="Bundles">
		<ul>
			<cfloop array="#variables.bundleStats#" item="thisBundle">
				<cfif !variables.helper.includesBundle( thisBundle )>
					<cfcontinue>
				</cfif>
				<cfset local.problem = variables.helper.bundleHasProblems( thisBundle )>
				<li>
					<a href="##bundle-#variables.helper.safeId( thisBundle.id )#" data-bundle="#variables.helper.safeId( thisBundle.id )#">
						<svg class="tb-icon tb-st-icon" data-status="#( local.problem ? "failed" : "passed" )#" aria-hidden="true">
							<use href="##i-#( local.problem ? "x-circle-fill" : "check-circle-fill" )#"/>
						</svg>
						#encodeForHtml( thisBundle.name )#
					</a>
				</li>
			</cfloop>
		</ul>
	</nav>

	<article>
		<cfloop array="#variables.bundleStats#" item="thisBundle">
			<cfif !variables.helper.includesBundle( thisBundle )>
				<cfcontinue>
			</cfif>
			<cfset local.bundleId = variables.helper.safeId( thisBundle.id )>
			<section
				class="tb-doc-bundle tb-bundle"
				id="bundle-#local.bundleId#"
				data-bundle="#local.bundleId#"
				aria-labelledby="bundle-title-#local.bundleId#"
			>
				<h2 id="bundle-title-#local.bundleId#">#encodeForHtml( thisBundle.name )#</h2>
				<p class="small text-body-secondary tb-num">
					<span class="tb-mono">#encodeForHtml( thisBundle.path )#</span>
					&middot; #variables.helper.plural( thisBundle.totalSpecs, "spec" )#
					&middot; #encodeForHtml( variables.helper.duration( thisBundle.totalDuration ) )#
					&middot; <a href="#variables.helper.href( variables.helper.runURL( bundle = thisBundle.path ) )#">Run this bundle</a>
				</p>

				<cfif !isSimpleValue( thisBundle.globalException )>
					#renderPartial( "exception", { bundle : thisBundle } )#
				</cfif>

				<cfloop array="#thisBundle.suiteStats#" item="thisSuite">
					#renderPartial( "doc-suite", { suite : thisSuite, bundle : thisBundle, level : 3 } )#
				</cfloop>

				<cfif structKeyExists( thisBundle, "debugBuffer" ) && arrayLen( thisBundle.debugBuffer )>
					#renderPartial( "debug", { bundle : thisBundle } )#
				</cfif>
				<p class="tb-empty" hidden>No specs match the current filters.</p>
			</section>
		</cfloop>
		<p id="tb-no-matches" class="tb-empty" hidden>No bundles match the current filters.</p>
	</article>
</div>

<!--- payloads for Ask AI --->
<cfif variables.helper.getOptions().aiAssist>
	<cfloop array="#variables.failureList#" item="thisFailure">
		#renderPartial( "ask-payloads", { failure : thisFailure } )#
	</cfloop>
</cfif>
</cfoutput>
</cfsavecontent>
<cfoutput>#renderPartial( "page", { content : local.content } )#</cfoutput>
