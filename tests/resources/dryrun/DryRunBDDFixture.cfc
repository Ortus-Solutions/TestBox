component extends="testbox.system.BaseSpec" labels="componentLabel" {

	function beforeAll(){
		request.dryRunBDDBeforeAll = ( request.dryRunBDDBeforeAll ?: 0 ) + 1;
	}

	function afterAll(){
		request.dryRunBDDAfterAll = ( request.dryRunBDDAfterAll ?: 0 ) + 1;
	}

	function run(){
		describe( title = "Runnable Suite", body = function(){
			beforeEach( function(){
				request.dryRunBDDBeforeEach = ( request.dryRunBDDBeforeEach ?: 0 ) + 1;
			} );

			afterEach( function(){
				request.dryRunBDDAfterEach = ( request.dryRunBDDAfterEach ?: 0 ) + 1;
			} );

			it( title = "Runnable Spec", body = function(){
				request.dryRunBDDSpecRuns = ( request.dryRunBDDSpecRuns ?: 0 ) + 1;
			}, labels = "specLabel" );

			xit( title = "Skipped Spec", body = function(){
				request.dryRunBDDSkippedSpecRuns = ( request.dryRunBDDSkippedSpecRuns ?: 0 ) + 1;
			}, labels = "skipLabel" );
		}, labels = "suiteLabel" );
	}

}