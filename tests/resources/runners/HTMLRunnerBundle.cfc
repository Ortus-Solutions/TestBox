component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Runner fixture", function(){
			it(
				title = "selected spec",
				body  = function(){
					expect( true ).toBeTrue()
				},
				labels = "selected"
			)
			it( "other spec", function(){
				expect( true ).toBeTrue()
			} )
		} )
	}

}
