<!---
	Simple reporter layout: failures first, then every bundle.
	Inputs (set by BaseHTMLReporter): results, testbox, bundleStats, helper, verdict, failureList
	All logic lives in ReportHelper.cfc: BoxLang's transpiler drops tag-form functions in .cfm files (BL-2736).
--->
<cfsavecontent variable="local.content">
<cfoutput>
#renderPartial( "toolbar" )#

<cfif arrayLen( variables.failureList )>
	<section aria-labelledby="tb-failures-title">
		<h2 id="tb-failures-title" class="tb-section-title">
			Needs attention <span class="tb-num">(#arrayLen( variables.failureList )#)</span>
		</h2>
		<cfloop array="#variables.failureList#" item="thisFailure">
			#renderPartial( "failure", { failure : thisFailure } )#
		</cfloop>
	</section>
</cfif>

<section aria-labelledby="tb-bundles-title">
	<h2 id="tb-bundles-title" class="tb-section-title">Bundles</h2>
	<cfloop array="#variables.bundleStats#" item="thisBundle">
		<!--- skip bundles outside ?testBundles= --->
		<cfif !variables.helper.includesBundle( thisBundle )>
			<cfcontinue>
		</cfif>
		#renderPartial( "bundle", { bundle : thisBundle } )#
	</cfloop>
	<p id="tb-no-matches" class="tb-empty" hidden>No bundles match the current filters.</p>
</section>
</cfoutput>
</cfsavecontent>
<cfoutput>#renderPartial( "page", { content : local.content } )#</cfoutput>
