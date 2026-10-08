<!--- The preview of the prompt, toggled by previewOpen in the parent scope. Input: arguments.data.id --->
<cfset local.id = variables.helper.safeId( arguments.data.id )>
<cfoutput>
<div class="mt-3" x-show="previewOpen" x-cloak>
	<div class="d-flex align-items-center gap-2 mb-1">
		<strong class="small">Prompt preview</strong>
		<button type="button" class="btn btn-sm btn-outline-secondary ms-auto" @click="aiCopy( '#local.id#' )">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-clipboard"/></svg> Copy
		</button>
	</div>
	<pre class="tb-pre" x-text="aiPreview( '#local.id#' )"></pre>
</div>
</cfoutput>
