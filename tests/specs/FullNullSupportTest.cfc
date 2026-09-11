/**
 * Regression coverage for public TestBox flows when missing values are real nulls.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Full null support", function(){
			it( "lazy loads public helper services from an uninitialized state", function(){
				expect( getCBMockData() ).toBeComponent();
				expect( getUtility() ).toBeComponent();
				expect( getEnv() ).toBeComponent();
				expect( getMockBox() ).toBeComponent();
			} );

			it( "discovers tests without optional URL filters", function(){
				var discovery = new testbox.system.TestBox(
					bundles = [ "tests.specs.BaseTest" ],
					options = { "coverage" : { "enabled" : false } }
				).dryRun();

				expect( discovery ).toBeStruct().toHaveKey( "bundles,filters,summary" );
				expect( discovery.filters.testBundles ).toBeEmpty();
				expect( discovery.filters.testSuites ).toBeEmpty();
				expect( discovery.filters.testSpecs ).toBeEmpty();
			} );
		} );
	}

}
