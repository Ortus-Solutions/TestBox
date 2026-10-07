/**
 * Fixture for the AgentReporter tests: everything passes.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "All good", function(){
			it( "passes", function(){
				expect( true ).toBeTrue();
			} );
		} );
	}

}
