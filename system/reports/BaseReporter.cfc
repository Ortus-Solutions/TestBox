/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* A Base reporter class
*/
component{

	/**
	 * Helper method to deal with ACF2016's overload of the page context response, come on Adobe, get your act together!
	 */
	function getPageContextResponse(){
        if ( structKeyExists( server, "lucee" ) ) {
            return getPageContext().getResponse();
        } else {
            return getPageContext().getResponse().getResponse();
        }
	}

	/**
	 * Reset the HTML response
	 */
	function resetHTMLResponse(){
		// reset cfhtmlhead from integration tests
		if( structKeyExists( server, "lucee" ) ){
			try{
				getPageContext().getOut().resetHTMLHead();
			}catch( any e ){
				// don't care, that lucee version doesn't support it.
				writedump( var="resetHTMLHead() not supported #e.message#", output="console" );
			}
		}
		// reset cfheader from integration tests
		getPageContextResponse().reset();
	}

}
