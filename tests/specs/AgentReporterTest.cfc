/**
 * Tests for the token-efficient AgentReporter
 */
component extends="testbox.system.BaseSpec" {

	variables.mixed   = "tests.resources.agentreporter.MixedBundle";
	variables.passing = "tests.resources.agentreporter.PassingBundle";

	/**
	 * Run a fixture bundle with the agent reporter and return the raw report string
	 */
	private string function runAgent( required string bundle, struct options = {} ){
		return new testbox.system.TestBox(
			bundles  = arguments.bundle,
			reporter = { type : "testbox.system.reports.AgentReporter", options : arguments.options }
		).run();
	}

	function run(){
		describe( "AgentReporter", function(){
			it( "is resolvable by the agent name", function(){
				var reporter = new testbox.system.TestBox().buildReporter( "agent" );
				expect( reporter.getName() ).toBe( "Agent" );
			} );

			it( "emits valid minified JSON on a single line", function(){
				var raw = runAgent( variables.mixed );
				expect( isJSON( raw ) ).toBeTrue( raw );
				expect( raw ).notToInclude( chr( 10 ) );
			} );

			describe( "passing runs", function(){
				it( "reports ok with totals and no failures", function(){
					var report = deserializeJSON( runAgent( variables.passing ) );
					expect( report.ok ).toBeTrue();
					expect( report.totals.pass ).toBe( 1 );
					expect( report.totals.fail ).toBe( 0 );
					expect( report.totals.error ).toBe( 0 );
					expect( report.totals.specs ).toBe( 1 );
					expect( report.failures ).toBeEmpty();
					expect( report.truncated ).toBe( 0 );
				} );
			} );

			describe( "failing runs", function(){
				var report = "";

				beforeEach( function(){
					report = deserializeJSON( runAgent( variables.mixed ) );
				} );

				it( "reports not ok and accurate totals", function(){
					expect( report.ok ).toBeFalse();
					expect( report.totals.pass ).toBe( 2 );
					expect( report.totals.fail ).toBe( 2 );
					expect( report.totals.error ).toBe( 1 );
					expect( report.totals.skipped ).toBe( 1 );
					expect( report.totals.specs ).toBe( 6 );
					expect( report.totals ).toHaveKey( "ms" );
				} );

				it( "lists only failed and errored specs", function(){
					expect( report.failures ).toHaveLength( 3 );
					for ( var thisFailure in report.failures ) {
						expect( [ "failed", "error" ] ).toInclude( thisFailure.status );
					}
				} );

				it( "builds the spec path with suite nesting", function(){
					var specs = report.failures.map( function( f ){
						return f.spec;
					} );
					expect( specs ).toInclude( "Math > fails with a message" );
					expect( specs ).toInclude( "Math > nested > fails with a very long message" );
					expect( specs ).toInclude( "Math > errors" );
				} );

				it( "includes bundle, message and origin", function(){
					var failure = report.failures.filter( function( f ){
						return f.spec == "Math > fails with a message";
					} )[ 1 ];
					expect( failure.bundle ).toInclude( "MixedBundle" );
					expect( failure.status ).toBe( "failed" );
					expect( failure.message ).notToBeEmpty();
					expect( failure.at ).toInclude( "MixedBundle.cfc:" );
				} );

				it( "reports thrown errors with the error status", function(){
					var failure = report.failures.filter( function( f ){
						return f.spec == "Math > errors";
					} )[ 1 ];
					expect( failure.status ).toBe( "error" );
					expect( failure.message ).toInclude( "kaboom" );
				} );

				it( "omits optional sections by default", function(){
					expect( report ).notToHaveKey( "specs" );
					expect( report ).notToHaveKey( "skipped" );
					expect( report ).notToHaveKey( "debug" );
					expect( report.failures[ 1 ] ).notToHaveKey( "stack" );
				} );
			} );

			describe( "options", function(){
				it( "detail=summary returns totals only", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { detail : "summary" } ) );
					expect( report ).toHaveKey( "ok" );
					expect( report ).toHaveKey( "totals" );
					expect( report ).notToHaveKey( "failures" );
				} );

				it( "detail=all lists every spec compactly", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { detail : "all" } ) );
					expect( report.specs ).toHaveLength( 6 );
					expect( report.specs[ 1 ] ).toHaveKey( "spec" );
					expect( report.specs[ 1 ] ).toHaveKey( "status" );
					expect( report.specs[ 1 ] ).toHaveKey( "ms" );
				} );

				it( "falls back to failures for an unknown detail value", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { detail : "nonsense" } ) );
					expect( report.failures ).toHaveLength( 3 );
				} );

				it( "maxFailures caps the list and reports the overflow", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { maxFailures : 1 } ) );
					expect( report.failures ).toHaveLength( 1 );
					expect( report.truncated ).toBe( 2 );
				} );

				it( "maxFailures=0 is unlimited", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { maxFailures : 0 } ) );
					expect( report.failures ).toHaveLength( 3 );
					expect( report.truncated ).toBe( 0 );
				} );

				it( "maxMessageLength truncates long messages", function(){
					var report  = deserializeJSON( runAgent( variables.mixed, { maxMessageLength : 50 } ) );
					var failure = report.failures.filter( function( f ){
						return f.spec == "Math > nested > fails with a very long message";
					} )[ 1 ];
					expect( failure.message ).toHaveLength( 53 );
					expect( failure.message ).toMatch( "\.\.\.$" );
				} );

				it( "includeStack adds a bounded stack array", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { includeStack : true, stackDepth : 2 } ) );
					for ( var thisFailure in report.failures ) {
						expect( thisFailure ).toHaveKey( "stack" );
						expect( arrayLen( thisFailure.stack ) ).toBeLTE( 2 );
					}
				} );

				it( "includeSkipped lists skipped spec paths", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { includeSkipped : true } ) );
					expect( report.skipped ).toBe( [ "Math > is skipped" ] );
				} );

				it( "includeDebug adds a debug array", function(){
					var report = deserializeJSON( runAgent( variables.mixed, { includeDebug : true } ) );
					expect( report ).toHaveKey( "debug" );
					expect( report.debug ).toBeArray();
				} );
			} );

			it( "reports bundle level exceptions as errors and never as ok", function(){
				var report = deserializeJSON( runAgent( "tests.specsWithFailures.BeforeAllFailures" ) );
				expect( report.ok ).toBeFalse();
				expect( report.failures ).toHaveLength( 1 );
				expect( report.failures[ 1 ].spec ).toBeEmpty();
				expect( report.failures[ 1 ].status ).toBe( "error" );
				expect( report.failures[ 1 ].message ).toInclude( "fail" );
			} );

			it( "uses paths relative to the web root to save tokens", function(){
				var report = deserializeJSON( runAgent( variables.mixed ) );
				expect( report.failures[ 1 ].at ).notToInclude( replace( expandPath( "/" ), "\\", "/", "all" ) );
			} );

			it( "is far smaller than the JSON reporter", function(){
				var agent = runAgent( variables.mixed );
				var full  = new testbox.system.TestBox(
					bundles  = variables.mixed,
					reporter = "json"
				).run();
				expect( len( agent ) ).toBeLT( len( full ) / 4 );
			} );
		} );
	}

}
