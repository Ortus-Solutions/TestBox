/**
 * This tests the CoverageService functionality in TestBox.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "CoverageService", function(){
			it( "can init", function(){
				expect( new system.coverage.CoverageService() ).toBeComponent();
			} );
			it( "will read options", function(){
				var model = new system.coverage.CoverageService( {} );
				// debug( model.getCoverageOptions() );

				expect( model.getCoverageOptions() )
					.toHaveKey( "blacklist" )
					.toHaveKey( "whitelist" )
					.toHaveKey( "browser" )
					.toHaveKey( "sonarqube" );

				// Coverage is opt-in: omitting `enabled` never turns it on, even when a
				// coverage provider (BoxLang profiler / FusionReactor) is available.
				expect( model.getCoverageEnabled() ).toBeFalse(
					"coverage stays off unless explicitly enabled"
				);
			} );
			describe( "un-enabled coverage", function(){
				beforeEach( function(){
					if ( structKeyExists( variables, "model" ) ) {
						structDelete( variables, "model" );
					}
					variables.model         = prepareMock( new system.coverage.CoverageService( { "enabled" : false } ) );
					variables.mockGenerator = createEmptyMock( "system.coverage.data.CoverageGenerator" );
					model.$( "loadCoverageGenerator", mockGenerator );
					mockGenerator.$( "generateData" );
				} );
				it( "beginCapture - will not generate coverage unless enabled", function(){
					variables.model.beginCapture();
					expect( mockGenerator.$never( "generateData" ) ).toBeTrue();
				} );
				it( "endCapture - will not generate coverage unless enabled", function(){
					variables.model.endCapture();
					expect( mockGenerator.$never( "generateData" ) ).toBeTrue();
				} );
			} );

			it( "applies defaults when optional coverage settings are omitted", function(){
				var options = new system.coverage.CoverageService( { "enabled" : false } ).getCoverageOptions();

				expect( options.browser.outputDir ).toBe( "" );
				expect( options.coverageTresholds ).toBe( { "good" : 85, "bad" : 50 } );
				expect( options.sonarQube.XMLOutputPath ).toBe( "" );
				expect( options.isBatched ).toBeFalse();
			} );

			describe( "enabled coverage, disabled coverage batching", function(){
				beforeEach( function(){
					if ( structKeyExists( variables, "model" ) ) {
						structDelete( variables, "model" );
					}
					variables.model = prepareMock(
						new system.coverage.CoverageService( { "enabled" : true, "isBatched" : false } )
					);
					variables.mockReporter = createEmptyMock( "system.coverage.CoverageReporter" );
					model.$( "loadCoverageReporter", mockReporter );
					mockReporter.$( "processCoverageReport" );
				} );
				it( "processCoverage - will not batch coverage unless enabled", function(){
					var mockResult  = createMock( "testbox.system.TestResult" );
					var mockTestbox = createMock( "testbox.system.TestBox" );

					variables.model.processCoverage( mockResult, mockTestbox );
					expect( mockReporter.$never( "processCoverageReport" ) ).toBeTrue();
				} );
			} );
		} );
	}

}
