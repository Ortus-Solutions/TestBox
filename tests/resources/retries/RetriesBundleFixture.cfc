/**
 * Fixture for RetriesTest: the bundle retries annotation, overridden by a spec retries argument.
 */
component extends="testbox.system.BaseSpec" retries="1" {

	function run(){
		describe( "Bundle Retries Fixture", function(){
			it( "uses the bundle retries", function(){
				request.retriesFixture.bundle++
				fail( "bundle attempt failed" )
			} )

			it(
				title   = "uses the spec retries over the bundle retries",
				body    = function(){
					request.retriesFixture.specOverride++
					fail( "spec attempt failed" )
				},
				retries = 3
			)
		} )
	}

}
