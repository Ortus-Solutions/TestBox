/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Service for streaming test results via Server-Sent Events (SSE)
 * Compatible with Adobe ColdFusion 2021+, Lucee 5+, and BoxLang
 *
 * LIMITATION: When a test suite uses `asyncAll = true`, the `onSpecStart` and `onSpecEnd`
 * callbacks are invoked from within a cfthread block. Calling writeOutput and cfflush from
 * a child thread doesn't write to the parent request's HTTP response buffer, so spec events
 * for async suites will not be streamed in real-time. Bundle and suite start/end events will
 * still be streamed normally.
 */
component accessors="true" {

	/**
	 * Initialize streaming mode - sets SSE headers
	 *
	 * @return StreamingService
	 */
	function initializeStream(){
		cfheader( name = "Content-Type", value = "text/event-stream" );
		cfheader( name = "Cache-Control", value = "no-cache, no-store, must-revalidate" );
		cfheader( name = "Pragma", value = "no-cache" );
		cfheader( name = "Connection", value = "keep-alive" );
		cfheader( name = "X-Accel-Buffering", value = "no" );
		return this;
	}

	/**
	 * Stream an SSE event to the client
	 * Errors are caught and logged to prevent client disconnects from interrupting test execution.
	 *
	 * @eventType The type of event (e.g., bundleStart, specEnd)
	 * @data      The data payload to send as JSON
	 */
	function streamEvent( required string eventType, required any data ){
		try {
			writeOutput( "event: #arguments.eventType##chr( 10 )#" );
			writeOutput( "data: #serializeJSON( arguments.data )##chr( 10 )##chr( 10 )#" );
			cfflush(  );
		} catch ( any e ) {
			// Client may have disconnected during SSE streaming.
			// Swallow the exception so it does not break the test run.
			try {
				writeLog(
					type = "information",
					file = "testbox-streaming",
					text = "StreamingService.streamEvent terminated early: " & e.message
				);
			} catch ( any ignore ) {
				// Ignore logging errors as well
			}
		}
	}

	/**
	 * Create streaming callbacks for TestBox
	 * These callbacks are passed to testbox.runRaw() to stream events during test execution
	 *
	 * @return struct of callback functions
	 */
	struct function createStreamingCallbacks(){
		var service = this;

		return {
			"onBundleStart" : function( target, testResults ){
				// Note: Bundle stats (including the id) are not yet created when onBundleStart fires.
				// We generate a deterministic id from the path so consumers can correlate
				// bundleStart with bundleEnd events.
				var targetMD    = getMetadata( arguments.target );
				var annotations = targetMD.keyExists( "annotations" ) ? targetMD.annotations : targetMD;
				var bundleName  = structKeyExists( annotations, "displayName" ) ? annotations.displayName : targetMD.name;
				var bundleId    = hash( targetMD.name );

				service.streamEvent(
					"bundleStart",
					{
						"id"        : bundleId,
						"name"      : bundleName,
						"path"      : targetMD.name,
						"timestamp" : getTickCount()
					}
				);
			},
			"onBundleEnd" : function( target, testResults ){
				var targetMD = getMetadata( arguments.target );
				var bundleId = hash( targetMD.name );

				// Look up bundle stats by path (internal stats use a different id scheme)
				var bundleStats   = arguments.testResults.getBundleStats();
				var matchingStats = bundleStats.filter( function( s ){
					return s.path == targetMD.name;
				} );

				// Prefer stats matched by path; fall back to last entry if none found
				var current = matchingStats.len() ? matchingStats[ matchingStats.len() ] : bundleStats[
					bundleStats.len()
				];

				service.streamEvent(
					"bundleEnd",
					{
						"id"            : bundleId,
						"name"          : current.name,
						"path"          : current.path,
						"totalDuration" : current.totalDuration,
						"totalSuites"   : current.totalSuites,
						"totalSpecs"    : current.totalSpecs,
						"totalPass"     : current.totalPass,
						"totalFail"     : current.totalFail,
						"totalError"    : current.totalError,
						"totalSkipped"  : current.totalSkipped
					}
				);
			},
			"onSuiteStart" : function( target, testResults, suite ){
				service.streamEvent(
					"suiteStart",
					{
						"id"        : arguments.suite.id,
						"name"      : arguments.suite.name,
						"timestamp" : getTickCount()
					}
				);
			},
			"onSuiteEnd" : function( target, testResults, suite ){
				var suiteStats = arguments.testResults.getSuiteStats( arguments.suite.id );
				service.streamEvent(
					"suiteEnd",
					{
						"id"            : arguments.suite.id,
						"name"          : arguments.suite.name,
						"totalDuration" : suiteStats.totalDuration,
						"totalSpecs"    : suiteStats.totalSpecs,
						"totalPass"     : suiteStats.totalPass,
						"totalFail"     : suiteStats.totalFail,
						"totalError"    : suiteStats.totalError,
						"totalSkipped"  : suiteStats.totalSkipped
					}
				);
			},
			"onSpecStart" : function( target, testResults, suite, spec ){
				service.streamEvent(
					"specStart",
					{
						"id"          : arguments.spec.id,
						"suiteId"     : arguments.suite.id,
						"name"        : arguments.spec.name,
						"displayName" : arguments.spec.displayName ?: arguments.spec.name,
						"timestamp"   : getTickCount()
					}
				);
			},
			"onSpecEnd" : function( target, testResults, suite, spec ){
				var suiteStats = arguments.testResults.getSuiteStats( arguments.suite.id );
				// Find the spec stats by id
				var specStats  = suiteStats.specStats.filter( function( s ){
					return s.id == spec.id;
				} );
				var currentSpec = specStats.len() ? specStats[ specStats.len() ] : {};

				service.streamEvent(
					"specEnd",
					{
						"id"             : arguments.spec.id,
						"suiteId"        : arguments.suite.id,
						"name"           : arguments.spec.name,
						"displayName"    : arguments.spec.displayName ?: arguments.spec.name,
						"status"         : currentSpec.status ?: "unknown",
						"totalDuration"  : currentSpec.totalDuration ?: 0,
						"failMessage"    : currentSpec.failMessage ?: "",
						"failDetail"     : currentSpec.failDetail ?: "",
						"failStacktrace" : currentSpec.failStacktrace ?: "",
						"failOrigin"     : currentSpec.failOrigin ?: {},
						"error"          : currentSpec.error ?: {}
					}
				);
			}
		};
	}

}
