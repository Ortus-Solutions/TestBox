/**
 * Fixture used to verify that a BDD bundle marked with a component-level
 * `skip` annotation is excluded from the dry-run discovery tree and from
 * the live runner's execution.
 *
 * `skip="true"` is always truthy regardless of the runtime so the test
 * remains deterministic on every supported engine.
 */
component extends="testbox.system.BaseSpec" skip="true" {

	function beforeAll(){
		request.dryRunBDDSkippedBeforeAll = ( request.dryRunBDDSkippedBeforeAll ?: 0 ) + 1;
	}

	function afterAll(){
		request.dryRunBDDSkippedAfterAll = ( request.dryRunBDDSkippedAfterAll ?: 0 ) + 1;
	}

	function run(){
		describe( title = "Skipped Suite", body = function(){
			it( title = "Skipped Spec", body = function(){
				request.dryRunBDDSkippedSpecRuns = ( request.dryRunBDDSkippedSpecRuns ?: 0 ) + 1;
			} );
		} );
	}

}
