/**
 * Fixture for RetriesTest: xUnit tests with the bundle annotation and a method annotation.
 */
component extends="testbox.system.BaseSpec" retries="1" {

	function setup(){
		request.retriesFixture.setup++
	}

	function teardown(){
		request.retriesFixture.teardown++
	}

	function testFlakyWithBundleRetries(){
		request.retriesFixture.xunitFlaky++
		if ( request.retriesFixture.xunitFlaky < 2 ) {
			fail( "first xUnit attempt fails" )
		}
	}

	// The retries method annotation overrides the bundle annotation
	function testBrokenWithMethodRetries() retries="3"{
		request.retriesFixture.xunitBroken++
		fail( "xUnit attempt failed" )
	}

}
