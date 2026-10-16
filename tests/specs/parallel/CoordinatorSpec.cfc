component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Parallel coordinator contract", function(){
			it( "attributes interleaved events and emits one final result after cleanup", function(){
				var provider    = new tests.parallel.FakeWorkers();
				var events      = [];
				var coordinator = new testbox.system.parallel.Coordinator( provider )
				var result      = coordinator.run(
					[ "tests.One", "tests.Two" ],
					2,
					{},
					function( type, data ){
						events.append( { "type" : type, "data" : duplicate( data ) } );
					}
				);
				expect( result.passed ).toBeTrue();
				expect( result.totalPass ).toBe( 2 );
				expect( events[ 1 ].data.workerBundleCounts.toList() ).toBe( "1,1" );
				expect( provider.stopped.len() ).toBe( 2 );
				expect( provider.finished ).toBeTrue();
				expect(
					events
						.filter( function( e ){
							return e.type == "testRunEnd";
						} )
						.len()
				).toBe( 1 );
				expect(
					events
						.filter( function( e ){
							return e.type == "specEnd";
						} )
						.map( function( e ){
							return e.data.workerId;
						} )
						.toList()
				).toBe( "1,2" );
				for ( var i = 1; i <= events.len(); i++ ) {
					expect( events[ i ].data.sequence ).toBe( i );
				}
			} );
			it( "still cleans up owned workers after an observer disconnects", function(){
				var provider    = new tests.parallel.FakeWorkers();
				var coordinator = new testbox.system.parallel.Coordinator( provider )
				var result      = coordinator.run(
					[ "tests.One", "tests.Two" ],
					2,
					{},
					function( type, data ){
						if ( type == "workerStart" ) {
							throw( message = "Client disconnected" );
						}
					}
				);
				expect( result.parallel.cancelled ).toBeTrue();
				expect( provider.stopped.len() ).toBe( provider.started.len() );
				expect( provider.finished ).toBeTrue();
			} );
			it( "treats cancellation as incomplete execution instead of an assertion failure", function(){
				var result = new testbox.system.parallel.Coordinator( new tests.parallel.FakeWorkers( "cancel" ) ).run(
					[ "tests.One", "tests.Two" ],
					2
				);
				expect( result.parallel.cancelled ).toBeTrue();
				expect( result.passed ).toBeFalse();
				expect( result.totalError ).toBe( 0 );
			} );
			it( "retains per-worker timings and run throughput in the final results", function(){
				var result = new testbox.system.parallel.Coordinator( new tests.parallel.FakeWorkers() ).run(
					[ "tests.One", "tests.Two", "tests.Three" ],
					2
				);
				expect( result.passed ).toBeTrue();
				expect( result.parallel.timing.reportedWorkers ).toBe( 2 );
				expect( result.parallel.timing.specsPerSecond ).toBeGT( 0 );
				expect( result.parallel.timing.preparationMilliseconds ).toBeGTE( 0 );
				expect( result.parallel.timing.cleanupMilliseconds ).toBeGTE( 0 );
				var bundleCount = 0;
				var workerIds   = [];
				for ( var worker in result.parallel.workerStats ) {
					workerIds.append( worker.workerId );
					bundleCount += worker.assignedBundles;
					expect( worker.wallMilliseconds ).toBeGT( 0 );
					expect( worker.wallMilliseconds ).toBeLTE( result.parallel.wallMilliseconds );
					expect( worker.report.totalSpecs ).toBe( worker.assignedBundles );
				}
				expect( bundleCount ).toBe( 3 );
				expect( workerIds.toList() ).toBe( "1,2" );
			} );
			it( "rejects duplicate selections before provisioning", function(){
				var provider = new tests.parallel.FakeWorkers();
				expect( function(){
					new testbox.system.parallel.Coordinator( provider ).run( [ "tests.One", "tests.One" ], 2 );
				} ).toThrow();
				expect( provider.started.len() ).toBe( 0 );
			} );
			for ( var scenario in [ "startup", "coverage", "cleanup", "cancel" ] ) {
				it(
					title = "fails the run and cleans up when " & scenario & " occurs",
					body  = function( data ){
						var provider = new tests.parallel.FakeWorkers( data.scenario );
						var result   = new testbox.system.parallel.Coordinator( provider ).run(
							[ "tests.One", "tests.Two" ],
							2
						);
						expect( result.passed ).toBeFalse();
						expect( provider.stopped.len() ).toBe( provider.started.len() );
						expect( provider.finished ).toBeTrue();
					},
					data = { "scenario" : scenario }
				);
			}
		} );
	}

}
