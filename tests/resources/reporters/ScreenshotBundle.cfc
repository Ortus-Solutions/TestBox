/**
 * Fixture for the HTML reporter tests. It is intentionally NOT named *Test or *Spec so runners do not discover it.
 * It produces one failure with a real PNG screenshot and a trace attached.
 */
component extends="testbox.system.BaseSpec" {

	// a 1x1 transparent PNG
	variables.PIXEL = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==";

	function run(){
		describe( "Checkout", function(){
			it( "fails with a screenshot", function(){
				var folder = getTempDirectory() & "testbox-screenshot-fixture";
				if ( !directoryExists( folder ) ) {
					directoryCreate( folder );
				}
				var shot = folder & "/screenshot-1.png";
				fileWrite( shot, toBinary( variables.PIXEL ) );
				attach( shot, "screenshot" );
				attach( folder & "/trace.zip", "trace" );
				fail( "the order was not shipped" );
			} );
		} );
	}

}
