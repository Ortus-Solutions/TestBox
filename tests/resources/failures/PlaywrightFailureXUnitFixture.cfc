/**
 * Fixture for PlaywrightFailureTest: a xUnit test that throws a bx-playwright assertion failure.
 */
component extends="testbox.system.BaseSpec" {

	function testPlaywrightAssertion(){
		throw( type = "Playwright.AssertionFailed", message = "Expected visible but was hidden" )
	}

}
