/**
********************************************************************************
Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldbox.org | www.ortussolutions.com
********************************************************************************
* Welcome to the next generation of BDD and xUnit testing for CFML applications
* The TestBox core class allows you to execute all kinds of test bundles, directories and more.
*/
component accessors="true"{

	// The version
	property name="version";
	// The codename
	property name="codename";
	// The main utility object
	property name="utility";
	// The CFC bundles to test
	property name="bundles";
	// The labels used for the testing
	property name="labels";
	// The reporter attached to this runner
	property name="reporter";
	// The configuration options attached to this runner
	property name="options";
    // Last TestResult in case runner wants to inspect it
    property name="result";

	/**
	* Constructor
	* @bundles.hint The path, list of paths or array of paths of the spec bundle CFCs to run and test
	* @directory.hint The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	* @reporter.hint The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a testbox.system.reports.IReporter
	* @labels.hint The list or array of labels that a suite or spec must have in order to execute.
	* @options.hint A structure of configuration options that are optionally used to configure a runner.
	*/
	any function init(
		any bundles=[],
		any directory={},
		any reporter="simple",
		any labels=[],
		struct options={}
	){

		// TestBox version
		variables.version 	= "2.1.0+@build.number@";
		variables.codename 	= "";
		// init util
		variables.utility = new testbox.system.util.Util();

		// reporter
		variables.reporter = arguments.reporter;
		// options
		variables.options = arguments.options;

		// inflate directory?
		if( isSimpleValue( arguments.directory ) ){ arguments.directory = { mapping=arguments.directory, recurse=true }; }
		// directory passed?
		if( !structIsEmpty( arguments.directory ) ){
			arguments.bundles = getSpecPaths( arguments.directory );
		}

		// inflate labels
		inflateLabels( arguments.labels );
		// inflate bundles to array
		inflateBundles( arguments.bundles );

		return this;
	}

	/**
	* Run me some testing goodness, this can use the constructed object variables or the ones
	* you can send right here.
	* @bundles.hint The path, list of paths or array of paths of the spec bundle CFCs to run and test
	* @directory.hint The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	* @reporter.hint The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a testbox.system.reports.IReporter. You can also pass a struct if the reporter requires options: {type="", options={}}
	* @labels.hint The list or array of labels that a suite or spec must have in order to execute.
	* @options.hint A structure of configuration options that are optionally used to configure a runner.
	* @testBundles.hint A list or array of bundle names that are the ones that will be executed ONLY!
	* @testSuites.hint A list or array of suite names that are the ones that will be executed ONLY!
	* @testSpecs.hint A list or array of test names that are the ones that will be executed ONLY!
	*/
	any function run(
		any bundles,
		any directory,
		any reporter,
		any labels,
		struct options,
		any testBundles=[],
		any testSuites=[],
		any testSpecs=[]
	){

		// reporter passed?
		if( !isNull( arguments.reporter ) ){ variables.reporter = arguments.reporter; }
		// run it and get results
		var results = runRaw( argumentCollection=arguments );
		// store latest results
        variables.result = results;
        // return report
		return produceReport( results );
	}

	/**
	* Run me some testing goodness but give you back the raw TestResults object instead of a report
	* @bundles.hint The path, list of paths or array of paths of the spec bundle CFCs to run and test
	* @directory.hint The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	* @labels.hint The list or array of labels that a suite or spec must have in order to execute.
	* @options.hint A structure of configuration options that are optionally used to configure a runner.
	* @testBundles.hint A list or array of bundle names that are the ones that will be executed ONLY!
	* @testSuites.hint A list or array of suite names that are the ones that will be executed ONLY!
	* @testSpecs.hint A list or array of test names that are the ones that will be executed ONLY!
	*/
	testbox.system.TestResult function runRaw(
		any bundles,
		any directory,
		any labels,
		struct options,
		any testBundles=[],
		any testSuites=[],
		any testSpecs=[]
	){

		// inflate options if passed
		if( !isNull( arguments.options ) ){ variables.options = arguments.options; }
		// inflate directory?
		if( !isNull( arguments.directory ) && isSimpleValue( arguments.directory ) ){ arguments.directory = { mapping=arguments.directory, recurse=true }; }
		// inflate test bundles, suites and specs from incoming variables.
		arguments.testBundles 	= ( isSimpleValue( arguments.testBundles ) ? listToArray( arguments.testBundles ) : arguments.testBundles );
		arguments.testSuites 	= ( isSimpleValue( arguments.testSuites ) ? listToArray( arguments.testSuites ) : arguments.testSuites );
		arguments.testSpecs 	= ( isSimpleValue( arguments.testSpecs ) ? listToArray( arguments.testSpecs ) : arguments.testSpecs );

		// Verify URL conventions for bundle, suites and specs exclusions.
		if( !isNull( url.testBundles) ){
			testBundles.addAll( listToArray( url.testBundles ) );
		}
		if( !isNull( url.testSuites) ){
			arguments.testSuites.addAll( listToArray( url.testSuites ) );
		}
		if( !isNull( url.testSpecs) ){
			arguments.testSpecs.addAll( listToArray( url.testSpecs ) );
		}
		if( !isNull( url.testMethod) ){
			arguments.testSpecs.addAll( listToArray( url.testMethod ) );
		}

		// Using a directory runner?
		if( !isNull( arguments.directory ) && !structIsEmpty( arguments.directory ) ){
			arguments.bundles = getSpecPaths( arguments.directory );
		}

		// Inflate labels if passed
		if( !isNull( arguments.labels ) ){ inflateLabels( arguments.labels ); }
		// If bundles passed, inflate those as the target
		if( !isNull( arguments.bundles ) ){ inflateBundles( arguments.bundles ); }

		// create results object
		var results = new testbox.system.TestResult( bundleCount=arrayLen( variables.bundles ),
															 labels=variables.labels,
															 testBundles=arguments.testBundles,
															 testSuites=arguments.testSuites,
															 testSpecs=arguments.testSpecs );

		// iterate and run the test bundles
		for( var thisBundlePath in variables.bundles ){
			testBundle( thisBundlePath, results );
		}

		// mark end of testing bundles
		results.end();

		sendStatusHeaders( results );

		return results;
	}

	/**
	* Run me some testing goodness, remotely via SOAP, Flex, REST, URL
	* @bundles.hint The path or list of paths of the spec bundle CFCs to run and test
	* @directory.hint The directory mapping to test: directory = the path to the directory using dot notation (myapp.testing.specs)
	* @recurse.hint Recurse the directory mapping or not, by default it does
	* @reporter.hint The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or a class path to the reporter to use.
	* @reporterOptions.hint A JSON struct literal of options to pass into the reporter
	* @labels.hint The list of labels that a suite or spec must have in order to execute.
	* @options.hint A JSON struct literal of configuration options that are optionally used to configure a runner.
	* @testBundles.hint A list or array of bundle names that are the ones that will be executed ONLY!
	* @testSuites.hint A list of suite names that are the ones that will be executed ONLY!
	* @testSpecs.hint A list of test names that are the ones that will be executed ONLY!
	*/
	remote function runRemote(
		string bundles,
		string directory,
		boolean recurse=true,
		string reporter="simple",
		string reporterOptions="{}",
		string labels="",
		string options,
		string testBundles="",
		string testSuites="",
		string testSpecs=""
	) output=true {
		// local init
		init();

		// simple to complex
		arguments.labels 		= listToArray( arguments.labels );
		arguments.testBundles	= listToArray( arguments.testBundles );
		arguments.testSuites 	= listToArray( arguments.testSuites );
		arguments.testSpecs 	= listToArray( arguments.testSpecs );

		// options inflate from JSON
		if( !isNull( arguments.options ) and isJSON( arguments.options ) ){
			arguments.options = deserializeJSON( arguments.options );
		}
		else{
			arguments.options = {};
		}

		// Inflate directory?
		if( !isNull( arguments.directory ) and len( arguments.directory ) ){
			arguments.directory = { mapping = arguments.directory, recurse = arguments.recurse };
		}

		// reporter options inflate from JSON
		if( !isNull( arguments.reporterOptions ) and isJSON( arguments.reporterOptions ) ){
			arguments.reporterOptions = deserializeJSON( arguments.reporterOptions );
		}
		else{
			arguments.reporterOptions = {};
		}

		// setup reporter
		if( !isNull( arguments.reporter ) and len( arguments.reporter ) ){
			variables.reporter = { type = arguments.reporter, options = arguments.reporterOptions };
		}

		// run it and get results
		var results = runRaw( argumentCollection=arguments );

		// check if reporter is "raw" and if raw, just return it
		if( variables.reporter.type == "raw" ){
			return produceReport( results );
		}
		else{
			// return report
			writeOutput( produceReport( results ) );
		}

		// create status headers
		sendStatusHeaders( results );
	}

	/**
	* Send some status headers
	*/
	private function sendStatusHeaders( required results ){

		try{
			var response = getPageContext().getResponse();

			response.addHeader( "x-testbox-totalDuration", javaCast( "string", results.getTotalDuration() ) );
			response.addHeader( "x-testbox-totalBundles", javaCast( "string", results.getTotalBundles() ) );
			response.addHeader( "x-testbox-totalSuites", javaCast( "string", results.getTotalSuites() ) );
			response.addHeader( "x-testbox-totalSpecs", javaCast( "string", results.getTotalSpecs() ) );
			response.addHeader( "x-testbox-totalPass", javaCast( "string", results.getTotalPass() ) );
			response.addHeader( "x-testbox-totalFail", javaCast( "string", results.getTotalFail() ) );
			response.addHeader( "x-testbox-totalError", javaCast( "string", results.getTotalError() ) );
			response.addHeader( "x-testbox-totalSkipped", javaCast( "string", results.getTotalSkipped() ) );
		} catch( Any e ){
			writeLog( type="error",
					  text="Error sending TestBox headers: #e.message# #e.detail# #e.stackTrace#",
					  file="testbox.log" );
		}

		return this;
	}

	/************************************** REPORTING COMMON METHODS *********************************************/

	/**
	* Build a report according to this runner's setup reporter, which can be anything.
	* @results.hint The results object to use to produce a report
	*/
	private any function produceReport( required results ){
		var iData = { type="", options={} };

		// If the type is a simple value then inflate it
		if( isSimpleValue( variables.reporter ) ){
			iData = { type=buildReporter( variables.reporter ), options={} };
		}

		// If the incoming reporter is an object.
		if( isObject( variables.reporter ) ){
			iData = { type=variables.reporter, options={} };
		}

		// Do we have reporter type and options
		if( isStruct( variables.reporter ) ){
			iData.type = buildReporter( variables.reporter.type );
			if( structKeyExists( variables.reporter, "options" ) ){
				iData.options = variables.reporter.options;
			}
		}
		// build the report from the reporter
		return iData.type.runReport( arguments.results, this, iData.options );
	}

	/**
	* Build a reporter according to passed in reporter type or class path
	* @reporter.hint The reporter type to build.
	*/
	private any function buildReporter( required reporter ){

		switch( arguments.reporter ){
			case "json" : { return new "testbox.system.reports.JSONReporter"(); }
			case "xml" : { return new "testbox.system.reports.XMLReporter"(); }
			case "raw" : { return new "testbox.system.reports.RawReporter"(); }
			case "simple" : { return new "testbox.system.reports.SimpleReporter"(); }
			case "dot" : { return new "testbox.system.reports.DotReporter"(); }
			case "text" : { return new "testbox.system.reports.TextReporter"(); }
			case "junit" : { return new "testbox.system.reports.JUnitReporter"(); }
			case "antjunit" : { return new "testbox.system.reports.ANTJUnitReporter"(); }
			case "console" : { return new "testbox.system.reports.ConsoleReporter"(); }
			case "min" : { return new "testbox.system.reports.MinReporter"(); }
			case "tap" : { return new "testbox.system.reports.TapReporter"(); }
			case "doc" : { return new "testbox.system.reports.DocReporter"(); }
			case "codexwiki" : { return new "testbox.system.reports.CodexWikiReporter"(); }
			default: {
				return new "#arguments.reporter#"();
			}
		}
	}

	/***************************************** PRIVATE ************************************************************ //

	/**
	* This method executes the tests in a bundle CFC according to type
	* @bundlePath.hint The path of the Bundle CFC to test.
	* @testResults.hint The testing results object to keep track of results
	*/
	private function testBundle(
		required bundlePath,
		required testResults
	){

		// create new target bundle and get its metadata
		var target = getBundle( arguments.bundlePath );

		// Discover type?
		if( structKeyExists( target, "run" ) ){
			// Run via BDD Style
			new testbox.system.runners.BDDRunner( testbox=this, options=variables.options )
				.run( target, arguments.testResults );
		}
		else{
			// Run via xUnit Style
			new testbox.system.runners.UnitRunner( testbox=this, options=variables.options )
				.run( target, arguments.testResults );
		}

		// Store debug buffer for this bundle
		arguments.testResults.storeDebugBuffer( target.getDebugBuffer() );

		return this;
	}

	/**
	* Creates and returns a bundle CFC with spec capabilities if not inherited.
	* @bundlePath.hint The path to the Bundle CFC
	*/
	private any function getBundle( required bundlePath ){
		var bundle		= createObject( "component", "#arguments.bundlePath#" );
		var familyPath 	= "testbox.system.BaseSpec";

		// check if base spec assigned
		if( isInstanceOf( bundle, familyPath ) ){
			return bundle;
		}

		// Else virtualize it
		var baseObject 			= new testbox.system.BaseSpec();
		var excludedProperties 	= "";

		// Mix it up baby
		variables.utility.getMixerUtil().start( bundle );

		// Mix in the virtual methods
		for( var key in baseObject ){
			// If target has overriden method, then don't override it with mixin, simulated inheritance
			if( NOT structKeyExists( bundle, key ) AND NOT listFindNoCase( excludedProperties, key ) ){
				bundle.injectMixin( key, baseObject[ key ] );
			}
		}

		// Mix in virtual super class just in case we need it
		bundle.$super = baseObject;

		return bundle;
	}

	/**
	* Get an array of spec paths from a directory
	* @directory.hint The directory information struct to test: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	*/
	private function getSpecPaths( required directory ){
		var results = [];

		// recurse default
		arguments.directory.recurse = ( structKeyExists( arguments.directory, "recurse" ) ? arguments.directory.recurse : true );
		// clean up paths
		var bundleExpandedPath 	= expandPath( "/" & replace( arguments.directory.mapping, ".", "/", "all" ) );
		bundleExpandedPath 		= replace( bundleExpandedPath, "\", "/", "all" );
		// search directory with filters
		var bundlesFound 		= directoryList( bundleExpandedPath, arguments.directory.recurse, "path", "*.cfc", "asc" );

		// cleanup paths and store them for usage
		for( var x=1; x lte arrayLen( bundlesFound ); x++ ){

			// filter closure exists and the filter does not match the path
			if( structKeyExists( arguments.directory, "filter" ) && !arguments.directory.filter( bundlesFound[ x ] ) ){
				continue;
			}

			// standardize paths
			bundlesFound[ x ] = rereplace( replaceNoCase( bundlesFound[ x ], ".cfc", "" ) , "(\\|/)", "/", "all" );
			// clean base out of them
			bundlesFound[ x ] = replace( bundlesFound[ x ], bundleExpandedPath, "" );
			// Clean out slashes and append the mapping.
			bundlesFound[ x ] = arguments.directory.mapping & rereplace( bundlesFound[ x ], "(\\|/)", ".", "all" );

			arrayAppend( results, bundlesFound[ x ] );
		}

		return results;
	}

	/**
	* Inflate incoming labels from a simple string as a standard array
	*/
	private function inflateLabels(required any labels){
		variables.labels = ( isSimpleValue( arguments.labels ) ? listToArray( arguments.labels ) : arguments.labels );
	}

	/**
	* Inflate incoming bundles from a simple string as a standard array
	*/
	private function inflateBundles(required any bundles){
		variables.bundles = ( isSimpleValue( arguments.bundles ) ? listToArray( arguments.bundles ) : arguments.bundles );
	}

}