/**
********************************************************************************
Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
* An XML reporter
*/ 
component{

	function init(){ 
		variables.converter = new testbox.system.util.XMLConverter();
		return this; 
	}

	/**
	* Get the name of the reporter
	*/
	function getName(){
		return "XML";
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
		getPageContext().getResponse().setContentType( "application/xml" );
		return variables.converter.toXML( data=arguments.results.getMemento(), rootName="TestBox" );
	}
	
}