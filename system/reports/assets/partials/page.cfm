<!---
	The shell every HTML reporter shares: head, header, verdict, coverage and scripts around the reporter's own content.
	Input: arguments.data.content (the markup of the reporter)
--->
<cfoutput>
<!DOCTYPE html>
<html lang="en" data-bs-theme="light">
	<head>
		#renderPartial( "head" )#
	</head>
	<body>
		#variables.helper.asset( "vendor/icons.svg" )#

		<div
			class="tb-report container-xl"
			x-data="tbReport"
			x-effect="applyFilters()"
			@keydown.window="onKey( $event )"
		>
			#renderPartial( "header" )#

			<main>
				#renderPartial( "verdict" )#

				<cfif variables.results.getCoverageEnabled()>
					#renderPartial( "coverage" )#
				</cfif>

				#arguments.data.content#
			</main>

			<div class="tb-toast" x-show="toast" x-cloak role="status" aria-live="polite">
				<span x-html="toast"></span>
			</div>
		</div>

		#renderPartial( "scripts" )#
	</body>
</html>
</cfoutput>
