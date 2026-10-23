component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Second bundle", function(){
			it( "passes too", function(){
				expect( true ).toBeTrue();
			} );
		} );
	}

}
