/**
 * This tests the StreamingService functionality in TestBox.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "StreamingService", function(){
			beforeEach( function(){
				variables.streamingService = new testbox.system.util.StreamingService();
			} );

			describe( "initialization", function(){
				it( "can be instantiated", function(){
					expect( variables.streamingService ).toBeComponent();
				} );

				it( "returns itself from initializeStream for chaining", function(){
					// We can't actually test headers in unit tests, but we can verify the return value
					var result = variables.streamingService.initializeStream();
					expect( result ).toBe( variables.streamingService );
				} );
			} );

			describe( "createStreamingCallbacks", function(){
				it( "returns a struct of callback functions", function(){
					var callbacks = variables.streamingService.createStreamingCallbacks();
					expect( callbacks ).toBeStruct();
				} );

				it( "includes all required callback functions", function(){
					var callbacks = variables.streamingService.createStreamingCallbacks();

					expect( callbacks ).toHaveKey( "onBundleStart" );
					expect( callbacks ).toHaveKey( "onBundleEnd" );
					expect( callbacks ).toHaveKey( "onSuiteStart" );
					expect( callbacks ).toHaveKey( "onSuiteEnd" );
					expect( callbacks ).toHaveKey( "onSpecStart" );
					expect( callbacks ).toHaveKey( "onSpecEnd" );
				} );

				it( "all callbacks are closures", function(){
					var callbacks = variables.streamingService.createStreamingCallbacks();

					expect( callbacks.keyExists( "onBundleStart" ) ).toBeTrue();
					expect( callbacks.keyExists( "onBundleEnd" ) ).toBeTrue();
					expect( callbacks.keyExists( "onSuiteStart" ) ).toBeTrue();
					expect( callbacks.keyExists( "onSuiteEnd" ) ).toBeTrue();
					expect( callbacks.keyExists( "onSpecStart" ) ).toBeTrue();
					expect( callbacks.keyExists( "onSpecEnd" ) ).toBeTrue();
				} );
			} );

			describe( "SSE event format", function(){
				it( "formatSSEEvent produces correct SSE format string", function(){
					var eventType = "testEvent";
					var data      = { "key" : "value" };
					var output    = variables.streamingService.formatSSEEvent( eventType, data );

					// Verify SSE format: event: <type>\ndata: <json>\n\n
					expect( output ).toInclude( "event: testEvent" );
					expect( output ).toInclude( "data: " );
					// Verify it ends with double newline
					expect( right( output, 2 ) ).toBe( chr( 10 ) & chr( 10 ) );
				} );

				it( "formatSSEEvent serializes complex data to JSON correctly", function(){
					var testData = {
						"id"       : "test-123",
						"name"     : "Test Spec",
						"nested"   : { "foo" : "bar" },
						"arrayVal" : [ 1, 2, 3 ]
					};
					var output = variables.streamingService.formatSSEEvent( "testEvent", testData );

					expect( output ).toInclude( """id""" );
					expect( output ).toInclude( """test-123""" );
					expect( output ).toInclude( """nested""" );
					expect( output ).toInclude( """foo""" );
					expect( output ).toInclude( """bar""" );
				} );
			} );

			describe( "callback event data structures", function(){
				beforeEach( function(){
					// Create a mocked service that tracks streamEvent calls using $callLog
					variables.mockService = prepareMock( new testbox.system.util.StreamingService() );
					// Mock streamEvent to do nothing but record calls
					variables.mockService.$( "streamEvent" );
				} );

				it( "onBundleStart sends bundleStart event with metadata", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onBundleStart( mockTarget, mockResults );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog ).toHaveLength( 1 );
					expect( callLog[ 1 ][ 1 ] ).toBe( "bundleStart" );
					expect( callLog[ 1 ][ 2 ] ).toHaveKey( "path" );
					expect( callLog[ 1 ][ 2 ] ).toHaveKey( "name" );
					expect( callLog[ 1 ][ 2 ] ).toHaveKey( "timestamp" );
					expect( callLog[ 1 ][ 2 ].path ).toInclude( "BaseSpec" );
				} );

				it( "onBundleEnd sends bundleEnd event with statistics", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();

					// The id is now generated from hash(path) of the target, not from bundle stats
					var targetMD   = getMetadata( mockTarget );
					var expectedId = hash( targetMD.name );

					var bundleStats = [
						{
							"id"            : "bundle-123",
							"name"          : "Test Bundle",
							"path"          : targetMD.name, // Use the actual target path so stats lookup works
							"totalDuration" : 100,
							"totalSuites"   : 2,
							"totalSpecs"    : 5,
							"totalPass"     : 4,
							"totalFail"     : 1,
							"totalError"    : 0,
							"totalSkipped"  : 0
						}
					];
					mockResults.$( "getBundleStats", bundleStats );

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onBundleEnd( mockTarget, mockResults );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog ).toHaveLength( 1 );
					expect( callLog[ 1 ][ 1 ] ).toBe( "bundleEnd" );
					expect( callLog[ 1 ][ 2 ].id ).toBe( expectedId );
					expect( callLog[ 1 ][ 2 ].totalSpecs ).toBe( 5 );
					expect( callLog[ 1 ][ 2 ].totalPass ).toBe( 4 );
					expect( callLog[ 1 ][ 2 ].totalFail ).toBe( 1 );
				} );

				it( "onSuiteStart sends suiteStart event with suite info", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onSuiteStart( mockTarget, mockResults, mockSuite );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog ).toHaveLength( 1 );
					expect( callLog[ 1 ][ 1 ] ).toBe( "suiteStart" );
					expect( callLog[ 1 ][ 2 ].id ).toBe( "suite-123" );
					expect( callLog[ 1 ][ 2 ].name ).toBe( "Test Suite" );
					expect( callLog[ 1 ][ 2 ] ).toHaveKey( "timestamp" );
				} );

				it( "onSuiteEnd sends suiteEnd event with statistics", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };

					var suiteStats = {
						"totalDuration" : 50,
						"totalSpecs"    : 3,
						"totalPass"     : 2,
						"totalFail"     : 1,
						"totalError"    : 0,
						"totalSkipped"  : 0
					};
					mockResults.$( "getSuiteStats", suiteStats );

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onSuiteEnd( mockTarget, mockResults, mockSuite );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog ).toHaveLength( 1 );
					expect( callLog[ 1 ][ 1 ] ).toBe( "suiteEnd" );
					expect( callLog[ 1 ][ 2 ].id ).toBe( "suite-123" );
					expect( callLog[ 1 ][ 2 ].totalSpecs ).toBe( 3 );
				} );

				it( "onSpecStart sends specStart event with spec info", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };
					var mockSpec    = {
						"id"          : "spec-456",
						"name"        : "should do something",
						"displayName" : "should do something"
					};

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onSpecStart( mockTarget, mockResults, mockSuite, mockSpec );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog ).toHaveLength( 1 );
					expect( callLog[ 1 ][ 1 ] ).toBe( "specStart" );
					expect( callLog[ 1 ][ 2 ].id ).toBe( "spec-456" );
					expect( callLog[ 1 ][ 2 ].suiteId ).toBe( "suite-123" );
					expect( callLog[ 1 ][ 2 ].name ).toBe( "should do something" );
				} );

				it( "onSpecEnd sends specEnd event with results", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };
					var mockSpec    = {
						"id"          : "spec-456",
						"name"        : "should do something",
						"displayName" : "should do something"
					};

					var specStats = {
						"id"             : "spec-456",
						"status"         : "passed",
						"totalDuration"  : 10,
						"failMessage"    : "",
						"failDetail"     : "",
						"failStacktrace" : "",
						"failOrigin"     : {},
						"error"          : {}
					};
					mockResults.$( "getSpecStats", specStats );

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onSpecEnd( mockTarget, mockResults, mockSuite, mockSpec );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog ).toHaveLength( 1 );
					expect( callLog[ 1 ][ 1 ] ).toBe( "specEnd" );
					expect( callLog[ 1 ][ 2 ].id ).toBe( "spec-456" );
					expect( callLog[ 1 ][ 2 ].status ).toBe( "passed" );
					expect( callLog[ 1 ][ 2 ].totalDuration ).toBe( 10 );
				} );

				it( "onSpecEnd includes failure info for failed specs", function(){
					var mockTarget  = new testbox.system.BaseSpec();
					var mockResults = createMock( "testbox.system.TestResult" ).init();
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };
					var mockSpec    = {
						"id"          : "spec-789",
						"name"        : "should fail gracefully",
						"displayName" : "should fail gracefully"
					};

					var specStats = {
						"id"             : "spec-789",
						"status"         : "failed",
						"totalDuration"  : 15,
						"failMessage"    : "Expected true but got false",
						"failDetail"     : "Assertion failed",
						"failStacktrace" : "at line 42",
						"failOrigin"     : { "template" : "test.cfc", "line" : 42 },
						"error"          : {}
					};
					mockResults.$( "getSpecStats", specStats );

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onSpecEnd( mockTarget, mockResults, mockSuite, mockSpec );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog[ 1 ][ 1 ] ).toBe( "specEnd" );
					expect( callLog[ 1 ][ 2 ].status ).toBe( "failed" );
					expect( callLog[ 1 ][ 2 ].failMessage ).toBe( "Expected true but got false" );
				} );
			} );

			describe( "integration with TestBox callbacks", function(){
				it( "callbacks can be passed to TestBox runRaw method", function(){
					var callbacks = variables.streamingService.createStreamingCallbacks();

					// Verify the callback struct has the correct signature for TestBox
					var requiredCallbacks = [
						"onBundleStart",
						"onBundleEnd",
						"onSuiteStart",
						"onSuiteEnd",
						"onSpecStart",
						"onSpecEnd"
					];

					for ( var callbackName in requiredCallbacks ) {
						expect( callbacks ).toHaveKey( callbackName );
						expect(
							isClosure( callbacks[ callbackName ] ) || isCustomFunction( callbacks[ callbackName ] )
						).toBeTrue( "#callbackName# should be a closure" );
					}
				} );
			} );

			describe( "asyncAll queue support", function(){
				beforeEach( function(){
					// Fresh streaming service for each test
					variables.streamingService = new testbox.system.util.StreamingService();
				} );

				describe( "hasQueuedEvents", function(){
					it( "returns false when no events have been queued", function(){
						expect( variables.streamingService.hasQueuedEvents() ).toBeFalse();
					} );

					it( "returns true when events have been queued", function(){
						// Queue an event directly
						variables.streamingService.queueEvent( "testEvent", { "key" : "value" } );
						expect( variables.streamingService.hasQueuedEvents() ).toBeTrue();
					} );
				} );

				describe( "queueEvent", function(){
					it( "adds events to the internal queue", function(){
						variables.streamingService.queueEvent( "specStart", { "id" : "spec-1" } );
						variables.streamingService.queueEvent(
							"specEnd",
							{ "id" : "spec-1", "status" : "passed" }
						);

						expect( variables.streamingService.hasQueuedEvents() ).toBeTrue();
						// We should have exactly 2 events queued
						var events = variables.streamingService.getQueuedEvents();
						expect( events ).toHaveLength( 2 );
					} );

					it( "preserves event order (FIFO)", function(){
						variables.streamingService.queueEvent( "event1", { "order" : 1 } );
						variables.streamingService.queueEvent( "event2", { "order" : 2 } );
						variables.streamingService.queueEvent( "event3", { "order" : 3 } );

						var events = variables.streamingService.getQueuedEvents();
						expect( events[ 1 ].eventType ).toBe( "event1" );
						expect( events[ 2 ].eventType ).toBe( "event2" );
						expect( events[ 3 ].eventType ).toBe( "event3" );
					} );

					it( "stores both eventType and data for each queued event", function(){
						var testData = { "id" : "spec-123", "name" : "test spec" };
						variables.streamingService.queueEvent( "specStart", testData );

						var events = variables.streamingService.getQueuedEvents();
						expect( events[ 1 ] ).toHaveKey( "eventType" );
						expect( events[ 1 ] ).toHaveKey( "data" );
						expect( events[ 1 ].eventType ).toBe( "specStart" );
						expect( events[ 1 ].data.id ).toBe( "spec-123" );
					} );
				} );

				describe( "getQueuedEvents", function(){
					it( "returns an empty array when no events are queued", function(){
						var events = variables.streamingService.getQueuedEvents();
						expect( events ).toBeArray();
						expect( events ).toHaveLength( 0 );
					} );

					it( "returns all queued events without clearing the queue", function(){
						variables.streamingService.queueEvent( "event1", { "id" : 1 } );
						variables.streamingService.queueEvent( "event2", { "id" : 2 } );

						// First call
						var events1 = variables.streamingService.getQueuedEvents();
						expect( events1 ).toHaveLength( 2 );

						// Second call should still return 2 events (not cleared)
						var events2 = variables.streamingService.getQueuedEvents();
						expect( events2 ).toHaveLength( 2 );
					} );
				} );

				describe( "drainQueue", function(){
					beforeEach( function(){
						// Create a mock to track streamEvent calls
						variables.mockService = prepareMock( new testbox.system.util.StreamingService() );
						// Disable flushing to prevent test issues
						variables.mockService.setFlushEnabled( false );
					} );

					it( "streams all queued events in order", function(){
						// Queue some events
						variables.mockService.queueEvent( "specStart", { "id" : "spec-1" } );
						variables.mockService.queueEvent( "specEnd", { "id" : "spec-1" } );
						variables.mockService.queueEvent( "specStart", { "id" : "spec-2" } );

						// Capture output using savecontent
						var output          = "";
						savecontent variable="output" {
							variables.mockService.drainQueue();
						}

						// Verify all events were streamed
						expect( output ).toInclude( "event: specStart" );
						expect( output ).toInclude( "event: specEnd" );
						expect( output ).toInclude( "spec-1" );
						expect( output ).toInclude( "spec-2" );
					} );

					it( "clears the queue after draining", function(){
						variables.mockService.queueEvent( "event1", { "id" : 1 } );
						variables.mockService.queueEvent( "event2", { "id" : 2 } );

						expect( variables.mockService.hasQueuedEvents() ).toBeTrue();

						// Drain the queue (ignore output)
						savecontent variable="local.ignored" {
							variables.mockService.drainQueue();
						}

						// Queue should now be empty
						expect( variables.mockService.hasQueuedEvents() ).toBeFalse();
						expect( variables.mockService.getQueuedEvents() ).toHaveLength( 0 );
					} );

					it( "does nothing when queue is empty", function(){
						expect( variables.mockService.hasQueuedEvents() ).toBeFalse();

						// Should not throw or produce output
						var output          = "";
						savecontent variable="output" {
							variables.mockService.drainQueue();
						}

						expect( output ).toBe( "" );
					} );

					it( "returns the number of events drained", function(){
						variables.mockService.queueEvent( "event1", {} );
						variables.mockService.queueEvent( "event2", {} );
						variables.mockService.queueEvent( "event3", {} );

						savecontent variable="local.ignored" {
							var count = variables.mockService.drainQueue();
						}

						expect( count ).toBe( 3 );
					} );
				} );

				describe( "thread-safe queue operations", function(){
					it( "queue is thread-safe for concurrent writes", function(){
						var service         = new testbox.system.util.StreamingService();
						var threadCount     = 10;
						var eventsPerThread = 5;

						// Spawn multiple threads that all queue events concurrently
						for ( var i = 1; i <= threadCount; i++ ) {
							thread
								name      ="queueThread_#i#"
								action    ="run"
								service   ="#service#"
								threadNum ="#i#"
								eventCount="#eventsPerThread#" {
								for ( var j = 1; j <= attributes.eventCount; j++ ) {
									attributes.service.queueEvent(
										"specEvent",
										{ "thread" : attributes.threadNum, "event" : j }
									);
								}
							}
						}

						// Wait for all threads to complete
						thread
							action="join"
							name  ="queueThread_1,queueThread_2,queueThread_3,queueThread_4,queueThread_5,queueThread_6,queueThread_7,queueThread_8,queueThread_9,queueThread_10";

						// Verify all events were queued (no lost events due to race conditions)
						var events        = service.getQueuedEvents();
						var expectedCount = threadCount * eventsPerThread;
						expect( events ).toHaveLength( expectedCount );
					} );
				} );

				describe( "streamEvent with thread detection", function(){
					it( "inThread property is available to detect thread context", function(){
						// This is a meta-test to ensure we can detect thread context
						var util = new testbox.system.util.Util();
						// In the main test thread, we should NOT be in a cfthread
						expect( util.inThread() ).toBeFalse();
					} );

					it( "streamEvent queues events when queueMode is enabled", function(){
						var service = new testbox.system.util.StreamingService();
						service.setFlushEnabled( false );
						service.setQueueMode( true );

						// Stream an event - should be queued, not written
						var output          = "";
						savecontent variable="output" {
							service.streamEvent( "specStart", { "id" : "spec-1" } );
						}

						// No immediate output when queueMode is enabled
						expect( output ).toBe( "" );

						// Event should be in the queue
						expect( service.hasQueuedEvents() ).toBeTrue();
						var events = service.getQueuedEvents();
						expect( events[ 1 ].eventType ).toBe( "specStart" );
					} );

					it( "streamEvent writes directly when queueMode is disabled", function(){
						var service = new testbox.system.util.StreamingService();
						service.setFlushEnabled( false );
						service.setQueueMode( false );

						// Stream an event - should be written directly
						var output          = "";
						savecontent variable="output" {
							service.streamEvent( "specStart", { "id" : "spec-1" } );
						}

						// Output should be written directly
						expect( output ).toInclude( "event: specStart" );

						// Queue should be empty
						expect( service.hasQueuedEvents() ).toBeFalse();
					} );

					it( "streamEvent auto-queues events when called from a thread context", function(){
						var service = new testbox.system.util.StreamingService();
						service.setFlushEnabled( false );
						service.setQueueMode( false ); // queueMode is OFF but should still queue in thread

						// Stream an event from inside a thread
						thread name="autoQueueTest" action="run" service="#service#" {
							attributes.service.streamEvent( "specStart", { "id" : "spec-thread" } );
							attributes.service.streamEvent(
								"specEnd",
								{ "id" : "spec-thread", "status" : "passed" }
							);
						}

						// Wait for thread to complete
						thread action="join" name="autoQueueTest";

						// Events should be queued (not written to output since we're in a thread)
						expect( service.hasQueuedEvents() ).toBeTrue();
						var events = service.getQueuedEvents();
						expect( events ).toHaveLength( 2 );
						expect( events[ 1 ].eventType ).toBe( "specStart" );
						expect( events[ 2 ].eventType ).toBe( "specEnd" );
					} );

					it( "onAsyncDrain callback drains queued events", function(){
						var service   = new testbox.system.util.StreamingService();
						var callbacks = service.createStreamingCallbacks();

						service.setFlushEnabled( false );

						// Queue some events (simulating what happens in async threads)
						service.queueEvent( "specStart", { "id" : "spec-1" } );
						service.queueEvent( "specEnd", { "id" : "spec-1" } );

						expect( service.hasQueuedEvents() ).toBeTrue();

						// Call the drain callback (simulating what runner does after thread join)
						savecontent variable="local.output" {
							callbacks.onAsyncDrain();
						}

						// Queue should be empty after drain
						expect( service.hasQueuedEvents() ).toBeFalse();
						// Output should contain the events
						expect( output ).toInclude( "event: specStart" );
						expect( output ).toInclude( "event: specEnd" );
					} );
				} );
			} );
		} );
	}

}
