/**
 * Fixture for RetriesTest: BDD specs with spec level retries.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Retries Fixture", function(){
			beforeEach( function(){
				request.retriesFixture.beforeEach++
			} )

			afterEach( function(){
				request.retriesFixture.afterEach++
			} )

			it(
				title   = "fails once then passes",
				body    = function(){
					request.retriesFixture.flaky++
					if ( request.retriesFixture.flaky < 2 ) {
						fail( "first attempt fails" )
					}
				},
				retries = 2
			)

			it(
				title   = "always fails",
				body    = function(){
					request.retriesFixture.broken++
					fail( "attempt #request.retriesFixture.broken# failed" )
				},
				retries = 1
			)

			it(
				title   = "errors then passes",
				body    = function(){
					request.retriesFixture.erroring++
					if ( request.retriesFixture.erroring < 3 ) {
						throw( type = "Fixture.Boom", message = "attempt #request.retriesFixture.erroring# errored" )
					}
				},
				retries = 2
			)

			it(
				title   = "skips without retrying",
				body    = function(){
					request.retriesFixture.skipping++
					skip( "skipped on purpose" )
				},
				retries = 3
			)

			it( "fails without retries", function(){
				request.retriesFixture.noRetries++
				fail( "no retries" )
			} )
		} )
	}

}
