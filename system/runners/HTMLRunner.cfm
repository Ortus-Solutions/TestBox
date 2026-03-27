<cfsetting showDebugOutput="false">
<cfsetting requesttimeout="99999999">
<!--- Executes all tests in the 'specs' folder with simple reporter by default --->
<cfparam name="url.reporter" 						default="simple">
<cfparam name="url.directory" 						default="">
<cfparam name="url.recurse" 						default="true" type="boolean">
<cfparam name="url.bundles" 						default="">
<cfparam name="url.labels" 							default="">
<cfparam name="url.excludes" 						default="">
<cfparam name="url.reportpath" 						default="">
<cfparam name="url.propertiesFilename"			 	default="TEST.properties">
<cfparam name="url.propertiesSummary"			 	default="false" type="boolean">
<cfparam name="url.bundlesPattern" 					default="*.bx|*.cfc">
<cfparam name="url.dryRun"							default="false" type="boolean">
<cfparam name="url.testSuites"						default="">
<cfparam name="url.testSpecs"						default="">

<!--- Coverage parameters --->
<cfparam name="url.coverageEnabled"					default="false" type="boolean">
<cfparam name="url.coverageSonarQubeXMLOutputPath"	default="">
<cfparam name="url.coverageBrowserOutputDir"		default="">
<cfparam name="url.coveragePathToCapture"			default="">
<cfparam name="url.coverageWhitelist"				default="">
<cfparam name="url.coverageBlacklist"				default="/testbox">
<!--- Enable batched code coverage reporter, useful for large test bundles which require spreading over multiple testbox run commands. --->
<cfparam name="url.isBatched"						default="false">
<cfparam name="url.gapAnalysis"						default="false">

<cfscript>
// If we have incoming bundles, then clear out the directory
if( len( url.bundles ) ){
	url.directory = ""
}

