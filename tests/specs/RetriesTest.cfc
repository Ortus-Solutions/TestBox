/**
 * Spec retries: the it() retries argument, the bundle retries annotation and the global retries option.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Spec retries", function(){
			beforeEach( function(){
				request.retriesFixture = {
					beforeEach   : 0,
					afterEach    : 0,
					flaky        : 0,
					broken       : 0,
					erroring     : 0,
					skipping     : 0,
					noRetries    : 0,
					bundle       : 0,
					specOverride : 0,
					global       : 0,
					setup        : 0,
					teardown     : 0,
					xunitFlaky   : 0,
					xunitBroken  : 0
				}
			} )

			describe( "BDD specs", function(){
				beforeEach( function(){
					variables.results = runFixture( "tests.resources.retries.RetriesFixture" )
				} )

				it( "passes a spec that fails first and passes on a retry", function(){
					var stats = findSpec( variables.results, "fails once then passes" )
					expect( stats.status ).toBe( "Passed" )
					expect( stats.attempts ).toBe( 2 )
					expect( request.retriesFixture.flaky ).toBe( 2 )
				} )

				it( "records the outcome of the final attempt when every attempt fails", function(){
					var stats = findSpec( variables.results, "always fails" )
					expect( stats.status ).toBe( "Failed" )
					expect( stats.attempts ).toBe( 2 )
					expect( stats.failMessage ).toBe( "attempt 2 failed" )
				} )

				it( "retries errors too", function(){
					var stats = findSpec( variables.results, "errors then passes" )
					expect( stats.status ).toBe( "Passed" )
					expect( stats.attempts ).toBe( 3 )
				} )

				it( "never retries a skipped spec", function(){
					var stats = findSpec( variables.results, "skips without retrying" )
					expect( stats.status ).toBe( "Skipped" )
					expect( request.retriesFixture.skipping ).toBe( 1 )
				} )

				it( "runs a spec without retries once", function(){
					var stats = findSpec( variables.results, "fails without retries" )
					expect( stats.status ).toBe( "Failed" )
					expect( stats.attempts ).toBe( 1 )
				} )

				it( "runs beforeEach and afterEach for every attempt", function(){
					// 2 + 2 + 3 + 1 + 1 attempts
					expect( request.retriesFixture.beforeEach ).toBe( 9 )
					expect( request.retriesFixture.afterEach ).toBe( 9 )
				} )

				it( "counts only the final outcome in the totals", function(){
					expect( variables.results.getTotalPass() ).toBe( 2 )
					expect( variables.results.getTotalFail() ).toBe( 2 )
					expect( variables.results.getTotalError() ).toBe( 0 )
					expect( variables.results.getTotalSkipped() ).toBe( 1 )
				} )
			} )

			describe( "precedence", function(){
				it( "uses the bundle retries annotation when the spec declares none", function(){
					var results = runFixture( "tests.resources.retries.RetriesBundleFixture" )
					expect( findSpec( results, "uses the bundle retries" ).attempts ).toBe( 2 )
					expect( request.retriesFixture.bundle ).toBe( 2 )
				} )

				it( "prefers the spec retries over the bundle annotation", function(){
					var results = runFixture( "tests.resources.retries.RetriesBundleFixture" )
					expect( findSpec( results, "uses the spec retries over the bundle retries" ).attempts ).toBe( 4 )
				} )

				it( "prefers the bundle annotation over the global option", function(){
					var results = runFixture( "tests.resources.retries.RetriesBundleFixture", { retries : 5 } )
					expect( findSpec( results, "uses the bundle retries" ).attempts ).toBe( 2 )
				} )

				it( "uses the global retries option when the spec and the bundle declare none", function(){
					var results = runFixture( "tests.resources.retries.RetriesGlobalFixture", { retries : 2 } )
					expect( findSpec( results, "uses the global retries" ).attempts ).toBe( 3 )
					expect( request.retriesFixture.global ).toBe( 3 )
				} )
			} )

			describe( "xUnit tests", function(){
				beforeEach( function(){
					variables.results = runFixture( "tests.resources.retries.RetriesXUnitFixture" )
				} )

				it( "retries with the bundle annotation", function(){
					var stats = findSpec( variables.results, "testFlakyWithBundleRetries" )
					expect( stats.status ).toBe( "Passed" )
					expect( stats.attempts ).toBe( 2 )
				} )

				it( "prefers the method retries annotation", function(){
					var stats = findSpec( variables.results, "testBrokenWithMethodRetries" )
					expect( stats.status ).toBe( "Failed" )
					expect( stats.attempts ).toBe( 4 )
				} )

				it( "runs setup and teardown for every attempt", function(){
					expect( request.retriesFixture.setup ).toBe( 6 )
					expect( request.retriesFixture.teardown ).toBe( 6 )
				} )
			} )

			describe( "reporters", function(){
				it( "describe the attempts of retried specs", function(){
					var reporter = new testbox.system.reports.BaseReporter()
					expect( reporter.getAttemptsNote( { status : "Passed", attempts : 3 } ) ).toBe( " (passed after 3 attempts)" )
					expect( reporter.getAttemptsNote( { status : "Failed", attempts : 2 } ) ).toBe( " (failed after 2 attempts)" )
					expect( reporter.getAttemptsNote( { status : "Passed", attempts : 1 } ) ).toBe( "" )
					expect( reporter.getAttemptsNote( { status : "Passed" } ) ).toBe( "" )
				} )

				it( "show the attempts in the text reporter", function(){
					var testbox = new testbox.system.TestBox(
						bundles = "tests.resources.retries.RetriesFixture",
						options = { coverage : { enabled : false } }
					)
					var results = testbox.runRaw()
					var report  = new testbox.system.reports.TextReporter().runReport( results, testbox )
					expect( report ).toInclude( "fails once then passes" )
					expect( report ).toInclude( "(passed after 2 attempts)" )
				} )
			} )
		} )
	}

	/**
	 * Run a fixture bundle and return its raw results.
	 *
	 * @bundle  The fixture bundle path
	 * @options The runner options
	 *
	 * @return The TestResult
	 */
	private function runFixture( required string bundle, struct options = {} ){
		var runnerOptions = duplicate( arguments.options )
		runnerOptions.coverage = { enabled : false }
		return new testbox.system.TestBox( bundles = arguments.bundle, options = runnerOptions ).runRaw()
	}

	/**
	 * Find the stats of a spec by name in a TestResult.
	 *
	 * @results The TestResult
	 * @name    The spec name
	 *
	 * @return The spec stats
	 */
	private struct function findSpec( required any results, required string name ){
		for ( var bundle in arguments.results.getBundleStats() ) {
			var found = findInSuites( bundle.suiteStats, arguments.name )
			if ( !structIsEmpty( found ) ) {
				return found
			}
		}
		throw( type = "RetriesTest.SpecNotFound", message = "No spec named [#arguments.name#]" )
	}

	/**
	 * Find the stats of a spec by name in suite stats, recursively.
	 *
	 * @suites The suite stats
	 * @name   The spec name
	 *
	 * @return The spec stats, or an empty struct
	 */
	private struct function findInSuites( required array suites, required string name ){
		for ( var suite in arguments.suites ) {
			for ( var spec in suite.specStats ) {
				if ( spec.name == arguments.name ) {
					return spec
				}
			}
			var nested = findInSuites( suite.suiteStats, arguments.name )
			if ( !structIsEmpty( nested ) ) {
				return nested
			}
		}
		return {}
	}

}
