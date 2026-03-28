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
<cfparam name="url.metadataSmoke"					default="false">
<cfparam name="url.metadataSmokeManifest"			default="">
<cfparam name="url.metadataSmokeComponent"			default="">
<cfparam name="url.metadataSmokeDirectoryRoot"		default="">
<cfparam name="url.metadataSmokeDirectoryPrefix"	default="">
<cfparam name="url.metadataSmokeExcludeFileNames"	default="">
<cfparam name="url.metadataSmokeExcludePathPrefixes"	default="">
<cfparam name="url.metadataSmokeExcludeComponentIds"	default="">
<cfparam name="url.metadataSmokeInvoke"				default="false">
<cfparam name="url.metadataSmokeFormat"				default="">

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
	sourceRoot = "";
	componentPrefix = "";
	testRoots = [];
	try {
		if ( !len( trim( toString( url.directory ) ) ) ) {
			arrayAppend( runnerErrors, "gapAnalysis requires url.directory (same as a normal TestBox directory run)." );
		} else {
			sourceRoot = testbox.getCoverageService().getCoverageOptions().pathToCapture;
			gapSvc = testbox.getGapAnalysisService();
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
	gapRunnerSummary = testbox.getGapAnalysisService().buildRunnerSummaryFromRequest( testbox, sourceRoot, componentPrefix, testRoots, false ).gapRunnerSummary;
	gapHtml = testbox.getGapAnalysisService().renderReport(
		testbox = testbox,
		gapReport = gapReport,
		gapRunnerSummary = gapRunnerSummary,
		runnerErrors = runnerErrors,
		ran = ran
	);
	writeOutput( gapHtml );
	abort;
}

metadataSmokeFlag = structKeyExists( url, "metadataSmoke" ) && listFindNoCase( "true,yes,1", trim( toString( url.metadataSmoke ) ) ) > 0;
if ( !metadataSmokeFlag ) {
	for ( var k in url ) {
		if ( reReplace( lCase( k ), "[^a-z]", "", "all" ) == "metadatasmoke" && listFindNoCase( "true,yes,1", trim( toString( url[ k ] ) ) ) > 0 ) {
			metadataSmokeFlag = true;
			break;
		}
	}
}
metadataSmokeJson = structKeyExists( url, "metadataSmokeFormat" ) && listFindNoCase( "json", trim( toString( url.metadataSmokeFormat ) ) ) > 0;

if ( metadataSmokeFlag ) {
	runnerErrors = [];
	smokeResult = {};
	ran = false;
	manifestWeb = "";
	smokeComponentForUrl = "";
	invokeFlag = structKeyExists( url, "metadataSmokeInvoke" ) && listFindNoCase( "true,yes,1", trim( toString( url.metadataSmokeInvoke ) ) ) > 0;
	smokeSvc = testbox.getMetadataSmokeService();
	try {
		if ( structKeyExists( request, "metadataSmokeManifestItems" ) ) {
			smokeResult = smokeSvc.runSmokeFromManifestItems( request.metadataSmokeManifestItems, invokeFlag );
			ran = true;
			manifestWeb = "(in-memory manifest)";
		} else if ( structKeyExists( request, "metadataSmokeDirectoryScan" ) && isStruct( request.metadataSmokeDirectoryScan ) ) {
			ds = request.metadataSmokeDirectoryScan;
			rootAbs = structKeyExists( ds, "absoluteComponentRoot" ) ? trim( toString( ds.absoluteComponentRoot ) ) : "";
			dotted = structKeyExists( ds, "dottedPrefix" ) ? trim( toString( ds.dottedPrefix ) ) : "";
			dsOpts = structKeyExists( ds, "options" ) && isStruct( ds.options ) ? ds.options : {};
			if ( !len( rootAbs ) || !len( dotted ) ) {
				arrayAppend( runnerErrors, "request.metadataSmokeDirectoryScan requires absoluteComponentRoot and dottedPrefix." );
			} else {
				smokeResult = smokeSvc.runSmokeFromDirectoryInline( rootAbs, dotted, dsOpts, invokeFlag );
				ran = true;
				manifestWeb = "(directory scan)";
			}
		} else {
			smokeComponentForUrl = structKeyExists( url, "metadataSmokeComponent" ) ? trim( toString( url.metadataSmokeComponent ) ) : "";
			if ( len( smokeComponentForUrl ) ) {
				smokeResult = smokeSvc.runSmokeForSingleComponent( smokeComponentForUrl, invokeFlag );
				ran = true;
				manifestWeb = smokeComponentForUrl;
			} else {
				manifestWeb = structKeyExists( url, "metadataSmokeManifest" ) ? trim( toString( url.metadataSmokeManifest ) ) : "";
				if ( len( manifestWeb ) ) {
					absManifest = smokeSvc.resolveManifestAbsolutePath( manifestWeb );
					if ( !fileExists( absManifest ) ) {
						arrayAppend( runnerErrors, "Manifest not found: #absManifest#" );
					} else {
						smokeResult = smokeSvc.runSmokeFromManifestFile( absManifest, invokeFlag );
						ran = true;
					}
				} else {
					dirRootWeb = structKeyExists( url, "metadataSmokeDirectoryRoot" ) ? trim( toString( url.metadataSmokeDirectoryRoot ) ) : "";
					dirPrefix = structKeyExists( url, "metadataSmokeDirectoryPrefix" ) ? trim( toString( url.metadataSmokeDirectoryPrefix ) ) : "";
					if ( len( dirRootWeb ) && len( dirPrefix ) ) {
						rootAbs = smokeSvc.resolveManifestAbsolutePath( dirRootWeb );
						dsOpts = {};
						exFiles = structKeyExists( url, "metadataSmokeExcludeFileNames" ) ? trim( toString( url.metadataSmokeExcludeFileNames ) ) : "";
						exPfx = structKeyExists( url, "metadataSmokeExcludePathPrefixes" ) ? trim( toString( url.metadataSmokeExcludePathPrefixes ) ) : "";
						exIds = structKeyExists( url, "metadataSmokeExcludeComponentIds" ) ? trim( toString( url.metadataSmokeExcludeComponentIds ) ) : "";
						if ( len( exFiles ) ) {
							dsOpts.excludeFileNames = exFiles;
						}
						if ( len( exPfx ) ) {
							dsOpts.excludeRelativePathPrefixes = exPfx;
						}
						if ( len( exIds ) ) {
							dsOpts.excludeComponentIds = exIds;
						}
						smokeResult = smokeSvc.runSmokeFromDirectoryInline( rootAbs, dirPrefix, dsOpts, invokeFlag );
						ran = true;
						manifestWeb = "(directory scan)";
					} else {
						arrayAppend( runnerErrors, "metadataSmoke requires one of: request.metadataSmokeManifestItems, request.metadataSmokeDirectoryScan, url.metadataSmokeComponent, url.metadataSmokeManifest, or url.metadataSmokeDirectoryRoot + url.metadataSmokeDirectoryPrefix." );
					}
				}
			}
		}
	} catch ( any e ) {
		arrayAppend( runnerErrors, e.message );
		if ( structKeyExists( e, "detail" ) && len( toString( e.detail ) ) ) {
			arrayAppend( runnerErrors, toString( e.detail ) );
		}
	}
	if ( metadataSmokeJson ) {
		cfcontent( type="application/json", reset="true" );
		writeOutput( serializeJSON( {
			"runnerErrors"  : runnerErrors,
			"ran"           : ran,
			"smokeResult"   : smokeResult,
			"manifestPath"  : manifestWeb,
			"invokeEnabled" : invokeFlag,
			"metadataSmokeComponent" : smokeComponentForUrl
		} ) );
	} else {
		html = smokeSvc.renderReport(
			testbox = testbox,
			smokeResult = smokeResult,
			runnerErrors = runnerErrors,
			ran = ran,
			manifestPath = manifestWeb,
			invokeEnabled = invokeFlag,
			metadataSmokeComponent = smokeComponentForUrl,
			metadataSmokeDirectoryRootWeb = structKeyExists( url, "metadataSmokeDirectoryRoot" ) ? trim( toString( url.metadataSmokeDirectoryRoot ) ) : "",
			metadataSmokeDirectoryPrefixForUrl = structKeyExists( url, "metadataSmokeDirectoryPrefix" ) ? trim( toString( url.metadataSmokeDirectoryPrefix ) ) : "",
			metadataSmokeExcludeFileNamesForUrl = structKeyExists( url, "metadataSmokeExcludeFileNames" ) ? trim( toString( url.metadataSmokeExcludeFileNames ) ) : "",
			metadataSmokeExcludePathPrefixesForUrl = structKeyExists( url, "metadataSmokeExcludePathPrefixes" ) ? trim( toString( url.metadataSmokeExcludePathPrefixes ) ) : "",
			metadataSmokeExcludeComponentIdsForUrl = structKeyExists( url, "metadataSmokeExcludeComponentIds" ) ? trim( toString( url.metadataSmokeExcludeComponentIds ) ) : "",
			justReturn = false
		);
		writeOutput( html );
	}
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
