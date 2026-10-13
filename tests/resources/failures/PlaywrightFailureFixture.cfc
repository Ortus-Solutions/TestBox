/**
 * Fixture for PlaywrightFailureTest: specs that throw bx-playwright errors without a browser.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Playwright Failure Fixture", function(){
			it( "fails with a Playwright assertion", function(){
				throw(
					type    = "Playwright.AssertionFailed",
					message = "Expected title ""Home"" but received ""Login""",
					detail  = "Raise timeouts.assertion if the page is slow"
				)
			} )

			it( "errors with a Playwright timeout", function(){
				throw( type = "Playwright.Timeout", message = "Timed out waiting for ##save" )
			} )
		} )
	}

}
