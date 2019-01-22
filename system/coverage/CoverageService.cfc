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
component accessors="true" {
	property name="coverageEnabled" type="boolean";
	property name="coverageOptions" type="struct";
	property name="coverageGenerator" type="any";

	/**
	* Boostrap the Code Coverage service and decide if we'll be enabled or not
	*/
	function init( coverageOptions={} ) {

	  	// Default options
	  	variables.coverageOptions = setDefaultOptions( coverageOptions );
	  	variables.coverageEnabled = coverageOptions.enabled;

	  	// If disabled in config, go no further
	  	if( coverageEnabled ) {
			variables.coverageGenerator = new data.CoverageGenerator();
			variables.coverageEnabled = coverageGenerator.configure();
	  	}
	}

	/**
	* Reset system for a new test.  Turns on line coverage and resets in-memory statistics
	*/
	function beginCapture() {
	  	if( coverageEnabled ) {
			coverageGenerator.beginCapture();
	  	}
	}

	/**
	* End the capture of data.  Clears up memory and optionally turns off line profiling
	* @leaveLineProfilingOn Set to true to leave line profiling enabled on the server
	*/
	function endCapture( leaveLineProfilingOn=false  ) {
	  	if( coverageEnabled ) {
			coverageGenerator.endCapture( leaveLineProfilingOn );
	  	}
	}

	/**
	* Process Code Coverage if enabled and set results inside the TestResult object
	*
	* @results.hint The instance of the TestBox TestResult object to build a report on
	* @testbox.hint The TestBox core object
	*/
	any function processCoverage(
		required testbox.system.TestResult results,
		required testbox.system.TestBox testbox
	){

		if( getCoverageEnabled() ) {

		  	// Prepare coverage data
		  	var qryCoverageData = generateCoverageData( getCoverageOptions() );

		  	// SonarQube Integration
		  	var sonarQubeResults = processSonarQube( qryCoverageData, getCoverageOptions() );

		  	// Generate Stats
		  	var stats = processStats( qryCoverageData );

		  	// Generate code browser
		  	var browserResults = processCodeBrowser( qryCoverageData, stats, getCoverageOptions() );

		  	results.setCoverageEnabled( true );
		  	results.setCoverageData( {
		  		'qryData' : qryCoverageData,
		  		'stats' : stats,
		  		'sonarQubeResults' : sonarQubeResults,
		  		'browserResults' : browserResults
		  	} );

	  	}
	}

	/**
	* Render HTML representation of statistics
	*/
	function renderStats( required struct coverageData ) {
		var stats = coverageData.stats;
		var codeBrowser = new browser.CodeBrowser(getCoverageOptions().coverageTresholds);

		savecontent variable="local.statsHTML" {
			include "/testbox/system/coverage/stats/CoverageStats.cfm";
		}
		return local.statsHTML;
	}

	/**
	* Default user option struct and do some validation
	*/
	private function setDefaultOptions( struct opts={} ) {

		if( isNull( opts.enabled ) ) { opts.enabled = true; }


		if( isNull( opts.sonarQube ) ) { opts.sonarQube = {}; }
		if( isNull( opts.sonarQube.XMLOutputPath ) ) { opts.sonarQube.XMLOutputPath = ''; }

		if( isNull( opts.browser ) ) { opts.browser = {}; }
		if( isNull( opts.browser.outputDir ) ) { opts.browser.outputDir = ''; }

		if( isNull( opts.coverageTresholds ) ) { opts.coverageTresholds = {}; }
		if( isNull( opts.coverageTresholds.good ) ) { opts.coverageTresholds.good = 85; }
		if( isNull( opts.coverageTresholds.bad ) ) { opts.coverageTresholds.bad = 50; }

		if( isNull( opts.pathToCapture ) ) { opts.pathToCapture = ''; }
		if( isNull( opts.whitelist ) ) { opts.whitelist = ''; }
		if( isNull( opts.blacklist ) ) { opts.blacklist = ''; }

	  	// If no path provided to capture
	  	if( !len( opts.pathToCapture ) ) {

	  		// Look for a /root mapping
	  		if( directoryExists( expandPath( '/root' ) ) ) {
	  			opts.pathToCapture = expandPath( '/root' );
	  		// And default to entire web root
	  		} else {
	  			opts.pathToCapture = expandPath( '/' );
	  		}

	  	} else if( !directoryExists( opts.pathToCapture ) && directoryExists( expandPath( opts.pathToCapture ) ) ) {
	  		opts.pathToCapture = expandPath( opts.pathToCapture );
	  	}

		// Bypass validation if not enabled
		if( !opts.enabled ) {
			return opts;
		}

	  	if( !directoryExists( opts.pathToCapture ) ) {
	  		throw( message='Coverage option [pathToCapture] does not point to a real and absolute directory path.', detail=opts.pathToCapture );
	  	}
		return opts;
	}

	/**
	* Interface with FusionReactor to build coverage data
	*/
	private function generateCoverageData( required struct opts ) {
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
			var sonarQube = new sonarqube.SonarQube();
			// Prettify output
			sonarQube.setFormatXML( true );

			// Generate XML (writes file and returns string
			sonarQube.generateXML( qryCoverageData, opts.sonarQube.XMLOutputPath );
	  		return opts.sonarQube.XMLOutputPath;
	  	}
  		return '';
	}


	/**
	* Generate statistics from the coverage data
	*/
	private function processStats( required query qryCoverageData ) {
	  	var coverageStats = new stats.CoverageStats();
	  	return coverageStats.generateStats( qryCoverageData );
	}

	/**
	* Generate code browser
	*/
	private function processCodeBrowser( qryCoverageData, stats, opts ) {

		// Only generate browser if there's a generation path specified
		if( len( opts.browser.outputDir ) ) {
		  	var codeBrowser = new browser.CodeBrowser(opts.coverageTresholds);
		  	codeBrowser.generateBrowser( qryCoverageData, stats, opts.browser.outputDir );
	  		return opts.browser.outputDir;
		}
  		return '';
	}

}