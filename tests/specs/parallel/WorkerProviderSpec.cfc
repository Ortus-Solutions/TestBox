component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Worker provider integration", function(){
			it( "adapts an existing environment helper using three functions", function(){
				var helper   = new tests.parallel.FakeWorkers()
				var adapters = {
					"start" : function( context ){
						return helper.startWorker( context )
					},
					"poll" : function( handle ){
						return helper.pollWorker( handle )
					},
					"stop" : function( handle ){
						helper.stopWorker( handle )
					}
				}
				var provider = new testbox.system.parallel.WorkerProvider( argumentCollection = adapters )
				var result   = new testbox.system.parallel.Coordinator( provider ).run(
					[ "tests.One", "tests.Two" ],
					2
				)
				expect( result.passed ).toBeTrue()
				expect( helper.started.len() ).toBe( 2 )
				expect( helper.stopped.len() ).toBe( 2 )
			} )
			it( "refuses to run without an environment implementation", function(){
				expect( function(){
					new testbox.system.parallel.WorkerProvider().startWorker( {} )
				} ).toThrow()
				expect( function(){
					new testbox.system.parallel.WorkerProvider( start = "url" )
				} ).toThrow()
			} )
			it( "forwards configured labels and excludes through the programmatic entry point", function(){
				var helper   = new tests.parallel.FakeWorkers()
				var filters  = {}
				var adapters = {
					"start" : function( context ){
						filters = context.run.filters;
						return helper.startWorker( context )
					},
					"poll" : function( handle ){
						return helper.pollWorker( handle )
					},
					"stop" : function( handle ){
						helper.stopWorker( handle )
					}
				}
				var provider = new testbox.system.parallel.WorkerProvider( argumentCollection = adapters )
				var result   = new testbox.system.TestBox(
					bundles  = "tests.One",
					labels   = "unit",
					excludes = "slow"
				).runParallel( provider )
				expect( result.passed ).toBeTrue()
				expect( filters.labels ).toBe( "unit" )
				expect( filters.excludes ).toBe( "slow" )
			} )
		} )
	}

}
