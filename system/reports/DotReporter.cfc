/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A dot matrix reporter
 */
component extends="BaseReporter" {

	function init(){
		return this;
	}

	/**
	 * Get the name of the reporter
	 */
	function getName(){
		return "Dot";
	}

	/**
	 * Do the reporting thing here using the incoming test results
	 * The report should return back in whatever format they desire and should set any
	 * Specific browser types if needed.
	 *
	 * @results    The instance of the TestBox TestResult object to build a report on
	 * @testbox    The TestBox core object
	 * @options    A structure of options this reporter needs to build the report with
	 * @justReturn Boolean flag that if set just returns the content with no content type and buffer reset
	 */
	any function runReport(
		required testbox.system.TestResult results,
		required testbox.system.TestBox testbox,
		struct options     = {},
		boolean justReturn = false
	){
		// bundle stats
		variables.bundleStats = arguments.results.getBundleStats();

		// prepare base links
		variables.baseURL = "?";
		if ( structKeyExists( url, "method" ) ) {
			variables.baseURL &= "method=#urlEncodedFormat( url.method )#";
		}
		if ( structKeyExists( url, "output" ) ) {
			variables.baseURL &= "output=#urlEncodedFormat( url.output )#";
		}
		if ( !structKeyExists( url, "directory" ) ) {
			url.directory = "";
		}

		// prepare incoming params
		prepareIncomingParams();

		// prepare the report
		savecontent variable="local.report" {
			include "assets/dot.cfm";
		}

		return local.report;
	}

}
