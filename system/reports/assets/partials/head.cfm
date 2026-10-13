<!--- Everything in the head is inline so the report works airgapped. --->
<cfoutput>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="generator" content="TestBox v#encodeForHtml( variables.testbox.getVersion() )#">
<meta name="color-scheme" content="light dark">
<title>#encodeForHtml( variables.verdict.tabTitle )# | TestBox</title>
<link rel="icon" href="#variables.helper.faviconURI( variables.verdict.bad )#">
<script>#variables.helper.asset( "js/theme-init.js" )#</script>
<style>#variables.helper.asset( "vendor/bootstrap.min.css" )#</style>
<style>#variables.helper.asset( "css/testbox.css" )#</style>
</cfoutput>
