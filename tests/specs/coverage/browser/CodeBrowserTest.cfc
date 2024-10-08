/**
 * This tests the CodeBrowser functionality in TestBox.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "CodeBrowser", function(){
			it( "can init", function(){
				expect( new system.coverage.browser.CodeBrowser( {} ) ).toBeComponent();
			} );
		} );
	}

}
