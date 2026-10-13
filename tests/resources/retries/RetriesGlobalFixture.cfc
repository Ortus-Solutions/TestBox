/**
 * Fixture for RetriesTest: no retries declared, so the global runner option applies.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Global Retries Fixture", function(){
			it( "uses the global retries", function(){
				request.retriesFixture.global++
				fail( "global attempt failed" )
			} )
		} )
	}

}
