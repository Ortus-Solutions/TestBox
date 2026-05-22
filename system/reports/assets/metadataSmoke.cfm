<cfparam name="variables.testbox" default="">
<cfparam name="variables.smokeResult" default="#structNew()#">
<cfparam name="variables.runnerErrors" default="#[]#">
<cfparam name="variables.ran" default="false">
<cfparam name="variables.manifestPath" default="">
<cfparam name="variables.invokeEnabled" default="false">
<cfparam name="variables.smokeRunnerSummary" default="#structNew()#">
<cfparam name="variables.smokeEmbedCompact" default="false">
<cfparam name="variables.fullPage" default="true">
<cfparam name="variables.smokeEmbedRerunLabels" default="false">
<cfparam name="variables.ASSETS_DIR" default="#expandPath( '/testbox/system/reports/assets' )#">

<cfscript>
	variables.smokeEmbedTooltip = "Smoke Test: Uses component metadata to list public and remote functions. Not line coverage and not a substitute for real tests.";
	variables.smokeFullTooltip = "Smoke Test: Loads components from a manifest, a directory scan, or a single CFC path, then does the same metadata pass. Use synthetic arguments; errors are ignored. Not line coverage.";
	variables.smokeDummySuffix = " Adds metadataSmokeInvoke=true (dummy invokes).";
	variables.smokeToolbarLastRanWithInvoke = false;
	if ( structKeyExists( url, "metadataSmokeInvoke" ) && listFindNoCase( "true,yes,1", trim( toString( url.metadataSmokeInvoke ) ) ) GT 0 ) {
		variables.smokeToolbarLastRanWithInvoke = true;
	} else {
		for ( uk in structKeyList( url ) ) {
			if ( reReplace( lCase( uk ), "[^a-z]", "", "all" ) == "metadatasmokeinvoke" && listFindNoCase( "true,yes,1", trim( toString( url[ uk ] ) ) ) GT 0 ) {
				variables.smokeToolbarLastRanWithInvoke = true;
				break;
			}
		}
	}
</cfscript>

