<cfsetting showDebugOutput="false">
<!--- Executes all tests in the 'specs' folder with simple reporter by default --->
<cfparam name="url.reporter" default="simple">
<cfparam name="url.directory" default="tests.specs">
<cfparam name="url.recurse" default="false" type="boolean">
<cfparam name="url.bundles" default="">
<cfparam name="url.labels" default="">
<cfparam name="url.excludes" default="">
<cfparam name="url.reportpath" default="#expandPath( "/tests/results" )#">
<cfparam name="url.propertiesFilename" default="TEST.properties">
<cfparam name="url.propertiesSummary" default="false" type="boolean">
<cfparam name="url.editor" 				default="vscode">
<cfparam name="url.bundlesPattern" 		default="*Spec*.cfc|*Test*.cfc|*Spec*.bx|*Test*.bx">

<cfparam name="url.coverageEnabled" default="false">
<cfparam name="url.coverageSonarQubeXMLOutputPath" default="">
<cfparam name="url.coveragePathToCapture" default="#expandPath( '/testbox/system' )#">
<cfparam name="url.coverageWhitelist" default="">
<cfparam name="url.coverageBlacklist" default="/stubs/**">
<cfparam name="url.coverageBrowserOutputDir" default="#expandPath( '/tests/results/coverageReport' )#">
<cfparam name="url.isBatched" default="false">
<cfparam name="url.gapAnalysis" default="false">

<cfparam name="url.metadataSmoke" default="false">
<cfparam name="url.metadataSmokeManifest" default="">
<cfparam name="url.metadataSmokeComponent" default="">
<cfparam name="url.metadataSmokeDirectoryRoot" default="">
<cfparam name="url.metadataSmokeDirectoryPrefix" default="">
<cfparam name="url.metadataSmokeExcludeFileNames" default="">
<cfparam name="url.metadataSmokeExcludePathPrefixes" default="">
<cfparam name="url.metadataSmokeExcludeComponentIds" default="">
<cfparam name="url.metadataSmokeInvoke" default="false">
<cfparam name="url.metadataSmokeFormat" default="">

<cfparam name="url.opt_run" default="false">
<cfscript>
	// create reporters
	reporters = [ "ANTJunit", "Console", "Codexwiki", "Doc", "Dot", "JSON", "JUnit", "Min", "Raw", "Simple", "Tap", "Text", "XML" ];
	ASSETS_DIR = expandPath( "/testbox/system/reports/assets" );

	if( url.opt_run ){
		// Include the TestBox HTML Runner
		include "/testbox/system/runners/HTMLRunner.cfm";
		abort;
	}
</cfscript>

