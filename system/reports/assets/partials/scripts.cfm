<!--- Page behavior, all inline. Order matters: config, Prism, our component, then Alpine which starts everything. --->
<cfset local.config = {
	"aiAssist"     : variables.helper.getOptions().aiAssist,
	"providers"    : variables.helper.getOptions().aiAssist ? variables.helper.getOptions().aiProviders : [],
	"maxUrlLength" : 6000,
	"bundles"      : {}
}>
<!--- bundles with trouble start open. When nothing is wrong, small runs start open too and big ones start collapsed. --->
<cfset local.anyProblem = false>
<cfloop array="#variables.bundleStats#" item="thisBundle">
	<cfif variables.helper.bundleHasProblems( thisBundle )>
		<cfset local.anyProblem = true>
	</cfif>
</cfloop>
<cfloop array="#variables.bundleStats#" item="thisBundle">
	<cfif local.anyProblem>
		<cfset local.config.bundles[ thisBundle.id ] = variables.helper.isBundleScoped( thisBundle ) || variables.helper.bundleHasProblems( thisBundle )>
	<cfelse>
		<cfset local.config.bundles[ thisBundle.id ] = variables.helper.isBundleScoped( thisBundle ) || ( arrayLen( variables.bundleStats ) lte 5 )>
	</cfif>
</cfloop>
<cfoutput>
<script type="application/json" id="tb-config">#variables.helper.jsonForHtml( local.config )#</script>
<script>#variables.helper.asset( "vendor/prism.min.js" )#</script>
<script>#variables.helper.asset( "js/testbox.js" )#</script>
<script>#variables.helper.asset( "vendor/alpine.min.js" )#</script>
</cfoutput>
