/**
 * bx-playwright assertion failures count as spec failures, not errors, on every engine.
 * No browser is needed: the fixtures throw the bx-playwright error types themselves.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Playwright.AssertionFailed", function(){
			it( "counts as a failure in BDD specs and keeps the message and detail", function(){
				var results = new testbox.system.TestBox(
					bundles = "tests.resources.failures.PlaywrightFailureFixture",
					options = { coverage : { enabled : false } }
				).runRaw()
				var specs = results.getBundleStats()[ 1 ].suiteStats[ 1 ].specStats

				expect( results.getTotalFail() ).toBe( 1 )
				expect( results.getTotalError() ).toBe( 1 )
				expect( specs[ 1 ].status ).toBe( "Failed" )
				expect( specs[ 1 ].failMessage ).toBe( "Expected title ""Home"" but received ""Login""" )
				expect( specs[ 1 ].failDetail ).toBe( "Raise timeouts.assertion if the page is slow" )
			} )

			it( "keeps other Playwright errors as errors", function(){
				var results = new testbox.system.TestBox(
					bundles = "tests.resources.failures.PlaywrightFailureFixture",
					options = { coverage : { enabled : false } }
				).runRaw()
				var specs = results.getBundleStats()[ 1 ].suiteStats[ 1 ].specStats
				expect( specs[ 2 ].status ).toBe( "Error" )
				expect( specs[ 2 ].error.type ).toBe( "Playwright.Timeout" )
			} )

			it( "counts as a failure in xUnit tests", function(){
				var results = new testbox.system.TestBox(
					bundles = "tests.resources.failures.PlaywrightFailureXUnitFixture",
					options = { coverage : { enabled : false } }
				).runRaw()
				var stats = results.getBundleStats()[ 1 ].suiteStats[ 1 ].specStats[ 1 ]
				expect( results.getTotalFail() ).toBe( 1 )
				expect( results.getTotalError() ).toBe( 0 )
				expect( stats.status ).toBe( "Failed" )
				expect( stats.failMessage ).toBe( "Expected visible but was hidden" )
			} )

			it( "is recognized by isAssertionFailure()", function(){
				var outcomes = {}
				for ( var type in [ "TestBox.AssertionFailed", "Playwright.AssertionFailed", "Playwright.Timeout" ] ) {
					try {
						throw( type = type, message = "x" )
					} catch ( any e ) {
						outcomes[ type ] = isAssertionFailure( e )
					}
				}
				expect( outcomes[ "TestBox.AssertionFailed" ] ).toBeTrue()
				expect( outcomes[ "Playwright.AssertionFailed" ] ).toBeTrue()
				expect( outcomes[ "Playwright.Timeout" ] ).toBeFalse()
			} )
		} )
	}

}
