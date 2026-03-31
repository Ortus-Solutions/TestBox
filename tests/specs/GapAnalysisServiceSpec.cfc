/**
 * Regression tests for heuristic gap analysis (public/remote name vs test corpus text).
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll(){
		variables.gapSvc              = new testbox.system.gap.GapAnalysisService();
		variables.fixtureSrc          = _gapFixtureAbs( "resources/gapAnalysisFixtures/src" );
		variables.fixtureCorpus       = _gapFixtureAbs( "resources/gapAnalysisFixtures/corpus" );
		variables.fixtureCorpusNested = _gapFixtureAbs( "resources/gapAnalysisFixtures/corpusNested" );
		variables.fixtureSrcNested    = _gapFixtureAbs( "resources/gapAnalysisFixtures/srcNested" );
	}

	private string function _gapFixtureAbs( required string relativeFromTests ){
		var specDir = getDirectoryFromPath( getCurrentTemplatePath() );
		var f       = createObject( "java", "java.io.File" ).init( specDir & "../" & arguments.relativeFromTests );
		return replace( f.getCanonicalPath(), "\", "/", "all" );
	}

	function run(){
		describe( "GapAnalysisService", function(){
			it( "inferComponentPrefix resolves longest mapping for fixture source root", function(){
				var p = gapSvc.inferComponentPrefix( fixtureSrc );
				expect( p ).toBe( "tests.resources.gapAnalysisFixtures.src" );
			} );

			it( "analyze marks functions mentioned in corpus and leaves others uncovered", function(){
				var r = gapSvc.analyze(
					sourceRoot      = fixtureSrc,
					componentPrefix = "tests.resources.gapAnalysisFixtures.src",
					testRootList    = fixtureCorpus
				);
				expect( r.stats.totalFunctions ).toBe( 2 );
				expect( r.stats.coveredHeuristic ).toBe( 1 );
				expect( r.stats.missingHeuristic ).toBe( 1 );
				expect( r.stats.skippedComponents ).toBe( 0 );

				var coveredNames = r.covered.map( function( row ){
					return row.function;
				} );
				expect( coveredNames ).toInclude( "gapFixtureMentionMe" );

				var uncoveredNames = r.uncovered.map( function( row ){
					return row.function;
				} );
				expect( uncoveredNames ).toInclude( "gapFixtureNeverMentioned" );
			} );

			it( "analyze with recurseTestRoots false skips nested corpus files", function(){
				var rDeep = gapSvc.analyze(
					sourceRoot       = fixtureSrcNested,
					componentPrefix  = "tests.resources.gapAnalysisFixtures.srcNested",
					testRootList     = fixtureCorpusNested,
					recurseTestRoots = true
				);
				expect( rDeep.stats.coveredHeuristic ).toBe( 1 );

				var rFlat = gapSvc.analyze(
					sourceRoot       = fixtureSrcNested,
					componentPrefix  = "tests.resources.gapAnalysisFixtures.srcNested",
					testRootList     = fixtureCorpusNested,
					recurseTestRoots = false
				);
				expect( rFlat.stats.coveredHeuristic ).toBe( 0 );
			} );

			it( "inferComponentPrefix returns empty for blank source root", function(){
				expect( gapSvc.inferComponentPrefix( "" ) ).toBe( "" );
			} );

			it( "resolveSourceRootForDirectoryRequest narrows to mirrored tests/specs subtree when present", function(){
				var tmpRoot      = replace( getTempDirectory(), "\", "/", "all" ) & "/tb-gap-" & lCase( createUUID() );
				var srcRoot      = tmpRoot & "/src";
				var mirroredRoot = srcRoot & "/com/palcare/hl7";
				var directoryArg = "tests/specs/com/palcare/hl7";
				directoryCreate( mirroredRoot, true );
				try {
					var resolved = gapSvc.resolveSourceRootForDirectoryRequest( srcRoot, directoryArg );
					expect( replace( resolved, "\", "/", "all" ) ).toBe( replace( mirroredRoot, "\", "/", "all" ) & "/" );
				} finally {
					if ( directoryExists( tmpRoot ) ) {
						directoryDelete( tmpRoot, true );
					}
				}
			} );

			it( "resolveSourceRootForDirectoryRequest avoids duplicated leading segment when base already includes it", function(){
				var tmpRoot      = replace( getTempDirectory(), "\", "/", "all" ) & "/tb-gap-" & lCase( createUUID() );
				var srcRoot      = tmpRoot & "/src/com";
				var mirroredRoot = srcRoot & "/palcare/hl7";
				var directoryArg = "tests/specs/com/palcare/hl7";
				directoryCreate( mirroredRoot, true );
				try {
					var resolved = gapSvc.resolveSourceRootForDirectoryRequest( srcRoot, directoryArg );
					expect( replace( resolved, "\", "/", "all" ) ).toBe( replace( mirroredRoot, "\", "/", "all" ) & "/" );
				} finally {
					if ( directoryExists( tmpRoot ) ) {
						directoryDelete( tmpRoot, true );
					}
				}
			} );

			it( "analyze with excludeFileNames omits matching CFCs", function(){
				var r = gapSvc.analyze(
					sourceRoot       = fixtureSrc,
					componentPrefix  = "tests.resources.gapAnalysisFixtures.src",
					testRootList     = fixtureCorpus,
					excludeFileNames = "GapFixture.cfc"
				);
				expect( r.stats.totalFunctions ).toBe( 0 );
				expect( r.stats.coveredHeuristic ).toBe( 0 );
				expect( r.stats.missingHeuristic ).toBe( 0 );
			} );

			it( "analyze with excludePathPrefixes omits CFCs under that path", function(){
				var r = gapSvc.analyze(
					sourceRoot          = fixtureSrc,
					componentPrefix     = "tests.resources.gapAnalysisFixtures.src",
					testRootList        = fixtureCorpus,
					excludePathPrefixes = "small"
				);
				expect( r.stats.totalFunctions ).toBe( 0 );
			} );

			it( "renderReport returns HTML with gap branding", function(){
				var tb   = new testbox.system.TestBox();
				var html = gapSvc.renderReport(
					testbox   = tb,
					gapReport = {
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
					gapRunnerSummary = {},
					runnerErrors     = [],
					ran              = false,
					justReturn       = true
				);
				expect( len( html ) ).toBeGT( 200 );
				expect( html ).toInclude( "Gap analysis" );
				expect( html ).toInclude( tb.getVersion() );
			} );

			it( "renderRunnerEmbed returns inline fragment without doctype", function(){
				var tb   = new testbox.system.TestBox();
				var html = gapSvc.renderRunnerEmbed( tb, false );
				expect( html ).notToInclude( "<!DOCTYPE html>" );
				expect( html ).toInclude( "Gap analysis" );
			} );

			it( "TestBox exposes gapAnalysisService like coverageService", function(){
				var tb = new testbox.system.TestBox();
				expect( tb.getGapAnalysisService() ).toBeInstanceOf( "testbox.system.gap.GapAnalysisService" );
			} );
		} );
	}

}
