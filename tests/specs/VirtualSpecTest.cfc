/**
 * Specs that do not extend testbox.system.BaseSpec: TestBox mixes BaseSpec into them.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "A spec that does not extend BaseSpec", function(){
			it( "runs like one that does", function(){
				request.virtualSpec = { ran  : false };
				var results         = new testbox.system.TestBox(
					bundles = "tests.resources.VirtualSpecFixture",
					options = { coverage  : { enabled  : false } }
				).runRaw();
				expect( results.getTotalError() ).toBe( 0 );
				expect( results.getTotalFail() ).toBe( 0 );
				expect( results.getTotalPass() ).toBe( 1 );
				expect( request.virtualSpec.ran ).toBeTrue();
			} );
		} );
	}

}
