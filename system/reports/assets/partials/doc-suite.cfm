<!---
	A suite of the Doc reporter, with its specs and nested suites.
	Inputs: arguments.data.suite, arguments.data.bundle, arguments.data.level (the heading level, 3 and up)
--->
<cfset local.suite   = arguments.data.suite>
<cfset local.bundle  = arguments.data.bundle>
<cfset local.level   = min( arguments.data.level, 6 )>
<cfset local.titleId = "suite-#variables.helper.safeId( local.suite.id )#">
<cfset local.aiOn    = variables.helper.getOptions().aiAssist>
<cfoutput>
<section class="tb-doc-suite tb-suite" aria-labelledby="#local.titleId#">
	<h#local.level# id="#local.titleId#">
		<a class="text-reset text-decoration-none" href="#variables.helper.href( variables.helper.runURL( bundle = local.bundle.path, suite = local.suite.name ) )#" title="Run only this suite">#encodeForHtml( local.suite.name )#</a>
		<small class="tb-num fw-normal">#encodeForHtml( variables.helper.duration( local.suite.totalDuration ) )#</small>
	</h#local.level#>

	<dl>
		<cfloop array="#local.suite.specStats#" item="thisSpec">
			<cfset local.status  = variables.helper.status( thisSpec.status )>
			<cfset local.problem = variables.helper.isProblem( thisSpec )>
			<div
				class="tb-doc-spec"
				id="doc-spec-#variables.helper.safeId( thisSpec.id )#"
				data-spec
				data-status="#local.status.key#"
				data-bundle="#variables.helper.safeId( local.bundle.id )#"
				data-search="#encodeForHtml( lCase( "#thisSpec.displayName# #local.suite.name# #local.bundle.path#" ) )#"
			>
				<dt>
					<svg class="tb-icon tb-st-icon" aria-hidden="true"><use href="##i-#local.status.icon#"/></svg>
					<span>#encodeForHtml( thisSpec.displayName )#</span>
					<span class="small fw-normal text-body-secondary tb-num">#encodeForHtml( variables.helper.duration( thisSpec.totalDuration ) )#</span>
					<span class="visually-hidden">#local.status.label#</span>
				</dt>
				<cfif local.problem>
					<cfset local.failure = { bundle : local.bundle, suites : [ local.suite.name ], crumb : local.suite.name, spec : thisSpec, message : variables.helper.specMessage( thisSpec ) }>
					<cfset local.code    = variables.helper.codeFor( thisSpec, 3 )>
					<dd x-data="{ previewOpen: false }">
						<p class="mb-2 text-break">#encodeForHtml( local.failure.message )#</p>
						#renderPartial( "attachments", { spec : thisSpec } )#
						<div class="d-flex flex-wrap align-items-center gap-2">
							<a class="btn btn-sm btn-outline-secondary" href="#variables.helper.href( variables.helper.runURL( bundle = local.bundle.path, spec = thisSpec.id ) )#">
								<svg class="tb-icon" aria-hidden="true"><use href="##i-play-fill"/></svg> Run this spec
							</a>
							<cfif local.aiOn>
								#renderPartial( "ask-ai", { id : thisSpec.id } )#
							</cfif>
						</div>
						<cfif local.aiOn>
							#renderPartial( "ai-preview", { id : thisSpec.id } )#
						</cfif>
						<details class="mt-2">
							<summary class="small">Origin and stack trace</summary>
							<cfif !structIsEmpty( local.code ) && arrayLen( local.code.lines )>
								<pre class="tb-code mt-2" data-lang="#local.code.lang#"><cfloop array="#local.code.lines#" item="thisLine"><span class="tb-code__line#( thisLine.hit ? " tb-code__line--hit" : "" )#" data-n="#thisLine.n#">#encodeForHtml( thisLine.text )#</span></cfloop></pre>
							</cfif>
							<cfset local.stack = ( len( thisSpec.failStacktrace ) ? thisSpec.failStacktrace : ( thisSpec.error.stackTrace ?: "" ) )>
							<pre class="tb-pre mt-2">#encodeForHtml( local.stack )#</pre>
						</details>
					</dd>
				<cfelseif arrayLen( getSpecAttachments( thisSpec ) )>
					<dd>#renderPartial( "attachments", { spec : thisSpec } )#</dd>
				</cfif>
			</div>
		</cfloop>
	</dl>

	<cfloop array="#local.suite.suiteStats#" item="thisNested">
		#renderPartial( "doc-suite", { suite : thisNested, bundle : local.bundle, level : local.level + 1 } )#
	</cfloop>
</section>
</cfoutput>
