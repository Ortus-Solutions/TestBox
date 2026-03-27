component extends="testbox.system.BaseSpec" labels="componentLabel" {

	function beforeTests(){
		request.dryRunXBeforeTests = ( request.dryRunXBeforeTests ?: 0 ) + 1;
	}

	function setup(){
		request.dryRunXSetup = ( request.dryRunXSetup ?: 0 ) + 1;
	}

	function teardown(){
		request.dryRunXTeardown = ( request.dryRunXTeardown ?: 0 ) + 1;
	}

	function afterTests(){
		request.dryRunXAfterTests = ( request.dryRunXAfterTests ?: 0 ) + 1;
	}

	function testRunnable() labels="methodLabel" {
		request.dryRunXSpecRuns = ( request.dryRunXSpecRuns ?: 0 ) + 1;
	}

	function testSkipped() skip labels="skipLabel" {
		request.dryRunXSkippedSpecRuns = ( request.dryRunXSkippedSpecRuns ?: 0 ) + 1;
	}

}