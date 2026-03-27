/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * HTML reporter for heuristic gap analysis (not part of IReporter / testbox.run() flow).
 */
component extends="BaseReporter" {

	function getName(){
		return "GapAnalysis";
	}

	/**
	 * @options gapReport, gapRunnerSummary, runnerErrors, ran, fullPage
	 */
	any function renderHtml(
		required testbox.system.TestBox testbox,
		struct options     = {},
		boolean justReturn = false
	){
		if ( !arguments.justReturn ) {
			getPageContextResponse().setContentType( "text/html" );
		}

		variables.gapReport = structKeyExists( arguments.options, "gapReport" ) && isStruct( arguments.options.gapReport ) ? arguments.options.gapReport : {};
		variables.gapRunnerSummary = structKeyExists( arguments.options, "gapRunnerSummary" ) && isStruct( arguments.options.gapRunnerSummary ) ? arguments.options.gapRunnerSummary : {};
		variables.runnerErrors = structKeyExists( arguments.options, "runnerErrors" ) && isArray( arguments.options.runnerErrors ) ? arguments.options.runnerErrors : [];
		variables.ran = structKeyExists( arguments.options, "ran" ) ? arguments.options.ran : false;
		variables.testbox = arguments.testbox;
		variables.fullPage = structKeyExists( arguments.options, "fullPage" ) ? arguments.options.fullPage : true;

		savecontent variable="local.report" {
			include "assets/gapAnalysis.cfm";
		}

		return local.report;
	}

}
