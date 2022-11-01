/**
 * This tests the CoverageService functionality in TestBox.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "CoverageService", function(){
			it( "can init", function(){
				expect( new system.coverage.CoverageService() ).toBeComponent();
			} );
			it( "will read options", function() {
				var model = new system.coverage.CoverageService( {} );

				expect( model.getCoverageEnabled() ).toBeTrue( "enables coverage if unspecified" );
			});
			describe( "un-enabled coverage", function() {
				beforeEach(function() {
					if ( structKeyExists( variables, "model" ) ){
						structDelete( variables, "model" );
					}
					variables.model = prepareMock( new system.coverage.CoverageService( {
						"enabled" : false
					} ) );
					variables.mockGenerator = createEmptyMock( "system.coverage.data.CoverageGenerator" );
					model.$( "loadCoverageGenerator", mockGenerator );
					mockGenerator.$( "generateData" );
				});
				it( "beginCapture - will not generate coverage unless enabled", function() {
					variables.model.beginCapture();
					expect( mockGenerator.$never( "generateData" ) ).toBeTrue();
				});
				it( "endCapture - will not generate coverage unless enabled", function() {
					variables.model.endCapture();
					expect( mockGenerator.$never( "generateData" ) ).toBeTrue();
				});
			});
			describe( "enabled coverage, disabled coverage batching", function() {
				beforeEach(function() {
					if ( structKeyExists( variables, "model" ) ){
						structDelete( variables, "model" );
					}
					variables.model = prepareMock( new system.coverage.CoverageService( {
						"enabled" : true,
						"isBatched" : false
					} ) );
					variables.mockReporter = createEmptyMock( "system.coverage.CoverageReporter" );
					model.$( "loadCoverageReporter", mockReporter );
					mockReporter.$( "processCoverageReport" );
				});
				it( "processCoverage - will not batch coverage unless enabled", function() {
					var mockResult = createMock( "testbox.system.TestResult" );
					var mockTestbox = createMock( "testbox.system.TestBox" );

					variables.model.processCoverage( mockResult, mockTestbox );
					expect( mockReporter.$never( "processCoverageReport" ) ).toBeTrue();
				});
			});
		} );
	}

}