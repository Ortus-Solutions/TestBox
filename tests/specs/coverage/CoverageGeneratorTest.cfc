/**
 * This tests the code coverage data builder in TestBox.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "CoverageGenerator", function(){
			it( "can init", function(){
				expect( new system.coverage.data.CoverageGenerator() ).toBeComponent();
			} );

			it( "reports 100% coverage by default for an un-instrumented file with executable code", function(){
				var model = prepareMock( new system.coverage.data.CoverageGenerator() );
				// Simulate a provider that could not capture ANY metrics for the file.
				model.$( "getLineMetricsMap" ).$results( {} );
				model.$( "compileAndLoad" );
				// The default provider hook can't tell "no executable code" from "no data",
				// so legacy behavior must be preserved: count every line against the file.
				expect( model.hasExecutableCode( "anything.bxm" ) ).toBeTrue();

				var row = getFileRow( model.generateData( getFixtureDir(), [], [] ), "ExecutableCode.bxm" );

				expect( row.numExecutableLines > 0 ).toBeTrue( "every line of an un-instrumented file is counted" );
				expect( row.percCoverage ).toBe( 0, "an un-instrumented file with code reports 0% coverage" );
			} );

			describe( "files with no executable code", function(){
				beforeEach( function(){
					variables.model = prepareMock( new system.coverage.data.CoverageGenerator() );
					// Simulate a provider that could not capture ANY metrics for the file.
					model.$( "getLineMetricsMap" ).$results( {} );
					model.$( "compileAndLoad" );
				} );

				it( "reports 100% coverage for a file with no executable code", function(){
					model.$( "hasExecutableCode" ).$results( false );

					var row = getFileRow( model.generateData( getFixtureDir(), [], [] ), "CommentsOnly.bxm" );

					expect( row.numExecutableLines ).toBe(
						0,
						"a file with no executable code has no executable lines"
					);
					expect( row.percCoverage ).toBe( 1, "a file with no executable code reports 100% coverage" );
				} );

				it( "still counts an un-instrumented file with executable code against itself", function(){
					model.$( "hasExecutableCode" ).$results( true );

					var row = getFileRow( model.generateData( getFixtureDir(), [], [] ), "ExecutableCode.bxm" );

					expect( row.numExecutableLines > 0 ).toBeTrue( "every line of an un-instrumented file is counted" );
					expect( row.percCoverage ).toBe( 0, "an un-instrumented file with code reports 0% coverage" );
				} );
			} );
		} );
	}

	/**
	 * Absolute path to the coverage fixtures folder. Normalized the same way
	 * CoverageService normalizes `pathToCapture`: forward slashes and a trailing slash.
	 */
	private string function getFixtureDir(){
		return expandPath( "/tests/resources/coverage" ).replace( "\", "/", "all" ) & "/";
	}

	/**
	 * Return the single coverage row for the given file.
	 *
	 * @qryData          The coverage data query
	 * @relativeFilePath The relative file path to find
	 */
	private struct function getFileRow( required query qryData, required string relativeFilePath ){
		for ( var row in arguments.qryData ) {
			if ( row.relativeFilePath == arguments.relativeFilePath ) {
				return row;
			}
		}

		throw( message = "No coverage data row found for [#arguments.relativeFilePath#]" );
	}

}
