/**
********************************************************************************
Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.ortussolutions.com
********************************************************************************
* This TestBox runner is used to run and report on xUnit style test suites.
*/ 
interface{

	/**
	* Constructor
	* @options.hint The options for a runner
	* @testbox.hint The TestBox class reference
	*/
	function init( required struct options, required testbox );

	/**
	* Execute a test run on a target bundle CFC
	* @target.hint The target bundle CFC to test
	* @testResults.hint The test results object to keep track of results for this test case
	*/
	any function run( 
		required any target,
		required testbox.system.TestResult testResults 
	);
	
}