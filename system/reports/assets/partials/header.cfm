<cfoutput>
<header class="tb-header d-flex flex-wrap align-items-center gap-2 gap-md-3 mb-3">
	<a
		class="d-inline-flex align-items-center"
		href="https://testbox.ortusbooks.com"
		target="_blank"
		rel="noopener"
		title="TestBox documentation"
	>
		<img class="tb-logo tb-logo--light" src="#variables.helper.dataURI( "images/testbox-logo-light.svg" )#" alt="TestBox">
		<img class="tb-logo tb-logo--dark" src="#variables.helper.dataURI( "images/testbox-logo-dark.svg" )#" alt="" aria-hidden="true">
	</a>
	<span class="badge text-bg-primary">v#encodeForHtml( variables.testbox.getVersion() )#</span>
	<span class="badge text-bg-secondary">#encodeForHtml( variables.results.getCFMLEngine() )# #encodeForHtml( variables.results.getCFMLEngineVersion() )#</span>

	<div class="ms-auto d-flex flex-wrap align-items-center gap-2">
		<div class="btn-group btn-group-sm tb-theme" role="group" aria-label="Color theme">
			<button
				type="button"
				class="btn btn-outline-secondary"
				:aria-pressed="theme === 'system'"
				@click="setTheme( 'system' )"
				title="Follow the system theme"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-circle-half"/></svg>
				<span class="visually-hidden">System theme</span>
			</button>
			<button
				type="button"
				class="btn btn-outline-secondary"
				:aria-pressed="theme === 'light'"
				@click="setTheme( 'light' )"
				title="Light theme"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-sun-fill"/></svg>
				<span class="visually-hidden">Light theme</span>
			</button>
			<button
				type="button"
				class="btn btn-outline-secondary"
				:aria-pressed="theme === 'dark'"
				@click="setTheme( 'dark' )"
				title="Dark theme"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-moon-stars-fill"/></svg>
				<span class="visually-hidden">Dark theme</span>
			</button>
		</div>

		<a class="btn btn-primary btn-sm" href="#variables.helper.href( variables.helper.runURL() )#" title="Run all tests">
			<svg class="tb-icon" aria-hidden="true"><use href="##i-play-fill"/></svg> Run All
		</a>
		<cfset local.failedTargets = variables.results.getFailedTargets()>
		<cfif arrayLen( local.failedTargets.bundles )>
			<a
				class="btn btn-danger btn-sm"
				href="#variables.helper.href( variables.helper.failedRunURL( local.failedTargets ) )#"
				title="Run only the specs that failed or errored in this run"
			>
				<svg class="tb-icon" aria-hidden="true"><use href="##i-arrow-repeat"/></svg> Run Failed (#arrayLen( local.failedTargets.specs )#)
			</a>
		</cfif>
	</div>
</header>
</cfoutput>
