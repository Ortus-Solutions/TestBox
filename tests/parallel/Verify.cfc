/** CommandBox focused cross-engine core contracts; no app environments are created. */
component {

	function run(){
		var root = variables.fileSystemUtil.resolvePath( "." )
		variables.fileSystemUtil.createMapping( "/testbox", root )
		variables.fileSystemUtil.createMapping( "/tests", root & "/tests" )
		var result = new testbox.system.TestBox(
			bundles = "tests.specs.parallel.CoordinatorSpec,tests.specs.parallel.ProgressFileSpec,tests.specs.parallel.RunnerSpec,tests.specs.parallel.ShardPlanSpec,tests.specs.parallel.WorkerProviderSpec"
		).runRaw()
		variables.print
			.line(
				result.getTotalPass() & " passed / " & result.getTotalFail() & " failed / " & result.getTotalError() & " errors"
			)
			.toConsole()
		if ( result.getTotalFail() || result.getTotalError() ) {
			variables.print.line( "Failure report directory: " & getTempDirectory() ).toConsole()
			fileWrite(
				getTempDirectory() & "testbox-parallel-contract-failure.json",
				serializeJSON( result.getMemento( true ) )
			)
			throw( message = "Parallel contracts failed. See temporary testbox-parallel-contract-failure.json." )
		}
	}

}
