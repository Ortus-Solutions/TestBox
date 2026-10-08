<!---
	Dot reporter layout: one dot per spec, grouped by bundle. A click opens the details in a drawer.
	Filters dim the dots that do not match instead of removing them, so the shape of the run stays put.
--->
<cfsavecontent variable="local.content">
<cfoutput>
#renderPartial( "toolbar", { expand : false } )#

<section aria-labelledby="tb-bundles-title">
	<h2 id="tb-bundles-title" class="tb-section-title">Specs</h2>
	<cfloop array="#variables.bundleStats#" item="thisBundle">
		<cfif !variables.helper.includesBundle( thisBundle )>
			<cfcontinue>
		</cfif>
		<cfset local.bundleId = variables.helper.safeId( thisBundle.id )>
		<section
			class="card tb-bundle mb-3#( variables.helper.bundleHasProblems( thisBundle ) ? " tb-bundle--problem" : "" )#"
			id="bundle-#local.bundleId#"
			data-bundle="#local.bundleId#"
			aria-labelledby="bundle-title-#local.bundleId#"
		>
			<header class="card-header d-flex flex-wrap align-items-center gap-2">
				<h3 class="h6 m-0" id="bundle-title-#local.bundleId#"
					title="Bundle #encodeForHtml( thisBundle.path )#"
				>
					#encodeForHtml( thisBundle.name )#
				</h3>
				<span class="ms-auto d-flex flex-wrap gap-2">
					<cfloop array="#variables.helper.statusList()#" item="thisStatus">
						<cfset local.count = variables.helper.countOf( thisBundle, thisStatus.key )>
						<cfif local.count>
							<span class="tb-badge tb-num" data-status="#thisStatus.key#">#local.count# #thisStatus.short#</span>
						</cfif>
					</cfloop>
				</span>
			</header>

			<cfif !isSimpleValue( thisBundle.globalException )>
				#renderPartial( "exception", { bundle : thisBundle } )#
			</cfif>

			<!--- no whitespace between the dots: they flow like text --->
			<div class="tb-dots" role="group" aria-label="Specs of #encodeForHtml( thisBundle.name )#" @click="dotClick( $event )"><cfloop array="#variables.helper.specs( thisBundle )#" item="thisEntry"><cfset local.s = thisEntry.spec><cfset local.st = variables.helper.status( local.s.status )><button
				type="button"
				class="tb-dot"
				data-spec
				data-dim
				data-status="#local.st.key#"
				data-bundle="#local.bundleId#"
				data-bundle-name="#encodeForHtml( thisBundle.path )#"
				data-spec-id="#encodeForHtml( local.s.id )#"
				data-name="#encodeForHtml( local.s.displayName )#"
				data-crumb="#encodeForHtml( thisEntry.crumb )#"
				data-ms="#local.s.totalDuration#"
				data-run-url="#variables.helper.href( variables.helper.runURL( bundle = thisBundle.path, spec = local.s.id ) )#"
				data-search="#encodeForHtml( lCase( "#local.s.displayName# #thisEntry.crumb# #thisBundle.path#" ) )#"
				title="#encodeForHtml( local.s.displayName )# (#local.s.totalDuration# ms)"
				aria-label="#encodeForHtml( local.s.displayName )#, #local.st.label#"
			></button></cfloop></div>

			<cfif structKeyExists( thisBundle, "debugBuffer" ) && arrayLen( thisBundle.debugBuffer )>
				#renderPartial( "debug", { bundle : thisBundle } )#
			</cfif>
		</section>
	</cfloop>
	<p id="tb-no-matches" class="tb-empty" hidden>No bundles match the current filters.</p>
</section>

<!--- payloads for Ask AI live at the top level, the drawer panels are cloned from the templates below --->
<cfif variables.helper.getOptions().aiAssist>
	<cfloop array="#variables.failureList#" item="thisFailure">
		#renderPartial( "ask-payloads", { failure : thisFailure } )#
	</cfloop>
</cfif>
<cfloop array="#variables.failureList#" item="thisFailure">
	<template data-panel="#encodeForHtml( thisFailure.spec.id )#">#renderPartial( "failure", { failure : thisFailure, payloads : false } )#</template>
</cfloop>

<div class="offcanvas-backdrop show" x-show="drawer" x-cloak @click="closeSpec()"></div>
<aside
	class="offcanvas offcanvas-end tb-drawer"
	:class="{ show: drawer }"
	tabindex="-1"
	role="dialog"
	aria-labelledby="tb-drawer-title"
	:aria-hidden="!drawer"
>
	<div class="offcanvas-header align-items-start gap-3">
		<div class="min-w-0">
			<span class="tb-badge mb-1" :data-status="drawer ? drawer.status : ''">
				<span x-text="drawer ? drawer.status : ''"></span>
			</span>
			<h2 id="tb-drawer-title" class="offcanvas-title h5 text-break" x-text="drawer ? drawer.name : ''"></h2>
			<div class="tb-crumb" x-text="drawer ? drawer.bundle + ' > ' + drawer.crumb : ''"></div>
		</div>
		<button type="button" class="btn-close" aria-label="Close" @click="closeSpec()"></button>
	</div>
	<div class="offcanvas-body">
		<div class="d-flex flex-wrap align-items-center gap-3 mb-3" x-show="drawer" x-cloak>
			<span class="tb-num text-body-secondary" x-text="drawer ? drawer.ms + ' ms' : ''"></span>
			<a class="btn btn-sm btn-primary" :href="drawer ? drawer.runUrl : '##'">
				<svg class="tb-icon" aria-hidden="true"><use href="##i-play-fill"/></svg> Run this spec
			</a>
		</div>
		<div id="tb-drawer-body"></div>
	</div>
</aside>
</cfoutput>
</cfsavecontent>
<cfoutput>#renderPartial( "page", { content : local.content } )#</cfoutput>
