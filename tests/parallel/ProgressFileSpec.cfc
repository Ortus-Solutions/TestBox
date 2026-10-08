component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Worker progress transport", function(){
			it( "publishes the whole bundle's recursive spec count when suites are declared", function(){
				var path = getTempDirectory() & createUUID() & ".jsonl";
				fileWrite( path, "" );
				try {
					var target     = new tests.parallel.FakeWorkers();
					target.$suites = [
						{
							"id"     : "outer",
							"name"   : "Outer",
							"specs"  : [ {}, {} ],
							"suites" : [ { "specs" : [ {} ], "suites" : [] } ]
						},
						{
							"id"     : "second",
							"name"   : "Second",
							"specs"  : [ {} ],
							"suites" : []
						}
					];
					var callbacks = new testbox.system.parallel.ProgressFile( path ).createStreamingCallbacks();
					callbacks.onSuiteStart( target, {}, target.$suites[ 1 ] );
					var event = deserializeJSON( trim( fileRead( path ) ) );
					expect( event.type ).toBe( "suiteStart" );
					expect( event.data.bundleTotalSpecs ).toBe( 4 );
					expect( event.data.bundlePath ).toInclude( "FakeWorkers" );
				} finally {
					fileDelete( path );
				}
			} );
			it( "bounds diagnostics and excludes application objects and debug buffers", function(){
				var path = getTempDirectory() & createUUID() & ".jsonl";
				fileWrite( path, "" );
				try {
					var transport = new testbox.system.parallel.ProgressFile( path );
					transport.streamEvent(
						"specEnd",
						{
							"name"        : "Unicode café",
							"status"      : "Failed",
							"failMessage" : repeatString( "x", 9000 ),
							"debugBuffer" : [ new tests.parallel.FakeWorkers() ],
							"error"       : {
								"message"     : "Bounded error",
								"application" : new tests.parallel.FakeWorkers()
							}
						}
					);
					var event = deserializeJSON( trim( fileRead( path, "UTF-8" ) ) );
					expect( event.data.name ).toBe( "Unicode café" );
					expect( event.data.failMessage.len() ).toBe( 8192 );
					expect( event.data.errorMessage ).toBe( "Bounded error" );
					expect( event.data.keyExists( "debugBuffer" ) ).toBeFalse();
					expect( event.data.keyExists( "error" ) ).toBeFalse();
				} finally {
					fileDelete( path );
				}
			} );
		} );
	}

}
