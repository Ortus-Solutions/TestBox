/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * HTML view for Smoke Test (manifest reflection checks); used by MetadataSmokeService.renderReport().
 */
component extends="BaseReporter" {

	function getName(){
		return "MetadataSmoke";
	}

	/**
	 * @options smokeResult, runnerErrors, ran, manifestPath, invokeEnabled, smokeRunnerSummary
	 */
	any function renderHtml(
		required testbox.system.TestBox testbox,
		struct options     = {},
		boolean justReturn = false
	){
		if ( !arguments.justReturn ) {
			getPageContextResponse().setContentType( "text/html" );
		}

		variables.testbox     = arguments.testbox;
		variables.smokeResult = structKeyExists( arguments.options, "smokeResult" ) && isStruct(
			arguments.options.smokeResult
		) ? arguments.options.smokeResult : {};
		variables.runnerErrors = structKeyExists( arguments.options, "runnerErrors" ) && isArray(
			arguments.options.runnerErrors
		) ? arguments.options.runnerErrors : [];
		variables.ran          = structKeyExists( arguments.options, "ran" ) ? arguments.options.ran : false;
		variables.manifestPath = structKeyExists( arguments.options, "manifestPath" ) ? toString(
			arguments.options.manifestPath
		) : "";
		variables.invokeEnabled      = structKeyExists( arguments.options, "invokeEnabled" ) ? arguments.options.invokeEnabled : false;
		variables.smokeRunnerSummary = structKeyExists( arguments.options, "smokeRunnerSummary" ) && isStruct(
			arguments.options.smokeRunnerSummary
		) ? arguments.options.smokeRunnerSummary : {};
		variables.smokeEmbedCompact = structKeyExists( arguments.options, "smokeEmbedCompact" ) ? arguments.options.smokeEmbedCompact : false;
		variables.fullPage          = structKeyExists( arguments.options, "fullPage" ) ? arguments.options.fullPage : true;
		variables.smokeEmbedRerunLabels = structKeyExists( arguments.options, "smokeEmbedRerunLabels" ) ? arguments.options.smokeEmbedRerunLabels : false;

		savecontent variable="local.report" {
			include "assets/metadataSmoke.cfm";
		}

		return local.report;
	}

}
