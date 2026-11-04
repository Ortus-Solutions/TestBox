component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Reusable parallel HTTP runner", function(){
			beforeEach( function(){
				variables.storage = getTempDirectory() & "testbox-runner-contract-" & createUUID();
				variables.runner  = new testbox.system.parallel.Runner(
					provider    = new tests.parallel.FakeWorkers(),
					directory   = "tests.parallel.fixtures",
					storageRoot = variables.storage,
					maxWorkers  = 8
				);
			} );
			afterEach( function(){
				if ( directoryExists( variables.storage ) ) {
					directoryDelete( variables.storage, true );
				}
			} );
			it( "discovers without provisioning and bounds targeted runs to the selected bundle count", function(){
				var selection = variables.runner.selection( { "workers" : 8 } );
				expect( selection.workers ).toBe( 2 );
				expect( selection.bundles.len() ).toBe( 2 );
				var discovered = selection.testbox.dryRun();
				expect( discovered.summary.totalSpecs ).toBe( 2 );
				expect(
					variables.runner.selection( {
						"workers"   : 4,
						"directory" : "",
						"bundles"   : "tests.parallel.fixtures.OneSpec"
					} ).workers
				).toBe( 1 );
			} );
			it( "rejects paths, duplicate or unknown bundles and invalid concurrency before provisioning", function(){
				for (
					var options in [
						{ "directory" : "tests.specs" },
						{ "directory" : "tests.parallel.fixtures../other" },
						{ "bundles" : "tests.parallel.fixtures.OneSpec,tests.parallel.fixtures.OneSpec" },
						{ "bundles" : "app.models.User" },
						{ "workers" : 0 },
						{ "workers" : -1 },
						{ "workers" : 1.5 },
						{ "workers" : 9 },
						{ "workers" : "four" },
						{ "coverageEnabled" : true }
					]
				) {
					expect( function(){
						variables.runner.selection( options );
					} ).toThrow();
				}
			} );
			it( "claims identities once, scopes cancellation and retains evidence outside the provider environment", function(){
				var id      = lCase( replace( createUUID(), "-", "", "all" ) );
				var context = variables.runner.claim( id );
				expect( directoryExists( context.output ) ).toBeFalse();
				expect( variables.runner.cancel( id ) ).toBeTrue();
				expect( fileExists( context.cancellationFile ) ).toBeTrue();
				expect( function(){
					variables.runner.claim( id );
				} ).toThrow();
				expect( function(){
					variables.runner.runDirectory( "../../escape" );
				} ).toThrow();
				fileWrite( variables.runner.runDirectory( id ) & "/summary.json", "{}" );
				expect( variables.runner.cancel( id ) ).toBeFalse();
				expect( variables.runner.cancel( repeatString( "a", 32 ) ) ).toBeFalse();
			} );
		} );
	}

}
