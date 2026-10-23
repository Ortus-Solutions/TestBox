component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "First bundle", function(){
			it( "passes", function(){
				expect( true ).toBeTrue();
			} );
		} );
	}

}
