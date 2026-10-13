<!--- The global exception of a bundle: it never ran, say so plainly. Input: arguments.data.bundle --->
<cfset local.bundle = arguments.data.bundle>
<cfset local.frames = variables.helper.framesOf( local.bundle.globalException.tagContext ?: [] )>
<cfoutput>
<div class="p-3 border-bottom" data-status="error">
	<h4 class="h6 d-flex align-items-center gap-2" style="color: var(--tb-error-emphasis)">
		<svg class="tb-icon" aria-hidden="true"><use href="##i-exclamation-octagon-fill"/></svg> Global bundle exception
	</h4>
	<p class="mb-2">#encodeForHtml( local.bundle.globalException.message ?: "" )#</p>
	<cfif arrayLen( local.frames )>
		<ul class="tb-frames mb-2">
			<cfloop array="#local.frames#" item="thisFrame">
				<li class="#( thisFrame.user ? "tb-frame--user" : "" )#">
					<a href="#encodeForHtml( variables.helper.editorURL( thisFrame.template, thisFrame.line ) )#">#encodeForHtml( thisFrame.relative )#:#thisFrame.line#</a>
				</li>
			</cfloop>
		</ul>
	</cfif>
	<details>
		<summary class="small">Full exception</summary>
		<div class="tb-dump mt-2"><cfdump var="#local.bundle.globalException#" expand="false" output="browser" format="html"></div>
	</details>
</div>
</cfoutput>
