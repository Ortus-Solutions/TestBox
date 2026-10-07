<!--- One failed or errored spec: what happened, where, and what to do next. Input: arguments.data.failure --->
<cfset local.failure = arguments.data.failure>
<cfset local.spec    = local.failure.spec>
<cfset local.status  = variables.helper.status( local.spec.status )>
<cfset local.code    = variables.helper.codeFor( local.spec, 3 )>
<cfset local.origin  = variables.helper.origin( local.spec )>
<cfset local.aiOn    = variables.helper.getOptions().aiAssist>
<cfoutput>
<article
	class="card tb-failure"
	id="failure-#encodeForHtml( local.spec.id )#"
	data-status="#local.status.key#"
>
	<header class="card-header tb-failure__header d-flex flex-wrap align-items-center gap-2">
		<span class="tb-badge">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-#local.status.icon#"/></svg> #local.status.label#
		</span>
		<span class="tb-crumb">#encodeForHtml( local.failure.bundle.path )# &gt; #encodeForHtml( local.failure.crumb )#</span>
		<h3 class="tb-failure__title">#encodeForHtml( local.spec.displayName )#</h3>
	</header>

	<div class="card-body" x-data="{ detailOpen: false, tab: 'origin', previewOpen: false }">
		<p class="tb-failure__message">#encodeForHtml( local.failure.message )#</p>

		<cfif !structIsEmpty( local.code ) && arrayLen( local.code.lines )>
			<!--- no whitespace between the line spans: each one is a block of its own --->
			<pre class="tb-code" data-lang="#local.code.lang#"><cfloop array="#local.code.lines#" item="thisLine"><span class="tb-code__line#( thisLine.hit ? " tb-code__line--hit" : "" )#" data-n="#thisLine.n#">#encodeForHtml( thisLine.text )#</span></cfloop></pre>
		</cfif>

		<div class="d-flex flex-wrap align-items-center gap-2 mt-3">
			<a
				class="btn btn-sm btn-outline-secondary"
				href="#variables.helper.href( variables.helper.runURL( bundle = local.failure.bundle.path, spec = local.spec.id ) )#"
				title="Run only this spec"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-play-fill"/></svg> Run this spec
			</a>
			<cfif !structIsEmpty( local.origin )>
				<a
					class="btn btn-sm btn-outline-secondary"
					href="#encodeForHtml( variables.helper.editorURL( local.origin.template, local.origin.line ) )#"
					title="Open in your editor"
				>
					<svg class="tb-icon" aria-hidden="true"><use href="##i-box-arrow-up-right"/></svg>
					Open in editor <span class="tb-mono">#encodeForHtml( listLast( local.origin.relative, "/" ) )#:#local.origin.line#</span>
				</a>
			</cfif>
			<cfif local.aiOn>
				#renderPartial( "ask-ai", { id : local.spec.id } )#
			</cfif>
			<button
				type="button"
				class="btn btn-sm btn-outline-secondary ms-auto"
				@click="detailOpen = !detailOpen"
				:aria-expanded="detailOpen"
				aria-controls="failure-details-#encodeForHtml( local.spec.id )#"
			>
				<svg class="tb-icon tb-chevron" :class="{ 'tb-chevron--open': detailOpen }" aria-hidden="true"><use href="##i-chevron-right"/></svg> Details
			</button>
		</div>

		<cfif local.aiOn>
			<cfif arguments.data.payloads ?: true>
				#renderPartial( "ask-payloads", { failure : local.failure } )#
			</cfif>
			#renderPartial( "ai-preview", { id : local.spec.id } )#
		</cfif>

		<div class="mt-3" id="failure-details-#encodeForHtml( local.spec.id )#" x-show="detailOpen" x-cloak>
			<ul class="nav nav-underline mb-3" role="tablist">
				<li class="nav-item" role="presentation">
					<button type="button" class="nav-link" :class="{ active: tab === 'origin' }" role="tab" :aria-selected="tab === 'origin'" @click="tab = 'origin'">Failure origin</button>
				</li>
				<li class="nav-item" role="presentation">
					<button type="button" class="nav-link" :class="{ active: tab === 'stack' }" role="tab" :aria-selected="tab === 'stack'" @click="tab = 'stack'">Stack trace</button>
				</li>
				<li class="nav-item" role="presentation">
					<button type="button" class="nav-link" :class="{ active: tab === 'detail' }" role="tab" :aria-selected="tab === 'detail'" @click="tab = 'detail'">Detail</button>
				</li>
			</ul>

			<div x-show="tab === 'origin'" role="tabpanel">
				<ul class="tb-frames">
					<cfloop array="#variables.helper.frames( local.spec )#" item="thisFrame">
						<li class="#( thisFrame.user ? "tb-frame--user" : "" )#">
							<a href="#encodeForHtml( variables.helper.editorURL( thisFrame.template, thisFrame.line ) )#" title="Open in your editor">#encodeForHtml( thisFrame.relative )#:#thisFrame.line#</a>
							<span class="text-body-secondary">#encodeForHtml( thisFrame.label )#</span>
						</li>
					</cfloop>
				</ul>
			</div>

			<div x-show="tab === 'stack'" x-cloak role="tabpanel">
				<cfset local.stack = ( len( local.spec.failStacktrace ) ? local.spec.failStacktrace : ( local.spec.error.stackTrace ?: "" ) )>
				<pre class="tb-pre">#encodeForHtml( local.stack )#</pre>
			</div>

			<div x-show="tab === 'detail'" x-cloak role="tabpanel" class="d-grid gap-3">
				<cfif len( local.spec.failDetail )>
					<div><h4 class="h6">Failure detail</h4><div class="tb-dump"><cfdump var="#local.spec.failDetail#" output="browser" format="html"></div></div>
				</cfif>
				<cfif len( local.spec.failExtendedInfo )>
					<div><h4 class="h6">Extended info</h4><div class="tb-dump"><cfdump var="#local.spec.failExtendedInfo#" output="browser" format="html"></div></div>
				</cfif>
				<cfif !structIsEmpty( local.spec.error )>
					<div><h4 class="h6">Exception</h4><div class="tb-dump"><cfdump var="#local.spec.error#" expand="false" output="browser" format="html"></div></div>
				</cfif>
				<cfif !len( local.spec.failDetail ) && !len( local.spec.failExtendedInfo ) && structIsEmpty( local.spec.error )>
					<p class="text-body-secondary mb-0">This spec reported no extra detail.</p>
				</cfif>
			</div>
		</div>
	</div>
</article>
</cfoutput>
