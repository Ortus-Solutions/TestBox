/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Base class of the HTML reporters. It renders the page from the partials in assets/partials and
 * hands every partial the same ReportHelper, so the reporters only decide which partials to use.
 *
 * Reporter options (all optional):
 * - aiAssist       : show the Ask AI menu on failures, default true. Also ?aiAssist=false
 * - aiProviders    : array of { id, name, url } where url contains {prompt}. Defaults to ChatGPT and Claude
 * - aiContextLines : lines of code before and after the failing line in the prompt, default 5
 * - aiStackFrames  : stack frames in the prompt, default 8
 * - aiPrompt       : custom prompt template using {intro} {spec} {status} {message} {code} {stack} {rerun}
 * - urlParams      : struct of request params (directory, labels, excludes, reporter...) that overrides the url scope.
 *                    The re-run links carry them, so set it when you run reports from code instead of a web request.
 */
component extends="BaseReporter" {

	/**
	 * Render the report using one of the layouts in assets/
	 *
	 * @layout     The layout template without extension, ex: simple
	 * @results    The TestResult
	 * @testbox    The TestBox instance
	 * @options    The reporter options
	 * @justReturn When false the content type is set to text/html
	 */
	private string function renderReport(
		required string layout,
		required results,
		required testbox,
		struct options     = {},
		boolean justReturn = false
	){
		if ( !arguments.justReturn ) {
			getPageContextResponse().setContentType( "text/html" );
		}

		// the incoming url params every report relies on
		prepareIncomingParams();

		variables.results     = arguments.results;
		variables.testbox     = arguments.testbox;
		variables.bundleStats = arguments.results.getBundleStats();
		// the request params that shaped this run, plus the urlParams option for headless runs where there is no url scope
		var params            = {};
		structAppend( params, url );
		if ( structKeyExists( arguments.options, "urlParams" ) && isStruct( arguments.options.urlParams ) ) {
			structAppend( params, arguments.options.urlParams, true );
		}

		variables.helper = new ReportHelper(
			reporter = this,
			options  = arguments.options,
			urlScope = params
		);

		variables.verdict     = variables.helper.verdict( arguments.results );
		variables.failureList = variables.helper.failures( variables.bundleStats );

		savecontent variable="local.report" {
			include "assets/#arguments.layout#.cfm";
		}

		return local.report;
	}

	/**
	 * Render one partial from assets/partials and return its markup.
	 * The partial reads its inputs from arguments.data and from the reporter's variables scope
	 * (results, testbox, bundleStats, helper). Rendering partials through a function keeps recursion
	 * possible, a suite partial can render its nested suites by calling this again.
	 *
	 * @name The partial name without extension
	 * @data The inputs of the partial
	 */
	private string function renderPartial( required string name, struct data = {} ){
		savecontent variable="local.markup" {
			include "assets/partials/#arguments.name#.cfm";
		}
		return local.markup;
	}

}
