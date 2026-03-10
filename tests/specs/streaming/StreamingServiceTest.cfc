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

					expect( isClosure( callbacks.onBundleStart ) ).toBeTrue();
					expect( isClosure( callbacks.onBundleEnd ) ).toBeTrue();
					expect( isClosure( callbacks.onSuiteStart ) ).toBeTrue();
					expect( isClosure( callbacks.onSuiteEnd ) ).toBeTrue();
					expect( isClosure( callbacks.onSpecStart ) ).toBeTrue();
					expect( isClosure( callbacks.onSpecEnd ) ).toBeTrue();
				} );
			} );

			describe( "SSE event format", function(){
				it( "streamEvent produces correct SSE format string", function(){
					// Disable flushing to prevent response commit during testing
					variables.streamingService.setFlushEnabled( false );

					// Capture the actual output from streamEvent using savecontent
					var eventType = "testEvent";
					var data      = { "key" : "value" };
					var output    = "";

					savecontent variable="output" {
						variables.streamingService.streamEvent( eventType, data );
					}

					// Verify SSE format: event: <type>\ndata: <json>\n\n
					expect( output ).toInclude( "event: testEvent" );
					expect( output ).toInclude( "data: " );
					// Verify it ends with double newline
					expect( right( output, 2 ) ).toBe( chr( 10 ) & chr( 10 ) );
				} );

				it( "streamEvent serializes complex data to JSON correctly", function(){
					// Disable flushing to prevent response commit during testing
					variables.streamingService.setFlushEnabled( false );

					var testData = {
						"id"       : "test-123",
						"name"     : "Test Spec",
						"nested"   : { "foo" : "bar" },
						"arrayVal" : [ 1, 2, 3 ]
					};
					var output = "";

					savecontent variable="output" {
						variables.streamingService.streamEvent( "testEvent", testData );
					}

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
					var mockResults = createMock( "testbox.system.TestResult" );

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
					var mockResults = createMock( "testbox.system.TestResult" );

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
					var mockResults = createMock( "testbox.system.TestResult" );
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
					var mockResults = createMock( "testbox.system.TestResult" );
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
					var mockResults = createMock( "testbox.system.TestResult" );
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
					var mockResults = createMock( "testbox.system.TestResult" );
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };
					var mockSpec    = {
						"id"          : "spec-456",
						"name"        : "should do something",
						"displayName" : "should do something"
					};

					var suiteStats = {
						"specStats" : [
							{
								"id"             : "spec-456",
								"status"         : "passed",
								"totalDuration"  : 10,
								"failMessage"    : "",
								"failDetail"     : "",
								"failStacktrace" : "",
								"failOrigin"     : {},
								"error"          : {}
							}
						]
					};
					mockResults.$( "getSuiteStats", suiteStats );

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
					var mockResults = createMock( "testbox.system.TestResult" );
					var mockSuite   = { "id" : "suite-123", "name" : "Test Suite" };
					var mockSpec    = {
						"id"          : "spec-789",
						"name"        : "should fail gracefully",
						"displayName" : "should fail gracefully"
					};

					var suiteStats = {
						"specStats" : [
							{
								"id"             : "spec-789",
								"status"         : "failed",
								"totalDuration"  : 15,
								"failMessage"    : "Expected true but got false",
								"failDetail"     : "Assertion failed",
								"failStacktrace" : "at line 42",
								"failOrigin"     : { "template" : "test.cfc", "line" : 42 },
								"error"          : {}
							}
						]
					};
					mockResults.$( "getSuiteStats", suiteStats );

					var callbacks = variables.mockService.createStreamingCallbacks();
					callbacks.onSpecEnd( mockTarget, mockResults, mockSuite, mockSpec );

					var callLog = variables.mockService.$callLog().streamEvent;
					expect( callLog[ 1 ][ 1 ] ).toBe( "specEnd" );
					expect( callLog[ 1 ][ 2 ].status ).toBe( "failed" );
					expect( callLog[ 1 ][ 2 ].failMessage ).toBe( "Expected true but got false" );
					expect( callLog[ 1 ][ 2 ].failOrigin ).toHaveKey( "template" );
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
						expect( isClosure( callbacks[ callbackName ] ) ).toBeTrue(
							"#callbackName# should be a closure"
						);
					}
				} );
			} );
		} );
	}

}
