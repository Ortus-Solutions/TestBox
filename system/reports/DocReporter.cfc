/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * The run as a document: bundles as sections, suites as nested sections, specs as a description list.
 * See BaseHTMLReporter for the options.
 */
component extends="BaseHTMLReporter" {

	/**
	 * Get the name of the reporter
	 */
	function getName(){
		return "Doc";
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
		return renderReport(
			layout     = "doc",
			results    = arguments.results,
			testbox    = arguments.testbox,
			options    = arguments.options,
			justReturn = arguments.justReturn
		);
	}

}
