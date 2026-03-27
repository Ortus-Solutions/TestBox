/**
 * Regression tests for heuristic gap analysis (public/remote name vs test corpus text).
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll(){
		variables.gapSvc = new testbox.system.gap.GapAnalysisService();
		variables.fixtureSrc = expandPath( "/tests/resources/gapAnalysisFixtures/src" );
		variables.fixtureCorpus = expandPath( "/tests/resources/gapAnalysisFixtures/corpus" );
		variables.fixtureCorpusNested = expandPath( "/tests/resources/gapAnalysisFixtures/corpusNested" );
		variables.fixtureSrcNested = expandPath( "/tests/resources/gapAnalysisFixtures/srcNested" );
	}

	function run(){
		describe( "GapAnalysisService", function(){
			it( "inferComponentPrefix resolves longest mapping for fixture source root", function(){
				var p = gapSvc.inferComponentPrefix( fixtureSrc );
				expect( p ).toBe( "tests.resources.gapAnalysisFixtures.src" );
			} );

			it( "analyze marks functions mentioned in corpus and leaves others uncovered", function(){
				var r = gapSvc.analyze(
					sourceRoot = fixtureSrc,
					componentPrefix = "tests.resources.gapAnalysisFixtures.src",
					testRootList = fixtureCorpus
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
					sourceRoot = fixtureSrcNested,
					componentPrefix = "tests.resources.gapAnalysisFixtures.srcNested",
					testRootList = fixtureCorpusNested,
					recurseTestRoots = true
				);
				expect( rDeep.stats.coveredHeuristic ).toBe( 1 );

				var rFlat = gapSvc.analyze(
					sourceRoot = fixtureSrcNested,
					componentPrefix = "tests.resources.gapAnalysisFixtures.srcNested",
					testRootList = fixtureCorpusNested,
					recurseTestRoots = false
				);
				expect( rFlat.stats.coveredHeuristic ).toBe( 0 );
			} );
		} );
	}

}
