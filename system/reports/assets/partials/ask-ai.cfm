<!---
	The Ask AI menu of a failure. Input: arguments.data.id (the spec id).
	It only builds links and copies text: nothing leaves the page until you choose an Open action
	and confirm the notice shown the first time.
--->
<cfset local.id = variables.helper.safeId( arguments.data.id )>
<cfoutput>
<div
	class="dropdown tb-ai"
	x-data="{ open: false, pending: null }"
	@click.outside="open = false; pending = null"
	@keydown.escape.window="open = false; pending = null"
>
	<button
		type="button"
		class="btn btn-sm btn-outline-primary"
		@click="open = !open; pending = null"
		:aria-expanded="open"
		aria-haspopup="menu"
	>
		<svg class="tb-icon" aria-hidden="true"><use href="##i-stars"/></svg> Ask AI
		<svg class="tb-icon" aria-hidden="true"><use href="##i-chevron-down"/></svg>
	</button>

	<div class="dropdown-menu" :class="{ show: open }" role="menu">
		<div class="px-3 py-2 small border-bottom mb-1" x-show="pending" x-cloak>
			<p class="mb-2">
				<svg class="tb-icon" aria-hidden="true"><use href="##i-shield-lock"/></svg>
				This opens a third party site with your code snippet and stack trace in the prompt.
				Nothing is sent until the page opens.
			</p>
			<button
				type="button"
				class="btn btn-sm btn-primary"
				@click="aiConfirm(); aiOpen( pending, '#local.id#' ); pending = null; open = false"
			>Continue</button>
			<button type="button" class="btn btn-sm btn-outline-secondary" @click="pending = null">Cancel</button>
		</div>

		<button type="button" class="dropdown-item" role="menuitem" @click="aiCopy( '#local.id#' ); open = false">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-clipboard"/></svg> Copy prompt
			<small class="d-block text-body-secondary">Stays on this page, works offline</small>
		</button>
		<button type="button" class="dropdown-item" role="menuitem" @click="previewOpen = !previewOpen; open = false">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-eye"/></svg> Preview prompt
			<small class="d-block text-body-secondary">See exactly what would be sent</small>
		</button>

		<cfloop array="#variables.helper.getOptions().aiProviders#" item="thisProvider">
			<cfset local.providerId = variables.helper.safeId( thisProvider.id )>
			<div class="dropdown-divider"></div>
			<button
				type="button"
				class="dropdown-item"
				role="menuitem"
				@click="if ( aiOk ) { aiOpen( '#local.providerId#', '#local.id#' ); open = false } else { pending = '#local.providerId#' }"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-box-arrow-up-right"/></svg> Open in #encodeForHtml( thisProvider.name )#
			</button>
		</cfloop>

		<div class="dropdown-divider"></div>
		<button type="button" class="dropdown-item" role="menuitem" @click="aiCopyAgent( '#local.id#' ); open = false">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-braces"/></svg> Copy for a coding agent
			<small class="d-block text-body-secondary">JSON in the AgentReporter format</small>
		</button>
	</div>
</div>
</cfoutput>
