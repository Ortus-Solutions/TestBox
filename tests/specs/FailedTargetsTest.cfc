/**
 * TestResult.getFailedTargets(): what failed in a run, to run only that again. Every engine.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "TestResult.getFailedTargets()", function(){
			it( "collects the bundles and spec ids that failed or errored", function(){
				var results = runFixtures( "tests.resources.failures.PlaywrightFailureFixture,tests.resources.attachments.AttachmentsXUnitFixture" );
				var targets = results.getFailedTargets();
				var specs   = results.getBundleStats()[ 1 ].suiteStats[ 1 ].specStats;

				expect( targets.bundles ).toBe( [ "tests.resources.failures.PlaywrightFailureFixture" ] );
				expect( targets.specs ).toHaveLength( 2 );
				expect( targets.specs ).toInclude( specs[ 1 ].id );
				expect( targets.specs ).toInclude( specs[ 2 ].id );
			} );

			it( "returns empty arrays when everything passed", function(){
				var targets = runFixtures( "tests.resources.attachments.AttachmentsXUnitFixture" ).getFailedTargets();
				expect( targets.bundles ).toBeEmpty();
				expect( targets.specs ).toBeEmpty();
				expect( targets.bundleErrors ).toBeEmpty();
			} );

			it( "puts bundles that failed outside of a spec in bundleErrors", function(){
				var targets = runFixtures( "tests.specsWithFailures.BeforeAllFailures" ).getFailedTargets();
				expect( targets.bundles ).toBeEmpty();
				expect( targets.specs ).toBeEmpty();
				expect( targets.bundleErrors ).toBe( [ "tests.specsWithFailures.BeforeAllFailures" ] );
			} );

			it( "keeps the failed specs of other bundles when a bundle failed outside of a spec", function(){
				var targets = runFixtures( "tests.specsWithFailures.BeforeAllFailures,tests.resources.failures.PlaywrightFailureFixture" ).getFailedTargets();
				expect( targets.bundles ).toBe( [ "tests.resources.failures.PlaywrightFailureFixture" ] );
				expect( targets.specs ).toHaveLength( 2 );
				expect( targets.bundleErrors ).toBe( [ "tests.specsWithFailures.BeforeAllFailures" ] );
			} );

			it( "selects only the failed specs when they are run again", function(){
				var targets = runFixtures( "tests.resources.failures.PlaywrightFailureFixture" ).getFailedTargets();
				var results = new testbox.system.TestBox(
					bundles = targets.bundles,
					options = { coverage : { enabled : false } }
				).runRaw( testBundles = targets.bundles, testSpecs = [ targets.specs[ 1 ] ] );

				expect( results.getTotalFail() + results.getTotalError() ).toBe( 1 );
				expect( results.getTotalSkipped() ).toBe( 1 );
			} );
		} );
	}

	/**
	 * Run fixture bundles and return their raw results.
	 *
	 * @bundles The fixture bundle paths, as a list
	 */
	private function runFixtures( required string bundles ){
		return new testbox.system.TestBox(
			bundles = arguments.bundles,
			options = { coverage : { enabled : false } }
		).runRaw();
	}

}
