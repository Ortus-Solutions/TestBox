<cfparam name="variables.testbox" default="">
<cfparam name="variables.smokeResult" default="#structNew()#">
<cfparam name="variables.runnerErrors" default="#[]#">
<cfparam name="variables.ran" default="false">
<cfparam name="variables.manifestPath" default="">
<cfparam name="variables.invokeEnabled" default="false">
<cfparam name="variables.smokeRunnerSummary" default="#structNew()#">
<cfparam name="variables.smokeEmbedCompact" default="false">
<cfparam name="variables.fullPage" default="true">
<cfparam name="variables.ASSETS_DIR" default="#expandPath( '/testbox/system/reports/assets' )#">

<cfscript>
	variables.smokeEmbedTooltip = "Smoke Test: Uses component metadata to list public and remote functions. Not line coverage and not a substitute for real tests.";
	variables.smokeFullTooltip = "Smoke Test: Loads components from a manifest, a directory scan, or a single CFC path, then does the same metadata pass. Use synthetic arguments; errors are ignored. Not line coverage.";
	variables.smokeDummySuffix = " Adds metadataSmokeInvoke=true (dummy invokes).";
	variables.smokeRunTestsTooltip = "Run the normal HTML test suite with the same URL parameters (without Smoke Test mode).";
</cfscript>

<cfoutput>
	<cfif variables.smokeEmbedCompact && !variables.fullPage>
			<div class="text-nowrap">
					<cfif structKeyExists( smokeRunnerSummary, "smokeRunUrl" ) && len( smokeRunnerSummary.smokeRunUrl )>
						<a class="btn btn-sm btn-primary mr-1" href="#htmlEditFormat( smokeRunnerSummary.smokeRunUrl )#" title="#encodeForHtml( variables.smokeEmbedTooltip )#"><i class="fas fa-search"></i> Run Smoke Test</a>
					</cfif>
					<cfif
						structKeyExists( smokeRunnerSummary, "smokeRunUrl" )
						&& len( smokeRunnerSummary.smokeRunUrl )
						&& structKeyExists( smokeRunnerSummary, "smokeRunUrlWithInvoke" )
						&& len( smokeRunnerSummary.smokeRunUrlWithInvoke )
						&& smokeRunnerSummary.smokeRunUrlWithInvoke NEQ smokeRunnerSummary.smokeRunUrl
					>
						<a class="btn btn-sm btn-outline-primary mr-1" href="#htmlEditFormat( smokeRunnerSummary.smokeRunUrlWithInvoke )#" title="#encodeForHtml( variables.smokeEmbedTooltip & variables.smokeDummySuffix )#"><i class="fas fa-bolt"></i> Smoke Test with Dummy Invoke</a>
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
				<script>#fileRead( "#ASSETS_DIR#/js/fontawesome.js" )#</script>
			</head>
			<body>
				<div class="container-fluid my-3">
					<div class="d-flex justify-content-between align-items-center mb-3 flex-wrap">
						<div class="mb-2 mb-md-0">
							<img src="data:image/png;base64, #toBase64( fileReadBinary( '#ASSETS_DIR#/images/TestBoxLogo125.png' ) )#" height="75" alt="TestBox">
						</div>
						<div class="text-nowrap">
							<cfif structKeyExists( smokeRunnerSummary, "smokeRunUrl" ) && len( smokeRunnerSummary.smokeRunUrl )>
								<a class="btn btn-sm btn-primary mr-1" href="#htmlEditFormat( smokeRunnerSummary.smokeRunUrl )#" title="#encodeForHtml( variables.smokeFullTooltip )#"><i class="fas fa-redo"></i> Re-run Smoke Test</a>
							</cfif>
							<cfif
								structKeyExists( smokeRunnerSummary, "smokeRunUrl" )
								&& len( smokeRunnerSummary.smokeRunUrl )
								&& structKeyExists( smokeRunnerSummary, "smokeRunUrlWithInvoke" )
								&& len( smokeRunnerSummary.smokeRunUrlWithInvoke )
								&& smokeRunnerSummary.smokeRunUrlWithInvoke NEQ smokeRunnerSummary.smokeRunUrl
							>
								<a class="btn btn-sm btn-outline-primary mr-1" href="#htmlEditFormat( smokeRunnerSummary.smokeRunUrlWithInvoke )#" title="#encodeForHtml( variables.smokeFullTooltip & variables.smokeDummySuffix )#"><i class="fas fa-bolt"></i> Re-run with Dummy Invoke</a>
							</cfif>
							<cfif structKeyExists( smokeRunnerSummary, "testsUrl" ) && len( smokeRunnerSummary.testsUrl )>
								<a class="btn btn-sm btn-outline-primary" href="#htmlEditFormat( smokeRunnerSummary.testsUrl )#" title="#encodeForHtml( variables.smokeRunTestsTooltip )#"><i class="fas fa-vial"></i> Run tests (same URL)</a>
							</cfif>
						</div>
					</div>

					<cfif arrayLen( runnerErrors )>
						<div class="alert alert-danger">
							<h5 class="alert-heading">Cannot run Smoke Test</h5>
							<ul class="mb-0">
								<cfloop array="#runnerErrors#" index="local.err">
									<li>#htmlEditFormat( toString( local.err ) )#</li>
								</cfloop>
							</ul>
						</div>
					</cfif>

					<div class="card mb-3">
						<div class="card-header">Request</div>
						<div class="card-body">
							<dl class="row mb-0 small">
								<dt class="col-sm-3">Manifest / source</dt>
								<dd class="col-sm-9"><code>#htmlEditFormat( manifestPath )#</code></dd>
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
										<dd class="col-sm-9 text-danger">#htmlEditFormat( toString( smokeResult.errorMessage ) )#</dd>
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
											<li><code>#htmlEditFormat( toString( local.sc ) )#</code></li>
										</cfloop>
									</ul>
								</cfif>
							</div>
						</div>
					</cfif>
				</div>
			</body>
		</html>
	</cfif>
</cfoutput>
