<cfsetting showDebugOutput="false">
<cfsetting requesttimeout="99999999">
<!---
	Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
	www.ortussolutions.com
	---
	Streaming Test Runner - Streams test results via Server-Sent Events (SSE)
	This runner outputs real-time test progress as SSE events, allowing CLI tools
	like CommandBox to display incremental progress during test execution.

	Usage: Add streaming=true to your runner URL parameters
	Example: /tests/runner.cfm?streaming=true&directory=tests.specs
--->

<!--- URL Parameters - same as HTMLRunner.cfm --->
<cfparam name="url.directory" 						default="">
<cfparam name="url.recurse" 						default="true" type="boolean">
<cfparam name="url.bundles" 						default="">
<cfparam name="url.labels" 							default="">
<cfparam name="url.excludes" 						default="">
<cfparam name="url.bundlesPattern" 					default="*.bx|*.cfc">
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

<cfscript>
// Initialize streaming service and set SSE headers
streamingService = new testbox.system.util.StreamingService();

// If we have incoming bundles, then clear out the directory
if( len( url.bundles ) ){
	url.directory = ""
}

// Create TestBox instance with same options as HTMLRunner
testbox = new testbox.system.TestBox(
	labels         = url.labels,
	excludes       = url.excludes,
	options        = {
		coverage : {
			enabled       : url.coverageEnabled,
			pathToCapture : url.coveragePathToCapture,
			whitelist     : url.coverageWhitelist,
			blacklist     : url.coverageBlacklist,
			isBatched     : url.isBatched,
			sonarQube     : { XMLOutputPath : url.coverageSonarQubeXMLOutputPath },
			browser       : { outputDir : url.coverageBrowserOutputDir }
		}
	},
	bundlesPattern = url.bundlesPattern
);

// Add bundles if specified
if ( len( url.bundles ) ) {
	testbox.addBundles( url.bundles );
}

// Add directories if specified
if ( len( url.directory ) ) {
	for ( dir in listToArray( url.directory ) ) {
		testbox.addDirectories( dir, url.recurse );
	}
}

// Stream test run start event
streamingService.initializeStream();
streamingService.streamEvent(
	"testRunStart",
	{
		"timestamp"    : getTickCount(),
		"totalBundles" : arrayLen( testbox.getBundles() ),
		"labels"       : testbox.getLabels(),
		"excludes"     : testbox.getExcludes()
	}
);

// Create streaming callbacks
callbacks = streamingService.createStreamingCallbacks();

// Run tests with streaming callbacks
try {
	results = testbox.runRaw(
		callbacks   = callbacks,
		testSuites  = url.testSuites,
		testSpecs   = url.testSpecs
	);
} catch ( any e ) {
	// Stream a fatal error event so SSE consumers can detect failure
	streamingService.streamEvent(
		"error",
		{
			"timestamp"  : getTickCount(),
			"message"    : e.message,
			"detail"     : e.detail ?: "",
			"type"       : e.type ?: "Exception",
			"tagContext" : e.tagContext ?: []
		}
	);

	rethrow;
}

// Stream final event with full JSON results for outputFormats compatibility
streamingService.streamEvent(
	"testRunEnd",
	{
		"timestamp"     : getTickCount(),
		"totalDuration" : results.getTotalDuration(),
		"totalBundles"  : results.getTotalBundles(),
		"totalSuites"   : results.getTotalSuites(),
		"totalSpecs"    : results.getTotalSpecs(),
		"totalPass"     : results.getTotalPass(),
		"totalFail"     : results.getTotalFail(),
		"totalError"    : results.getTotalError(),
		"totalSkipped"  : results.getTotalSkipped(),
		// Full results memento for outputFormats processing in testbox-cli
		"results"       : results.getMemento( includeDebugBuffer = true )
	}
);
</cfscript>
