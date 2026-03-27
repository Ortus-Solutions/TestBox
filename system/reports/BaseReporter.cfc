/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A Base reporter class
 */
component {

	/**
	 * Constructor
	 */
	function init(){
		return this;
	}

	/**
	 * The indicator format to use when rendering console output.
	 */
	string function getConsoleFormat(){
		return "text";
	}

	/**
	 * Lazily build a console helper utility.
	 */
	function getConsoleUtil(){
		if ( !structKeyExists( variables, "consoleUtils" ) ) {
			variables.consoleUtils = new testbox.system.util.ConsoleUtil();
		}
		return variables.consoleUtils;
	}

	/**
	 * Return a styled text for reporters that support ANSI output.
	 */
	function color( required style, required text ){
		return getConsoleUtil().color( arguments.style, arguments.text );
	}

	/**
	 * Get the indicator status text.
	 */
	function getStatusIndicator( required status ){
		return getConsoleUtil().getStatusIndicator( arguments.status, getConsoleFormat() );
	}

	/**
	 * Style a line of output according to the status.
	 */
	function printByStatus( required status, required text ){
		return getConsoleUtil().printByStatus( arguments.status, arguments.text );
	}

	/**
	 * Build a bundle indicator for the reporter's format.
	 */
	function getBundleIndicator( required bundle ){
		return getConsoleUtil().getBundleIndicator( arguments.bundle, getConsoleFormat() );
	}

	/**
	 * Build the standard TestBox banner.
	 */
	function getHeaderBanner( required testbox ){
		return getConsoleUtil().getBanner(
			arguments.testbox.getVersion(),
			"TestBox v",
			getConsoleFormat()
		);
	}

	/**
	 * Build a horizontal divider.
	 */
	function getDividerLine(
		numeric width    = 81,
		string character = "=",
		string style     = ""
	){
		return getConsoleUtil().getDivider(
			arguments.width,
			arguments.character,
			arguments.style
		);
	}

	/**
	 * Build an alert divider.
	 */
	function getAlertDivider( numeric width = 81 ){
		return getDividerLine(
			width     = arguments.width,
			character = "!",
			style     = "red+bold"
		);
	}

	function space( count = 1 ){
		return getConsoleUtil( false ).space( arguments.count );
	}

	function tab(){
		return getConsoleUtil( false ).tab();
	}

	/**
	 * Helper method to deal with ACF2016's overload of the page context response, come on Adobe, get your act together!
	 */
	function getPageContextResponse(){
		// If running in CLI mode, we don't have a page context
		if ( !getFunctionList().keyExists( "getPageContext" ) ) {
			return {
				"setContentType" : function(){
					// do nothing
				}
			};
		}

		if ( server.keyExists( "coldfusion" ) && server.coldfusion.productName.findNoCase( "ColdFusion" ) ) {
			return getPageContext().getResponse().getResponse();
		} else {
			return getPageContext().getResponse();
		}
	}

	/**
	 * Reset the HTML response
	 */
	function resetHTMLResponse(){
		// If running in CLI mode, we don't have a page context
		if ( !getFunctionList().keyExists( "getPageContext" ) ) {
			return;
		}
		// reset cfhtmlhead from integration tests
		if ( structKeyExists( server, "lucee" ) ) {
			try {
				getPageContext().getOut().resetHTMLHead();
			} catch ( any e ) {
				// don't care, that lucee version doesn't support it.
				writeDump( var = "resetHTMLHead() not supported #e.message#", output = "console" );
			}
		}
		// reset cfheader from integration tests
		getPageContextResponse().reset();
	}

	/**
	 * Compose a url for opening a file in an editor
	 *
	 * @template The template target
	 * @line     The line number target
	 * @editor   The editor to use: vscode, vscode-insiders, sublime, textmate, emacs, macvim, idea, atom, espresso
	 *
	 * @return The string for the IDE
	 */
	function openInEditorURL(
		required template,
		required line,
		editor = "vscode"
	){
		switch ( arguments.editor ) {
			case "vscode":
				return "vscode://file/#arguments.template#:#arguments.line#";
			case "vscode-insiders":
				return "vscode-insiders://file/#arguments.template#:#arguments.line#";
			case "sublime":
				return "subl://open?url=file://#arguments.template#&line=#arguments.line#";
			case "textmate":
				return "txmt://open?url=file://#arguments.template#&line=#arguments.line#";
			case "emacs":
				return "emacs://open?url=file://#arguments.template#&line=#arguments.line#";
			case "macvim":
				return "mvim://open/?url=file://#arguments.template#&line=#arguments.line#";
			case "idea":
				return "idea://open?file=#arguments.template#&line=#arguments.line#";
			case "atom":
				return "atom://core/open/file?filename=#arguments.template#&line=#arguments.line#";
			case "espresso":
				return "x-espresso://open?filepath=#arguments.template#&lines=#arguments.line#";
			default:
				return "#arguments.template#:#arguments.line#";
		}
	}

	/**
	 * Prepare incoming params for reports:
	 * - testMethod
	 * - testSpecs
	 * - testSuites
	 * - testBundles
	 * - directory
	 * - editor
	 */
	function prepareIncomingParams(){
		param url = {};

		if ( !structKeyExists( url, "testMethod" ) ) {
			url.testMethod = "";
		}
		if ( !structKeyExists( url, "testSpecs" ) ) {
			url.testSpecs = "";
		}
		if ( !structKeyExists( url, "testSuites" ) ) {
			url.testSuites = "";
		}
		if ( !structKeyExists( url, "testBundles" ) ) {
			url.testBundles = "";
		}
		if ( !structKeyExists( url, "directory" ) ) {
			url.directory = "";
		}
		if ( !structKeyExists( url, "editor" ) ) {
			url.editor = "vscode";
		}
	}

}
