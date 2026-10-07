/**
 * Fixture for the HTML reporter tests: names and messages that would inject markup if a template forgot to encode them.
 * Not named *Test or *Spec so runners do not discover it.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "<b>Suite</b> & friends", function(){
			it( "renders <img src=x onerror=alert(1)> safely", function(){
				fail( "<script>alert('xss')</script> & ""quotes""" );
			} );
		} );
	}

}
