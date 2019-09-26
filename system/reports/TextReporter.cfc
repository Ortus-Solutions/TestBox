/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* A text reporter
*/
component extends="BaseReporter"{

	function init(){
		return this;
	}

	/**
	* Get the name of the reporter
	*/
	function getName(){
		return "Text";
	}

	/**
	* Do the reporting thing here using the incoming test results
	* The report should return back in whatever format they desire and should set any
	* Specifc browser types if needed.
	* @results.hint The instance of the TestBox TestResult object to build a report on
	* @testbox.hint The TestBox core object
	* @options.hint A structure of options this reporter needs to build the report with
	*/
	any function runReport(
		required testbox.system.TestResult results,
		required testbox.system.TestBox testbox,
		struct options={}
	){
		// content type
		getPageContextResponse().setContentType( "text/plain" );
		// bundle stats
		variables.bundleStats = arguments.results.getBundleStats();

		// prepare the report
		savecontent variable="local.report"{
			include "assets/text.cfm";
		}

		return reReplace( trim( local.report ), '[\r\n]+', chr(10), 'all' );
	}

}