<!--- The server renders the Ask AI payloads, the page only copies or opens them. Input: arguments.data.failure --->
<cfset local.failure = arguments.data.failure>
<cfoutput>
<template data-prompt="#encodeForHtml( local.failure.spec.id )#">#encodeForHtml( variables.helper.prompt( local.failure, variables.results, variables.testbox ) )#</template>
<template data-agent="#encodeForHtml( local.failure.spec.id )#">#encodeForHtml( variables.helper.agentJSON( local.failure ) )#</template>
</cfoutput>