function escapePropertyValue( required string value ) {
	if ( len( arguments.value ) == 0 ) {
		return arguments.value;
	}
	var v = replaceNoCase( arguments.value, '\', '\\', 'all' );
	v = replaceNoCase( v, chr(13), '\r', 'all' );
	v = replaceNoCase( v, chr(10), '\n', 'all' );
	v = replaceNoCase( v, chr(9), '\t', 'all' );
	v = replaceNoCase( v, chr(60), '\u003c', 'all' );
	v = replaceNoCase( v, chr(62), '\u003e', 'all' );
	v = replaceNoCase( v, chr(47), '\u002f', 'all' );
	return replaceNoCase( v, chr(32), '\u0020', 'all' );
}

gapFlag = structKeyExists( url, "gapAnalysis" ) && listFindNoCase( "true,yes,1", trim( toString( url.gapAnalysis ) ) ) > 0;

// prepare for tests for bundles or directories
testbox = new testbox.system.TestBox(
	labels   = url.labels,
	excludes = url.excludes,
	options  =  {
		coverage : {
			enabled       	: url.coverageEnabled,
			pathToCapture 	: url.coveragePathToCapture,
			whitelist     	: url.coverageWhitelist,
			blacklist     	: url.coverageBlacklist,
			isBatched		: url.isBatched,
			sonarQube     	: {
				XMLOutputPath : url.coverageSonarQubeXMLOutputPath
			},
			browser			: {
				outputDir : url.coverageBrowserOutputDir
			}
		}
	},
	bundlesPattern = url.bundlesPattern
)
if( len( url.bundles ) ){
	testbox.addBundles( url.bundles )
}
if( len( url.directory ) ){
	for( dir in listToArray( url.directory ) ){
		testbox.addDirectories( dir, url.recurse )
	}
}

if ( gapFlag ) {
	runnerErrors = [];
	gapReport = {};
	ran = false;
	gapRunnerSummary = {};
	sourceRoot = "";
	componentPrefix = "";
	testRoots = [];
	try {
		if ( !len( trim( toString( url.directory ) ) ) ) {
			arrayAppend( runnerErrors, "gapAnalysis requires url.directory (same as a normal TestBox directory run)." );
		} else {
			sourceRoot = testbox.getCoverageService().getCoverageOptions().pathToCapture;
			gapSvc = new testbox.system.gap.GapAnalysisService();
			componentPrefix = gapSvc.inferComponentPrefix( sourceRoot );
			if ( !len( componentPrefix ) ) {
				arrayAppend( runnerErrors, "Could not infer component prefix from coverage pathToCapture; check url.coveragePathToCapture and application mappings." );
			} else {
				testRoots = [];
				for ( dir in listToArray( url.directory ) ) {
					dir = trim( dir );
					if ( !len( dir ) ) {
						continue;
					}
					arrayAppend( testRoots, expandPath( "/" & replace( dir, ".", "/", "all" ) ) );
				}
				if ( !arrayLen( testRoots ) ) {
					arrayAppend( runnerErrors, "No valid test directories resolved from url.directory." );
				} else {
					gapReport = gapSvc.analyze(
						sourceRoot = sourceRoot,
						componentPrefix = componentPrefix,
						testRootList = arrayToList( testRoots, "," ),
						recurseTestRoots = url.recurse
					);
					ran = true;
				}
			}
		}
	} catch ( any e ) {
		arrayAppend( runnerErrors, e.message );
		if ( structKeyExists( e, "detail" ) && len( toString( e.detail ) ) ) {
			arrayAppend( runnerErrors, toString( e.detail ) );
		}
	}
	qs = structKeyExists( cgi, "query_string" ) ? cgi.query_string : "";
	stripQs = reReplace( qs, "&gapAnalysis=[^&]*", "", "all" );
	stripQs = reReplace( stripQs, "^gapAnalysis=[^&]*&?", "", "all" );
	stripQs = reReplace( stripQs, "^[&]+|[&]+$", "", "all" );
	testsUrl = len( stripQs ) ? ( cgi.script_name & "?" & stripQs ) : cgi.script_name;
	gapRunnerSummary = {
		"directory" : url.directory,
		"recurse" : url.recurse,
		"bundles" : url.bundles,
		"coveragePathToCapture" : url.coveragePathToCapture,
		"sourceRootAbs" : sourceRoot,
		"componentPrefix" : componentPrefix,
		"testRootAbs" : testRoots,
		"testsUrl" : testsUrl
	};
	gapHtml = new testbox.system.gap.GapAnalysisService().renderReport(
		testbox = testbox,
		gapReport = gapReport,
		gapRunnerSummary = gapRunnerSummary,
		runnerErrors = runnerErrors,
		ran = ran
	);
	writeOutput( gapHtml );
	abort;
}

// Run Tests using correct reporter
if( url.dryRun ){
	discovery = testbox.dryRun()
	cfcontent( type="application/json", reset="true" )
	results = serializeJSON( discovery )
} else {
	results = testbox.run( reporter=url.reporter )
}

// Write TEST.properties in report destination path.
if( !url.dryRun && url.propertiesSummary ){
	testResult = testbox.getResult();
	errors = testResult.getTotalFail() + testResult.getTotalError();
	savecontent variable="propertiesReport"{
writeOutput( ( errors ? "test.failed=true" : "test.passed=true" ) & chr( 10 ) );
writeOutput( "test.labels=#escapePropertyValue( arrayToList( testResult.getLabels() ) )#
test.bundles=#escapePropertyValue( URL.bundles )#
test.directory=#escapePropertyValue( url.directory )#
total.bundles=#escapePropertyValue( testResult.getTotalBundles() )#
total.suites=#escapePropertyValue( testResult.getTotalSuites() )#
total.specs=#escapePropertyValue( testResult.getTotalSpecs() )#
total.pass=#escapePropertyValue( testResult.getTotalPass() )#
total.fail=#escapePropertyValue( testResult.getTotalFail() )#
total.error=#escapePropertyValue( testResult.getTotalError() )#
total.skipped=#escapePropertyValue( testResult.getTotalSkipped() )#" );
	}

	//ACF Compatibility - check for and expand to absolute path
	if( !directoryExists( url.reportpath ) ) url.reportpath = expandPath( url.reportpath );

	if( !trim( lcase( url.propertiesfilename ) ).endsWith( '.properties' ) ) {
		url.propertiesfilename &= '.properties';
	}
	fileWrite( url.reportpath & "/" & url.propertiesfilename, propertiesReport );
}

// do stupid JUnitReport task processing, if the report is ANTJunit
if( !url.dryRun && url.reporter eq "ANTJunit" ){
	// Produce individual test files due to how ANT JUnit report parses these.
	xmlReport = xmlParse( results );
	for( thisSuite in xmlReport.testsuites.XMLChildren ){
		fileWrite( url.reportpath & "/TEST-" & thisSuite.XMLAttributes.package & ".xml", toString( thisSuite ) );
	}
}

// Writeout Results
writeoutput( results );
</cfscript>
