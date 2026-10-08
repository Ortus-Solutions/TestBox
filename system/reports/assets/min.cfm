<!---
	Min reporter layout: the verdict, a one line per failure list, and the bundle exceptions and debug streams.
	It deliberately leaves out specs that passed.
--->
<cfsavecontent variable="local.content">
<cfoutput>
<cfif arrayLen( variables.failureList )>
	<section aria-labelledby="tb-failures-title">
		<h2 id="tb-failures-title" class="tb-section-title">
			Needs attention <span class="tb-num">(#arrayLen( variables.failureList )#)</span>
		</h2>
		<ul class="list-group tb-min-failures">
			<cfloop array="#variables.failureList#" item="thisFailure">
				<cfset local.status = variables.helper.status( thisFailure.spec.status )>
				<li class="list-group-item d-flex flex-wrap align-items-baseline gap-2" data-status="#local.status.key#">
					<span class="tb-badge">
						<svg class="tb-icon" aria-hidden="true"><use href="##i-#local.status.icon#"/></svg> #local.status.label#
					</span>
					<a
						class="fw-semibold"
						href="#variables.helper.href( variables.helper.runURL( bundle = thisFailure.bundle.path, spec = thisFailure.spec.id ) )#"
						title="Run only this spec"
					>#encodeForHtml( thisFailure.spec.displayName )#</a>
					<span class="tb-crumb">#encodeForHtml( thisFailure.bundle.path )# &gt; #encodeForHtml( thisFailure.crumb )#</span>
					<span class="w-100 small text-break">#encodeForHtml( thisFailure.message )#</span>
				</li>
			</cfloop>
		</ul>
	</section>
</cfif>

<!--- the Copy all failures for AI button reads these --->
<cfif variables.helper.getOptions().aiAssist>
	<cfloop array="#variables.failureList#" item="thisFailure">
		#renderPartial( "ask-payloads", { failure : thisFailure } )#
	</cfloop>
</cfif>

<cfloop array="#variables.bundleStats#" item="thisBundle">
	<cfset local.hasException = !isSimpleValue( thisBundle.globalException )>
	<cfset local.hasDebug     = structKeyExists( thisBundle, "debugBuffer" ) && arrayLen( thisBundle.debugBuffer )>
	<cfif local.hasException || local.hasDebug>
		<section class="card tb-bundle mt-3" aria-labelledby="bundle-title-#variables.helper.safeId( thisBundle.id )#">
			<header class="card-header">
				<h3 class="h6 m-0" id="bundle-title-#variables.helper.safeId( thisBundle.id )#">
					#encodeForHtml( thisBundle.name )#
					<cfif thisBundle.name != thisBundle.path>
						<span class="tb-bundle__path">#encodeForHtml( thisBundle.path )#</span>
					</cfif>
				</h3>
			</header>
			<cfif local.hasException>
				#renderPartial( "exception", { bundle : thisBundle } )#
			</cfif>
			<cfif local.hasDebug>
				#renderPartial( "debug", { bundle : thisBundle } )#
			</cfif>
		</section>
	</cfif>
</cfloop>
</cfoutput>
</cfsavecontent>
<cfoutput>#renderPartial( "page", { content : local.content } )#</cfoutput>
