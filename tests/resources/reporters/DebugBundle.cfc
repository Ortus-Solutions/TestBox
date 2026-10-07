/**
 * Fixture for the HTML reporter tests: writes to the debug() stream.
 * Not named *Test or *Spec so runners do not discover it.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Debugging", function(){
			it( "collects debug output", function(){
				debug( { "answer" : 42 }, "The answer" );
				expect( true ).toBeTrue();
			} );
		} );
	}

}
