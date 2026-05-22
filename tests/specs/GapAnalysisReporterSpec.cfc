/**
 * Tests for GapAnalysisReporter HTML assembly (paired with assets/gapAnalysis.cfm).
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll(){
		variables.tb  = new testbox.system.TestBox();
		variables.rep = new testbox.system.reports.GapAnalysisReporter();
	}

	function run(){
		describe( "GapAnalysisReporter", function(){
			it( "getName returns GapAnalysis", function(){
				expect( rep.getName() ).toBe( "GapAnalysis" );
			} );

			it( "renderHtml returns full-page HTML with branding and TestBox version", function(){
				var html = rep.renderHtml(
					testbox = tb,
					options = {
						gapReport : {
							stats : {
								totalFunctions    : 0,
								coveredHeuristic  : 0,
								missingHeuristic  : 0,
								skippedComponents : 0
							},
							uncovered : [],
							covered   : [],
							skipped   : []
						},
						gapRunnerSummary : {},
						runnerErrors     : [],
						ran              : false,
						fullPage         : true
					},
					justReturn = true
				);
				expect( len( html ) ).toBeGT( 200 );
				expect( html ).toInclude( "Gap analysis" );
				expect( html ).toInclude( tb.getVersion() );
				expect( html ).toInclude( "<!DOCTYPE html>" );
				expect( html ).toInclude( "Filter Bundles" );
				expect( html ).toInclude( "collapse-bundles" );
			} );

			it( "renderHtml surfaces runnerErrors in output", function(){
				var html = rep.renderHtml(
					testbox = tb,
					options = {
						gapReport        : {},
						gapRunnerSummary : {},
						runnerErrors     : [ "fixture error message" ],
						ran              : false
					},
					justReturn = true
				);
				expect( html ).toInclude( "fixture error message" );
			} );
		} );
	}

}
