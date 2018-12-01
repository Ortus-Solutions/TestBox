/**
* ********************************************************************************
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ********************************************************************************
*
* I am a custom TestBox repoter that captures line coverage data.  Use me like so:
*
* testbox = new testbox.system.TestBox(
*	directory={
*		mapping = url.directory,
*		recurse = url.recurse
*	},
*	reporter={
*	    type = "CoverageReporter",
*	    options = {
*		  	pathToCapture = expandPath( '/root' ),
*			whitelist = '/models,/handlers,/modules_app',
*			blacklist = '/tests,/temp',
*	    	passThroughReporter={
*	    		type='simple',
*	    		option={},
*	    		// This closure will be run against the results from the passthroguh reporter.
*	    		resultsUDF=function( reporterData ) {
*	    			fileWrite( 'myResults.xml', reporterData.results );
*				    reporterData.results = '<pre>' & encodeForHTML( reporterData.results ) & '<pre>';
*	    		}
*	    	},
*	    	sonarQube = {
*				XMLOutputPath = expandpath( '/tests/sonarqube-codeCoverage.xml' )
*	    	}
*	    }
*	} );
*
*/
component {

	/**
	* Get the name of the reporter
	*/
	function getName(){
		return "Code Coverage";
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
		struct options
	){
	  	// Default options
	  	var opts = setDefaultOptions( arguments.options ?: {} );
	  	
	  	// Prepare coverage data
	  	var qryCoverageData = generateCoverageData( opts );
	  				
	  	// SonarQube Integration
	  	var sonarQubeResults = processSonarQube( qryCoverageData, opts );
	  		  	
	  	// Generate Stats
	  	var stats = processStats( qryCoverageData );
	  	var statsHTML = renderStats( stats );
	  		  	
	  	// Generate code browser
	  	processCodeBrowser( qryCoverageData, stats, opts );
	  	
	  	// Execute pass-through reporter
	  	var nestedReporterResult =  processPassThroughReporter( opts, results, testbox );
		
	  	// Prepare the wrapper report
		return renderWrapperReport( sonarQubeResults, statsHTML, nestedReporterResult, testbox, results, opts );
	}

	/**
	* Default user option struct and do some validation
	*/
	private function setDefaultOptions( struct opts={} ) {  	
	  	opts.passThroughReporter = opts.passThroughReporter ?: {};
	  	opts.passThroughReporter.type = opts.passThroughReporter.type ?: 'simple';	  	
	  	opts.passThroughReporter.options = opts.passThroughReporter.options ?: structNew();
	  	
	  	
	  	// Not defaulting opts.passThroughReporter.resultsUDF
	  	
	  	opts.sonarQube = opts.sonarQube ?: {};
		opts.sonarQube.XMLOutputPath = opts.sonarQube.XMLOutputPath ?: '';
		
		opts.browser = opts.browser ?: {};
		opts.browser.outputDir = opts.browser.outputDir ?: '';
				
	  	opts.pathToCapture = opts.pathToCapture ?: '';
		opts.whitelist = opts.whitelist ?: '';
		opts.blacklist = opts.blacklist ?: '';
	  	
	  	// validate path to capture
	  	if( !len( opts.pathToCapture ) ) {
	  		throw( message='Please provide [options.pathToCapture] to the reporter.', detail='The [pathToCapture] option should be an absolute path that points to a directory of CFML code executed by your tests.' );
	  	}
	  		  	
	  	if( !directoryExists( opts.pathToCapture ) ) {
	  		throw( message='Reporter option [pathToCapture] does not point to a real and absolute directory path.', detail=opts.pathToCapture );
	  	}
		return opts;
	}

	/**
	* Interface with FusionReactor to build coverage data
	*/
	private function generateCoverageData( required struct opts ) {		
		var coverageGenerator = new codeCoverage.data.coverageGenerator();
		return coverageGenerator.generateData( 
				opts.pathToCapture,
				opts.whitelist,
				opts.blacklist
			);
	}

	/**
	* Write out SonarQube generic coverage XML file
	*/
	private function processSonarQube( required query qryCoverageData, required struct opts ) {
	  	if( len( opts.sonarQube.XMLOutputPath ) ) {
			// Create XML generator
			var sonarQube = new codeCoverage.sonarqube.SonarQube();
			// Prettify output
			sonarQube.setFormatXML( true );
			
			// Generate XML (writes file and returns string
			sonarQube.generateXML( qryCoverageData, opts.sonarQube.XMLOutputPath );
	  		return 'SonarQube code coverage XML file generated at #opts.sonarQube.XMLOutputPath#';
	  	}
  		return '';
	}
	

	/**
	* Generate statistics from the coverage data
	*/
	private function processStats( required query qryCoverageData ) {
	  	var coverageStats = new codeCoverage.stats.CoverageStats();
	  	return coverageStats.generateStats( qryCoverageData );
	}
	

	/**
	* Render HTML representation of statistics
	*/
	private function renderStats( required struct stats ) {
		savecontent variable="local.statsHTML" {
			include "/testbox/system/reports/codeCoverage/stats/CoverageStats.cfm";
		}
		return local.statsHTML;
	}
	

	/**
	* Generate code browser
	*/
	private function processCodeBrowser( qryCoverageData, stats, opts ) {
		
		// Only generate browser if there's a generation path specified
		if( len( opts.browser.outputDir ) ) {
		  	var codeBrowser = new codeCoverage.browser.CodeBrowser();
		  	codeBrowser.generateBrowser( qryCoverageData, stats, opts.browser.outputDir );
		}
	}

	
	/**
	* Run the passthrough reporter 
	*/
	private function processPassThroughReporter( required struct opts, results, testbox ) {
	  	var nestedReporterResult = '';
	  	if( len( opts.passThroughReporter.type ) ) {
			testbox.exposeBuildReporter = variables.exposeBuildReporter;
			testbox.exposeBuildReporter();
			
			var nestedReporter = testbox.buildReporter( 
				opts.passThroughReporter.type,
				opts.passThroughReporter.options ?: {}
			);
			
			nestedReporterResult = nestedReporter.runReport( arguments.results, arguments.testbox, {} );
			
			// If provided, execute a closure against 
			if( structKeyExists( opts.passThroughReporter, 'resultsUDF' ) ) {
				// Setup struct so we can pass the results via reference
				var reporterData = {
					passThroughReporter = opts.passThroughReporter,
					results = nestedReporterResult
				};
				// Execute UDF
				opts.passThroughReporter.resultsUDF( reporterData=reporterData );
				// Update results in case they changed
				nestedReporterResult = reporterData.results;
			}
	  	}
	  	return nestedReporterResult;
	}
	

	/**
	* Generate our final HTML to display
	*/
	private function renderWrapperReport( sonarQubeResults, statsHTML, nestedReporterResult, testbox, results, opts ) {
		getPageContext().getResponse().setContentType( "text/html" );
		savecontent variable="local.report" {
			include "/testbox/system/reports/codeCoverage/CoverageReportWrapper.cfm";
		}
		return local.report;
	}


	/**
	* This is a mixin that will expose the buildReporter() method in the TestBox component
	*/
	private function exposeBuildReporter() {
		this.buildReporter = variables.buildReporter;
	}

}