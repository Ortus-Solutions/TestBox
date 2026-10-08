<!--- The debug() stream of a bundle. Input: arguments.data.bundle --->
<cfset local.bundle = arguments.data.bundle>
<cfoutput>
<div class="p-3 border-top" x-data="{ debugOpen: false }">
	<button type="button" class="btn btn-sm btn-outline-secondary" @click="debugOpen = !debugOpen" :aria-expanded="debugOpen">
		<svg class="tb-icon" aria-hidden="true"><use href="##i-bug"/></svg> Debug stream (#arrayLen( local.bundle.debugBuffer )#)
	</button>
	<div class="mt-3" x-show="debugOpen" x-cloak>
		<p class="small text-body-secondary">The following data was collected in order as your tests ran via the <em>debug()</em> method:</p>
		<cfloop array="#local.bundle.debugBuffer#" item="thisDebug">
			<cfif !isNull( thisDebug )>
				<h4 class="h6">#encodeForHtml( thisDebug.label )#</h4>
				<div class="tb-dump mb-3">
					<cfdump
						var      = "#thisDebug.data#"
						label    = "#thisDebug.label# - #dateFormat( thisDebug.timestamp, "short" )# at #timeFormat( thisDebug.timestamp, "full" )#"
						top      = "#thisDebug.top#"
						showUDFs = "#thisDebug.showUDFs#"
						output   = "browser"
						format   = "html"
					>
				</div>
			</cfif>
		</cfloop>
	</div>
</div>
</cfoutput>
