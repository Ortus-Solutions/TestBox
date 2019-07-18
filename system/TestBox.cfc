/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
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
    // The labels excluded from testing
	property name="excludes";
	// The reporter attached to this runner
	property name="reporter";
	// The configuration options attached to this runner
	property name="options";
	// Last TestResult in case runner wants to inspect it
	property name="result";
	// Code Coverage Service
	property name="coverageService";

	/**
	* Constructor
	* @bundles The path, list of paths or array of paths of the spec bundle CFCs to run and test
	* @directory The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	* @directories  Same as @directory, but accepts an array or list
	* @reporter The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a testbox.system.reports.IReporter
	* @labels The list or array of labels that a suite or spec must have in order to execute.
	* @options A structure of configuration options that are optionally used to configure a runner.
	*/
	any function init(
		any bundles=[],
		any directory={},
		any directories={},
		any reporter="simple",
        any labels=[],
        any excludes=[],
		struct options={}
	){

		// TestBox version
		variables.version 	= "@build.version@+@build.number@";
		variables.codename 	= "";
		// init util
		variables.utility = new testbox.system.util.Util();
		if( !structKeyExists( arguments.options, 'coverage' ) ) {
			arguments.options.coverage = {};
		}
		variables.coverageService = new testbox.system.coverage.CoverageService( arguments.options.coverage );

		// reporter
		variables.reporter = arguments.reporter;
		// options
		variables.options = arguments.options;
		// Empty bundles to start
		variables.bundles = [];

		// inflate labels
        inflateLabels( arguments.labels );
        // inflate excludes
		inflateExcludes( arguments.excludes );
		// add bundles
		addBundles( arguments.bundles );
		// Add directory given (if any)
		addDirectory( arguments.directory );
		// Add directory given (if any)
		addDirectories( arguments.directories );

		return this;
	}

	/**
	* Constructor
	* @directory A directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	*/
	any function addDirectory( required any directory, boolean recurse=true ) {
		// inflate directory?
		if( isSimpleValue( arguments.directory ) ) {
			arguments.directory = { mapping=arguments.directory, recurse=arguments.recurse };
		}
		// directory passed?
		if( !structIsEmpty( arguments.directory ) ){
			for( var bundle in getSpecPaths( arguments.directory ) ){
				arrayAppend( variables.bundles, bundle );
			}
		}
		return this;
	}

	/**
	* Constructor
	* @directories A set of directories to test which can be a list of simple mapping paths or an array of structs with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	*/
	any function addDirectories( required any directories, boolean recurse=true ){
		if( isSimpleValue( arguments.directories ) ){
			arguments.directories = listToArray( arguments.directories );
		}
		for( var dir in arguments.directories ) {
			addDirectory( dir, arguments.recurse );
		}
		return this;
	}

	/**
	* Constructor
	* @directory A directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	*/
	any function addBundles(required any bundles) {
		if( isSimpleValue( arguments.bundles ) ){
			arguments.bundles = listToArray( arguments.bundles );
		}
		for( var bundle in arguments.bundles ){
			arrayAppend( variables.bundles, bundle );
		}
		return this;
	}

	/**
	 * Run me some testing goodness, this can use the constructed object variables or the ones
	 * you can send right here.
	 *
	 * @bundles The path, list of paths or array of paths of the spec bundle CFCs to run and test
	 * @directory The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	 * @reporter The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or an instance of a testbox.system.reports.IReporter. You can also pass a struct if the reporter requires options: {type="", options={}}
	 * @labels The list or array of labels that a suite or spec must have in order to execute.
     * @excludes The list or array of labels that a suite or spec must not have in order to execute.
	 * @options A structure of configuration options that are optionally used to configure a runner.
	 * @testBundles A list or array of bundle names that are the ones that will be executed ONLY!
	 * @testSuites A list or array of suite names that are the ones that will be executed ONLY!
	 * @testSpecs A list or array of test names that are the ones that will be executed ONLY!
	 * @callbacks A struct of listener callbacks or a CFC with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 * @eagerFailure If this boolean is set to true, then execution of more bundle tests will stop once the first failure/error is detected. By default this is false.
	 */
	any function run(
		any bundles,
		any directory,
		any reporter,
        any labels,
        any excludes,
		struct options,
		any testBundles=[],
		any testSuites=[],
		any testSpecs=[],
		any callbacks={},
		boolean eagerFailure=false
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
	 *
	 * @bundles The path, list of paths or array of paths of the spec bundle CFCs to run and test
	 * @directory The directory to test which can be a simple mapping path or a struct with the following options: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
	 * @labels The list or array of labels that a suite or spec must have in order to execute.
	 * @excludes The list or array of labels that a suite or spec must not have in order to execute.
	 * @options A structure of configuration options that are optionally used to configure a runner.
	 * @testBundles A list or array of bundle names that are the ones that will be executed ONLY!
	 * @testSuites A list or array of suite names that are the ones that will be executed ONLY!
	 * @testSpecs A list or array of test names that are the ones that will be executed ONLY!
	 * @callbacks A struct of listener callbacks or a CFC with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 * @eagerFailure If this boolean is set to true, then execution of more bundle tests will stop once the first failure/error is detected. By default this is false.
	 */
	testbox.system.TestResult function runRaw(
		any bundles,
		any directory,
		any labels,
		any excludes,
		struct options,
		any testBundles=[],
		any testSuites=[],
		any testSpecs=[],
		any callbacks={},
		boolean eagerFailure=false
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
        // Inflate excludes if passed
		if( !isNull( arguments.excludes ) ){ inflateExcludes( arguments.excludes ); }
		// If bundles passed, inflate those as the target
		if( !isNull( arguments.bundles ) ){ inflateBundles( arguments.bundles ); }

        // create results object
		var results = new testbox.system.TestResult(
			bundleCount = arrayLen( variables.bundles ),
            labels      = variables.labels,
            excludes    = variables.excludes,
			testBundles = arguments.testBundles,
			testSuites  = arguments.testSuites,
			testSpecs   = arguments.testSpecs
		);

		coverageService.beginCapture();

		// iterate and run the test bundles
		for( var thisBundlePath in variables.bundles ){
			// Skip interfaces, they are not testable
			if( getComponentMetadata( thisBundlePath ).type eq "interface" ){
				continue;
			}
			// Execute Bundle
			testBundle(
				bundlePath  = thisBundlePath,
				testResults = results,
				callbacks   = arguments.callbacks
			);

			// Eager Failures on Bundle?
			if( arguments.eagerFailure ){
				var failuresDetected = results.getBundleStats()
					// Get stats for running bundle
					.filter( function( item ){
						return ( item.path == thisBundlePath ? true : false );
					} )
					.reduce( function( result, item ){
						return ( item.totalError + item.totalFail ) > 0;
					}, false );

				if( failuresDetected ){
					// Hard skip iterations
					break;
				}
			}
		}

		// mark end of testing bundles
		results.end();

		coverageService.processCoverage( results=results, testbox=this );

		coverageService.endCapture( true );

		sendStatusHeaders( results );

		return results;
	}

	/**
	 * Run me some testing goodness, remotely via SOAP, Flex, REST, URL
	 *
	 * @bundles The path or list of paths of the spec bundle CFCs to run and test
	 * @directory The directory mapping to test: directory = the path to the directory using dot notation (myapp.testing.specs)
	 * @recurse Recurse the directory mapping or not, by default it does
	 * @reporter The type of reporter to use for the results, by default is uses our 'simple' report. You can pass in a core reporter string type or a class path to the reporter to use.
	 * @reporterOptions A JSON struct literal of options to pass into the reporter
	 * @labels The list of labels that a suite or spec must have in order to execute.
	 * @options A JSON struct literal of configuration options that are optionally used to configure a runner.
	 * @testBundles A list or array of bundle names that are the ones that will be executed ONLY!
	 * @testSuites A list of suite names that are the ones that will be executed ONLY!
	 * @testSpecs A list of test names that are the ones that will be executed ONLY!
	 * @eagerFailure If this boolean is set to true, then execution of more bundle tests will stop once the first failure/error is detected. By default this is false.
	*/
	remote function runRemote(
		string bundles,
		string directory,
		boolean recurse=true,
		string reporter="simple",
		string reporterOptions="{}",
        string labels="",
        string excludes="",
		string options,
		string testBundles="",
		string testSuites="",
		string testSpecs="",
		boolean eagerFailure=false
	) output=true {
		// local init
		init();

		// simple to complex
		arguments.labels 		= listToArray( arguments.labels );
		arguments.excludes 		= listToArray( arguments.excludes );
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
	* @results The results object to use to produce a report
	*/
	private any function produceReport( required results ){
		var iData = { type="", options={} };

		// If the type is a simple value then inflate it
		if( isSimpleValue( variables.reporter ) ){
			iData = { type=buildReporter( variables.reporter ), options={} };
		}
		// If the incoming reporter is an object.
		else if ( isObject( variables.reporter ) ){
			iData = { type=variables.reporter, options={} };
		}
		// Do we have reporter type and options
		else if ( isStruct( variables.reporter ) ){
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
	* @reporter The reporter type to build.
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
			case "mintext" : { return new "testbox.system.reports.MinTextReporter"(); }
			case "tap" : { return new "testbox.system.reports.TapReporter"(); }
			case "doc" : { return new "testbox.system.reports.DocReporter"(); }
			case "codexwiki" : { return new "testbox.system.reports.CodexWikiReporter"(); }
			default: {
				return new "#arguments.reporter#"();
			}
		}
	}

	/***************************************** PRIVATE ************************************************************/

	/**
	 * This method executes the tests in a bundle CFC according to type. If the testing was ok a true is returned.
	 *
	 * @bundlePath The path of the Bundle CFC to test.
	 * @testResults The testing results object to keep track of results
	 * @callbacks The callbacks struct or CFC
	 */
	private function testBundle(
		required bundlePath,
		required testResults,
		required callbacks
	){

		// create new target bundle and get its metadata
		var target = getBundle( arguments.bundlePath );

		// verify call backs
		if( structKeyExists( arguments.callbacks, "onBundleStart" ) ){
			arguments.callbacks.onBundleStart( target, testResults );
		}

		try{
			// Discover type?
			if( structKeyExists( target, "run" ) ){
				// Run via BDD Style
				new testbox.system.runners.BDDRunner( options=variables.options, testbox=this )
					.run( target, arguments.testResults, arguments.callbacks );
			}
			else{
				// Run via xUnit Style
				new testbox.system.runners.UnitRunner( options=variables.options,testbox=this )
					.run( target, arguments.testResults, arguments.callbacks );
			}
		} catch( Any e ){
			throw(
				message = "Error executing bundle - #arguments.bundlePath#  message: #e.message# #e.detail#",
				detail  = e.stackTrace,
				type 	= "BundleRunnerMajorException"
			);
		}

		// Store debug buffer for this bundle
		arguments.testResults.storeDebugBuffer( target.getDebugBuffer() );

		// verify call backs
		if( structKeyExists( arguments.callbacks, "onBundleEnd" ) ){
			arguments.callbacks.onBundleEnd( target, testResults );
		}

		return this;
	}

	/**
	* Creates and returns a bundle CFC with spec capabilities if not inherited.
	* @bundlePath The path to the Bundle CFC
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
	* @directory The directory information struct to test: [ mapping = the path to the directory using dot notation (myapp.testing.specs), recurse = boolean, filter = closure that receives the path of the CFC found, it must return true to process or false to continue process ]
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
	* Inflate incoming excludes from a simple string as a standard array
	*/
	private function inflateExcludes(required any excludes){
		variables.excludes = ( isSimpleValue( arguments.excludes ) ? listToArray( arguments.excludes ) : arguments.excludes );
	}

	/**
	* Inflate incoming bundles from a simple string as a standard array
	*/
	private function inflateBundles(required any bundles){
		variables.bundles = ( isSimpleValue( arguments.bundles ) ? listToArray( arguments.bundles ) : arguments.bundles );
	}

}