<!DOCTYPE html>
<html>

	<head>
		<meta charset="utf-8">
		<meta name="generator" content="TestBox v#testbox.getVersion()#">
		<title>TestBox Runner</title>

		<cfoutput>
			<style>#fileRead( '#ASSETS_DIR#/css/main.css' )#</style>
			<script>#fileRead( '#ASSETS_DIR#/js/jquery-3.3.1.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/popper.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/bootstrap.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/stupidtable.min.js' )#</script>
		</cfoutput>

		<script>
		$(document).ready(function() {
			toggleInputsLinkedCheckbox('propertiesSummary', 'propertiesInputs');
			toggleInputsLinkedCheckbox('coverageEnabled', 'coverageInputs');
		});

		function toggleInputsLinkedCheckbox(checkboxId, inputsDivId) {
			$(`#${checkboxId}`).on('change', function(){
				if($(this).prop("checked")) {
					$(`#${inputsDivId}`).find( "input" ).prop('disabled', false);
					$(`#${inputsDivId}`).show();
				} else {
					$(`#${inputsDivId}`).hide();
					$(`#${inputsDivId}`).find( "input" ).prop('disabled', true);
				}
			}).trigger('change');
		}

		function runTests() {
			console.log($("#runnerForm").serialize());

			$("#tb-results")
				.html("");

			$("#btn-run")
				.attr("disabled", "disabled")
				.html('Running...')
				.css("opacity", "0.5");

			$("#tb-results")
				.load("index.cfm", $("#runnerForm").serialize(), function(data) {
					$("#btn-run").removeAttr("disabled").html('Run').css("opacity", "1");
				});
		}

		function clearResults() {
			$("#tb-results").html('');
			$("#target").html('');
			$("#labels").html('');
		}
		</script>
	</head>
	<cfoutput>

		<body>
			<!--- Title --->
			<div id="tb-runner" class="container">
				<div class="row">
					<div class="col-md-4 text-center mx-auto">
						<img class="mt-3" src="https://www.ortussolutions.com/__media/testbox-185.png" alt="TestBox" id="tb-logo" />
					</div>
				</div>
				<div class="row">
					<div class="col-md-12">
						<form name="runnerForm" id="runnerForm">
							<input type="hidden" name="opt_run" id="opt_run" value="true" />
							<input type="hidden" name="fullPage" id="fullPage" value="false" />

							<h2>TestBox Global Runner</h2>
							<p>Please use the form below to run test bundle(s), directories and more.</p>
							<p class="small">Gap analysis compares public/remote function names to test/spec file text (heuristic, not line coverage). Uses <code>directory</code> and <code>coveragePathToCapture</code>.</p>
							<div class="form-group form-check">
								<input class="form-check-input" title="Heuristic gap analysis report instead of running tests" name="gapAnalysis" id="gapAnalysis" type="checkbox" value="true" <cfif url.gapAnalysis>checked="true"</cfif> />
								<label class="form-check-label" for="gapAnalysis"> Gap analysis (HTML report)</label>
							</div>
							<p class="small">Smoke Test lists public/remote functions from metadata and can optionally dummy-invoke them (failures ignored). Not line coverage. Use a manifest, <code>directory root + prefix</code>, or a single component—see TestBox readme.</p>
							<div class="form-group form-check">
								<input class="form-check-input" title="Smoke Test report instead of running tests" name="metadataSmoke" id="metadataSmoke" type="checkbox" value="true" <cfif url.metadataSmoke>checked="true"</cfif> />
								<label class="form-check-label" for="metadataSmoke"> Smoke Test (HTML or JSON)</label>
							</div>
							<div class="form-group">
								<label for="metadataSmokeManifest">Smoke Test — manifest (web path)</label>
								<input class="form-control" type="text" name="metadataSmokeManifest" id="metadataSmokeManifest" value="#htmlEditFormat( url.metadataSmokeManifest )#" placeholder="/tests/specs/manifest.json" />
							</div>
							<div class="form-group">
								<label for="metadataSmokeComponent">Smoke Test — single component</label>
								<input class="form-control" type="text" name="metadataSmokeComponent" id="metadataSmokeComponent" value="#htmlEditFormat( url.metadataSmokeComponent )#" placeholder="com.myapp.Foo" />
							</div>
							<div class="form-group">
								<label for="metadataSmokeDirectoryRoot">Smoke Test — directory root (mapping path)</label>
								<input class="form-control" type="text" name="metadataSmokeDirectoryRoot" id="metadataSmokeDirectoryRoot" value="#htmlEditFormat( url.metadataSmokeDirectoryRoot )#" placeholder="/com/myapp" />
							</div>
							<div class="form-group">
								<label for="metadataSmokeDirectoryPrefix">Smoke Test — dotted prefix</label>
								<input class="form-control" type="text" name="metadataSmokeDirectoryPrefix" id="metadataSmokeDirectoryPrefix" value="#htmlEditFormat( url.metadataSmokeDirectoryPrefix )#" placeholder="com.myapp" />
							</div>
							<div class="form-group">
								<label for="metadataSmokeExcludeFileNames">Exclude file names (comma list)</label>
								<input class="form-control" type="text" name="metadataSmokeExcludeFileNames" id="metadataSmokeExcludeFileNames" value="#htmlEditFormat( url.metadataSmokeExcludeFileNames )#" />
							</div>
							<div class="form-group">
								<label for="metadataSmokeExcludePathPrefixes">Exclude path prefixes (comma list)</label>
								<input class="form-control" type="text" name="metadataSmokeExcludePathPrefixes" id="metadataSmokeExcludePathPrefixes" value="#htmlEditFormat( url.metadataSmokeExcludePathPrefixes )#" />
							</div>
							<div class="form-group">
								<label for="metadataSmokeExcludeComponentIds">Exclude component IDs (comma list)</label>
								<input class="form-control" type="text" name="metadataSmokeExcludeComponentIds" id="metadataSmokeExcludeComponentIds" value="#htmlEditFormat( url.metadataSmokeExcludeComponentIds )#" />
							</div>
							<div class="form-group form-check">
								<input class="form-check-input" name="metadataSmokeInvoke" id="metadataSmokeInvoke" type="checkbox" value="true" <cfif url.metadataSmokeInvoke>checked="true"</cfif> />
								<label class="form-check-label" for="metadataSmokeInvoke"> Smoke Test — dummy invoke</label>
							</div>
							<div class="form-group">
								<label for="metadataSmokeFormat">Smoke Test output format</label>
								<input class="form-control" type="text" name="metadataSmokeFormat" id="metadataSmokeFormat" value="#htmlEditFormat( url.metadataSmokeFormat )#" placeholder="json or leave empty for HTML" />
							</div>
							<div class="form-group">
								<label for="reporter">Reporter</label>
								<select name="reporter" id="reporter" class="custom-select">
									<cfloop array="#reporters#" index="thisReporter">
										<option <cfif url.reporter eq thisReporter>selected="selected"</cfif> value="#thisReporter#">#thisReporter# Reporter</option>
									</cfloop>
								</select>
							</div>
							<div class="form-group">
								<label for="directory">Directory Mapping</label>
								<input class="form-control" type="text" name="directory" id="directory" value="#trim( url.directory )#" placeholder="Directory" />
							</div>
							<div class="form-group form-check">
								<input class="form-check-input" title="Enable directory recursion for directory runner" name="recurse" id="recurse" type="checkbox" value="true" <cfif url.recurse>checked="true"</cfif> />
								<label class="form-check-label" for="recurse"> Recurse Directories</label>
							</div>
							<div class="form-group">
								<label for="bundles">Bundle(s)</label>
								<input class="form-control" title="List of bundles to run" type="text" name="bundles" id="bundles" value="#url.bundles#" placeholder="Bundle(s)" />
							</div>
							<div class="form-group">
								<label for="labels">Label(s)</label>
								<input class="form-control" title="List of labels to apply to tests" type="text" name="labels" id="labels" value="#url.labels#" placeholder="Label(s)" />
							</div>
							<div class="form-group">
								<label for="excludes">Excludes(s)</label>
								<input class="form-control" title="List of labels to exclude from tests" type="text" name="excludes" id="excludes" value="#url.excludes#" placeholder="Excludes(s)" />
							</div>
							<div class="form-group">
								<label for="reportpath">Report Path</label>
								<input class="form-control" title="Report Path" type="text" name="reportpath" id="reportpath" value="#url.reportpath#" placeholder="Report Path" />
							</div>
							<div class="form-group form-check">
								<input class="form-check-input" title="Include Properties Summary" name="propertiesSummary" id="propertiesSummary" type="checkbox" value="true" <cfif url.propertiesSummary>checked="true"</cfif> />
								<label class="form-check-label" for="propertiesSummary"> Include Properties Summary</label>
							</div>
							<div class="form-group" id="propertiesInputs">
								<div class="form-group">
									<label for="propertiesFilename">Properties Filename</label>
									<input class="form-control" title="Properties Filename" type="text" name="propertiesFilename" id="propertiesFilename" value="#url.propertiesFilename#" placeholder="Properties Filename" />
								</div>
							</div>
							<div class="form-group form-check">
								<input class="form-check-input" title="Enable code coverage report" name="coverageEnabled" id="coverageEnabled" type="checkbox" value="true" <cfif url.coverageEnabled>checked="true"</cfif> />
								<label class="form-check-label" for="coverageEnabled"> Enable code coverage report</label>
							</div>
							<div class="form-group form-check">
								<input class="form-check-input" title="Batched coverage reporter for very large suites" name="isBatched" id="isBatched" type="checkbox" value="true" <cfif url.isBatched>checked="true"</cfif> />
								<label class="form-check-label" for="isBatched"> Batched code coverage</label>
							</div>
							<div class="form-group" id="coverageInputs">
								<div class="form-group">
									<label for="coverageSonarQubeXMLOutputPath">Coverage SonarQube XML Output Path</label>
									<input class="form-control" title="Coverage SonarQube XML Output Path" type="text" name="coverageSonarQubeXMLOutputPath" id="coverageSonarQubeXMLOutputPath" value="#url.coverageSonarQubeXMLOutputPath#" placeholder="Coverage SonarQube XML Output Path" />
								</div>
								<div class="form-group">
									<label for="coveragePathToCapture">Coverage Path to Capture</label>
									<input class="form-control" title="Coverage path to Capture" type="text" name="coveragePathToCapture" id="coveragePathToCapture" value="#url.coveragePathToCapture#" placeholder="Coverage path to Capture" />
								</div>
								<div class="form-group">
									<label for="coverageWhitelist">Coverage Whitelist</label>
									<input class="form-control" title="Coverage Whitelist" type="text" name="coverageWhitelist" id="coverageWhitelist" value="#url.coverageWhitelist#" placeholder="Coverage Whitelist" />
								</div>
								<div class="form-group">
									<label for="coverageBlacklist">Coverage Blacklist</label>
									<input class="form-control" title="Coverage Blacklist" type="text" name="coverageBlacklist" id="coverageBlacklist" value="#url.coverageBlacklist#" placeholder="Coverage Blacklist" />
								</div>
								<div class="form-group">
									<label for="coverageBrowserOutputDir">Coverage Browser Output Directory</label>
									<input class="form-control" title="Coverage Browser Output Directory" type="text" name="coverageBrowserOutputDir" id="coverageBrowserOutputDir" value="#url.coverageBrowserOutputDir#" placeholder="Coverage Browser Output Directory" />
								</div>
							</div>

							<div class="form-group">
								<button class="btn btn-sm btn-primary" type="button" onclick="clearResults()">Clear</button>
								<button class="btn btn-sm btn-primary" type="button" id="btn-run" title="Run all the tests" onclick="runTests()">Run</button>
							</div>

						</form>
					</div>
				</div>
			</div>

			<!--- Results --->
			<div id="tb-results" class="container"></div>

		</body>

</html>
</cfoutput>