<cfoutput>
	<cfif variables.smokeEmbedCompact && !variables.fullPage>
			<div class="text-nowrap">
					<cfif structKeyExists( smokeRunnerSummary, "smokeRunUrl" ) && len( smokeRunnerSummary.smokeRunUrl )>
						<cfset variables.smokeToolbarUrlsDiffer = !structKeyExists( smokeRunnerSummary, "smokeRunUrlWithInvoke" ) OR !len( smokeRunnerSummary.smokeRunUrlWithInvoke ) OR smokeRunnerSummary.smokeRunUrlWithInvoke NEQ smokeRunnerSummary.smokeRunUrl>
						<cfif variables.smokeEmbedRerunLabels>
							<cfif variables.smokeToolbarLastRanWithInvoke && !variables.smokeToolbarUrlsDiffer>
								<a class="btn btn-sm btn-primary mr-1" href="#encodeForHTML( smokeRunnerSummary.smokeRunUrl )#" title="#encodeForHtml( variables.smokeFullTooltip & variables.smokeDummySuffix )#"><i class="fas fa-redo"></i> Re-run Smoke Test with Dummy Invoke</a>
							<cfelseif variables.smokeToolbarLastRanWithInvoke>
								<a class="btn btn-sm btn-primary mr-1" href="#encodeForHTML( smokeRunnerSummary.smokeRunUrl )#" title="#encodeForHtml( variables.smokeEmbedTooltip )#"><i class="fas fa-search"></i> Run Smoke Test</a>
							<cfelse>
								<a class="btn btn-sm btn-primary mr-1" href="#encodeForHTML( smokeRunnerSummary.smokeRunUrl )#" title="#encodeForHtml( variables.smokeFullTooltip )#"><i class="fas fa-redo"></i> Re-run Smoke Test</a>
							</cfif>
						<cfelse>
							<a class="btn btn-sm btn-primary mr-1" href="#encodeForHTML( smokeRunnerSummary.smokeRunUrl )#" title="#encodeForHtml( variables.smokeEmbedTooltip )#"><i class="fas fa-search"></i> Run Smoke Test</a>
						</cfif>
					</cfif>
					<cfif
						structKeyExists( smokeRunnerSummary, "smokeRunUrl" )
						&& len( smokeRunnerSummary.smokeRunUrl )
						&& structKeyExists( smokeRunnerSummary, "smokeRunUrlWithInvoke" )
						&& len( smokeRunnerSummary.smokeRunUrlWithInvoke )
						&& smokeRunnerSummary.smokeRunUrlWithInvoke NEQ smokeRunnerSummary.smokeRunUrl
					>
						<cfif variables.smokeEmbedRerunLabels && variables.smokeToolbarLastRanWithInvoke>
							<a class="btn btn-sm btn-outline-primary mr-1" href="#encodeForHTML( smokeRunnerSummary.smokeRunUrlWithInvoke )#" title="#encodeForHtml( variables.smokeFullTooltip & variables.smokeDummySuffix )#"><i class="fas fa-redo"></i> Re-run Smoke Test with Dummy Invoke</a>
						<cfelse>
							<a class="btn btn-sm btn-outline-primary mr-1" href="#encodeForHTML( smokeRunnerSummary.smokeRunUrlWithInvoke )#" title="#encodeForHtml( variables.smokeEmbedTooltip & variables.smokeDummySuffix )#"><i class="fas fa-bolt"></i> Smoke Test with Dummy Invoke</a>
						</cfif>
					</cfif>
			</div>
	<cfelse>
		<!DOCTYPE html>
		<html>
			<head>
				<meta charset="utf-8">
				<meta name="generator" content="TestBox v#testbox.getVersion()#">
				<title>Smoke Test — TestBox</title>
				<style>#fileRead( "#ASSETS_DIR#/css/main.css" )#</style>
				<script>#fileRead( "#ASSETS_DIR#/js/jquery-3.3.1.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/popper.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/bootstrap.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/stupidtable.min.js" )#</script>
				<script>#fileRead( "#ASSETS_DIR#/js/fontawesome.js" )#</script>
			</head>
			<body>
				<div class="container-fluid my-3">
					<cfset variables.runnerToolbarTestsUrl = "">
					<cfif structKeyExists( smokeRunnerSummary, "testsUrl" ) && len( trim( toString( smokeRunnerSummary.testsUrl ) ) )>
						<cfset variables.runnerToolbarTestsUrl = trim( toString( smokeRunnerSummary.testsUrl ) )>
					</cfif>
					<cfinclude template="runnerToolbarHeader.cfm">

					<div class="d-flex flex-wrap justify-content-end align-items-center mt-3 mb-3">
						#testbox.getGapAnalysisService().renderRunnerEmbed( testbox, false )#
						#testbox.getMetadataSmokeService().renderRunnerEmbed( testbox, false, true )#
					</div>

					<cfif arrayLen( runnerErrors )>
						<div class="alert alert-danger">
							<h5 class="alert-heading">Cannot run Smoke Test</h5>
							<ul class="mb-0">
								<cfloop array="#runnerErrors#" index="local.err">
									<li>#encodeForHTML( toString( local.err ) )#</li>
								</cfloop>
							</ul>
						</div>
					</cfif>

					<div class="card mb-3">
						<div class="card-header">Request</div>
						<div class="card-body">
							<dl class="row mb-0 small">
								<dt class="col-sm-3">Manifest / source</dt>
								<dd class="col-sm-9"><code>#encodeForHTML( manifestPath )#</code></dd>
								<dt class="col-sm-3">Dummy invoke</dt>
								<dd class="col-sm-9">#invokeEnabled ? "yes" : "no"#</dd>
							</dl>
						</div>
					</div>

					<cfif ran>
						<div class="card">
							<div class="card-header">Result</div>
							<div class="card-body">
								<dl class="row mb-0">
									<dt class="col-sm-3">success</dt>
									<dd class="col-sm-9">#structKeyExists( smokeResult, "success" ) && smokeResult.success ? "true" : "false"#</dd>
									<cfif structKeyExists( smokeResult, "errorMessage" ) && len( toString( smokeResult.errorMessage ) )>
										<dt class="col-sm-3">errorMessage</dt>
										<dd class="col-sm-9 text-danger">#encodeForHTML( toString( smokeResult.errorMessage ) )#</dd>
									</cfif>
									<dt class="col-sm-3">componentCount</dt>
									<dd class="col-sm-9">#structKeyExists( smokeResult, "componentCount" ) ? val( smokeResult.componentCount ) : 0#</dd>
									<dt class="col-sm-3">discovered</dt>
									<dd class="col-sm-9">#structKeyExists( smokeResult, "discovered" ) ? val( smokeResult.discovered ) : 0#</dd>
									<dt class="col-sm-3">attempted</dt>
									<dd class="col-sm-9">#structKeyExists( smokeResult, "attempted" ) ? val( smokeResult.attempted ) : 0#</dd>
								</dl>
								<cfif structKeyExists( smokeResult, "skippedComponents" ) && isArray( smokeResult.skippedComponents ) && arrayLen( smokeResult.skippedComponents )>
									<h6 class="mt-3">Skipped components (metadata unreadable)</h6>
									<ul>
										<cfloop array="#smokeResult.skippedComponents#" index="local.sc">
											<li><code>#encodeForHTML( toString( local.sc ) )#</code></li>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</div>
					</cfif>
				</div>
			<script>
			$( document ).ready( function() {
				<cfinclude template="runnerToolbarBundleScripts.cfm">
			} );
			</script>
			</body>
		</html>
	</cfif>
</cfoutput>
