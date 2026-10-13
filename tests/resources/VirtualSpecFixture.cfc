/**
 * Fixture for VirtualSpecTest: a spec that does not extend testbox.system.BaseSpec, so TestBox virtualizes it.
 */
component {

	function run(){
		describe( "Virtual spec fixture", function(){
			it( "runs expectations and assertions", function(){
				expect( 1 + 1 ).toBe( 2 );
				assert( true );
				request.virtualSpec = { ran : true };
			} );
		} );
	}

}
