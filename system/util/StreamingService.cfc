/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Service for streaming test results via Server-Sent Events (SSE)
 * Compatible with Adobe ColdFusion 2023+, Lucee 5+, and BoxLang
 *
 * When `asyncAll = true` is used in test suites, spec callbacks run inside cfthread blocks.
 * Since writeOutput/cfflush from child threads don't write to the parent HTTP response buffer,
 * this service supports a queue-based approach:
 * - Events from thread contexts are automatically queued
 * - Call drainQueue() from the main thread after threads join to flush queued events
 * - Alternatively, enable queueMode to queue all events regardless of context
 */
component accessors="true" {

	/**
	 * Whether to actually flush output (set to false for unit testing)
	 */
	property
		name   ="flushEnabled"
		type   ="boolean"
		default="true";

	/**
	 * Whether to queue events instead of streaming directly
	 * When true, all events are queued regardless of thread context.
	 * When false (default), events are auto-queued only when called from a thread.
	 */
	property
		name   ="queueMode"
		type   ="boolean"
		default="false";

	/**
	 * Thread-safe event queue for async event buffering
	 * Uses Java ConcurrentLinkedQueue for thread safety
	 */
	property name="eventQueue" type="any";

	/**
	 * Utility helper for thread detection
	 */
	property name="util" type="any";

	/**
	 * Constructor - initializes the thread-safe event queue
	 */
	function init(){
		variables.eventQueue = createObject( "java", "java.util.concurrent.ConcurrentLinkedQueue" ).init();
		variables.queueMode  = false;
		variables.util       = new testbox.system.util.Util();
		return this;
	}

	/**
	 * Initialize streaming mode - sets SSE headers
	 *
	 * @return StreamingService
	 */
	function initializeStream(){
		// Set SSE-specific headers to establish the correct content type and disable buffering
		cfcontent( type = "text/event-stream; charset=UTF-8", reset = "true" );
		cfheader( name = "Cache-Control", value = "no-cache, no-transform" );
		cfheader( name = "Pragma", value = "no-cache" );
		cfheader( name = "Connection", value = "keep-alive" );
		// Disable nginx buffering
		cfheader( name = "X-Accel-Buffering", value = "no" );
		// avoid gzip buffering in some stacks
		cfheader( name = "Content-Encoding", value = "identity" );
		return this;
	}

	/**
	 * Format an SSE event as a string
	 * Returns the properly formatted SSE event string without writing to output
	 *
	 * @eventType The type of event (e.g., bundleStart, specEnd)
	 * @data      The data payload to serialize as JSON
	 *
	 * @return string The formatted SSE event string
	 */
	string function formatSSEEvent( required string eventType, required any data ){
		return "event: #arguments.eventType##chr( 10 )#data: #serializeJSON( arguments.data )##chr( 10 )##chr( 10 )#";
	}

	/**
	 * Stream an SSE event to the client
	 * When queueMode is enabled or when called from a thread context, events are queued
	 * instead of streamed directly. Call drainQueue() from the main thread to flush.
	 * Errors are caught and logged to prevent client disconnects from interrupting test execution.
	 *
	 * @eventType The type of event (e.g., bundleStart, specEnd)
	 * @data      The data payload to send as JSON
	 */
	function streamEvent( required string eventType, required any data ){
		// Queue events when queueMode is enabled OR when called from a thread context
		if ( ( !isNull( variables.queueMode ) && variables.queueMode ) || variables.util.inThread() ) {
			queueEvent( arguments.eventType, arguments.data );
			return;
		}

		try {
			writeOutput( formatSSEEvent( arguments.eventType, arguments.data ) );
			// Only flush if enabled (disabled during unit testing to prevent response commit)
			if ( isNull( variables.flushEnabled ) || variables.flushEnabled ) {
				// cfflush moves data from the CFML output buffer to the Java response writer.
				// It may not be available in all BoxLang contexts, so we catch and fall through.
				cfflush(  );
			}
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
	 * Queue an event for later streaming
	 * This method is thread-safe and can be called from multiple threads concurrently.
	 *
	 * @eventType The type of event (e.g., specStart, specEnd)
	 * @data      The data payload to queue
	 */
	function queueEvent( required string eventType, required any data ){
		variables.eventQueue.add( {
			"eventType" : arguments.eventType,
			"data"      : arguments.data
		} );
	}

	/**
	 * Check if there are any queued events
	 *
	 * @return boolean True if there are events in the queue
	 */
	boolean function hasQueuedEvents(){
		return !variables.eventQueue.isEmpty();
	}

	/**
	 * Get all queued events without clearing the queue
	 * Returns events in FIFO order.
	 *
	 * @return array Array of event structs with eventType and data keys
	 */
	array function getQueuedEvents(){
		var events   = [];
		var iterator = variables.eventQueue.iterator();
		while ( iterator.hasNext() ) {
			events.append( iterator.next() );
		}
		return events;
	}

	/**
	 * Drain all queued events by streaming them to the client
	 * This method should be called from the main thread after async specs complete.
	 * The queue is cleared after draining.
	 *
	 * @return numeric The number of events that were drained
	 */
	numeric function drainQueue(){
		var count = 0;
		var event = variables.eventQueue.poll();

		while ( !isNull( event ) ) {
			try {
				writeOutput( formatSSEEvent( event.eventType, event.data ) );
				// Only flush if enabled (disabled during unit testing to prevent response commit)
				if ( isNull( variables.flushEnabled ) || variables.flushEnabled ) {
					cfflush(  );
				}
			} catch ( any e ) {
				// Client may have disconnected - log and continue draining
				try {
					writeLog(
						type = "information",
						file = "testbox-streaming",
						text = "StreamingService.drainQueue event failed: " & e.message
					);
				} catch ( any ignore ) {
					// Ignore logging errors
				}
			}
			count++;
			event = variables.eventQueue.poll();
		}

		return count;
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
			"onBundleStart" : ( target, testResults ) => {
				// Note: Bundle stats (including the id) are not yet created when onBundleStart fires.
				// We generate a deterministic id from the path so consumers can correlate
				// bundleStart with bundleEnd events.
				var targetMD    = getMetadata( target );
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
			"onBundleEnd" : ( target, testResults ) => {
				var targetMD = getMetadata( target );
				var bundleId = hash( targetMD.name );

				// Look up bundle stats by path (internal stats use a different id scheme)
				var bundleStats   = testResults.getBundleStats();
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
						"totalSkipped"  : current.totalSkipped,
						"debugBuffer"   : current.debugBuffer ?: []
					}
				);
			},
			"onSuiteStart" : ( target, testResults, suite ) => {
				var targetMD = getMetadata( target );
				service.streamEvent(
					"suiteStart",
					{
						"id"         : suite.id,
						"bundlePath" : targetMD.name,
						"name"       : suite.name,
						"timestamp"  : getTickCount()
					}
				);
			},
			"onSuiteEnd" : ( target, testResults, suite ) => {
				var targetMD   = getMetadata( target );
				var suiteStats = testResults.getSuiteStats( suite.id );
				service.streamEvent(
					"suiteEnd",
					{
						"id"            : suite.id,
						"bundlePath"    : targetMD.name,
						"name"          : suite.name,
						"totalDuration" : suiteStats.totalDuration,
						"totalSpecs"    : suiteStats.totalSpecs,
						"totalPass"     : suiteStats.totalPass,
						"totalFail"     : suiteStats.totalFail,
						"totalError"    : suiteStats.totalError,
						"totalSkipped"  : suiteStats.totalSkipped
					}
				);
			},
			"onSpecStart" : ( target, testResults, suite, spec ) => {
				var targetMD = getMetadata( target );
				service.streamEvent(
					"specStart",
					{
						"id"          : spec.id,
						"suiteId"     : suite.id,
						"bundlePath"  : targetMD.name,
						"name"        : spec.name,
						"displayName" : spec.displayName ?: spec.name,
						"timestamp"   : getTickCount()
					}
				);
			},
			"onSpecEnd" : ( target, testResults, suite, spec ) => {
				var targetMD    = getMetadata( target );
				var currentSpec = testResults.getSpecStats( spec.id );

				service.streamEvent(
					"specEnd",
					{
						"id"             : spec.id,
						"suiteId"        : suite.id,
						"bundlePath"     : targetMD.name,
						"name"           : spec.name,
						"displayName"    : spec.displayName ?: spec.name,
						"status"         : currentSpec.status ?: "unknown",
						"totalDuration"  : currentSpec.totalDuration ?: 0,
						"failMessage"    : currentSpec.failMessage ?: "",
						"failDetail"     : currentSpec.failDetail ?: "",
						"failStacktrace" : currentSpec.failStacktrace ?: "",
						"failOrigin"     : isArray( currentSpec.failOrigin ?: "" ) ? currentSpec.failOrigin : [],
						"error"          : currentSpec.error ?: {}
					}
				);
			},
			/**
			 * Drain any queued events from async spec execution
			 * This callback should be called by the runner after thread joins to flush
			 * any events that were queued from thread contexts.
			 */
			"onAsyncDrain" : () => {
				service.drainQueue();
			}
		};
	}

}
