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

	/**
	 * Describe how many attempts a retried spec needed, for example " (passed after 2 attempts)".
	 *
	 * @specStats The spec stats
	 *
	 * @return The note, or an empty string when the spec ran once
	 */
	string function getAttemptsNote( required struct specStats ){
		if ( !structKeyExists( arguments.specStats, "attempts" ) || arguments.specStats.attempts <= 1 ) {
			return ""
		}
		var outcome = arguments.specStats.status == "Error" ? "errored" : lCase( arguments.specStats.status )
		return " (#outcome# after #arguments.specStats.attempts# attempts)"
	}

	/**
	 * The files attached to a spec with attach().
	 *
	 * @specStats The spec stats
	 *
	 * @return An array of { path, type, name } structs, empty when there are none
	 */
	array function getSpecAttachments( required struct specStats ){
		if ( structKeyExists( arguments.specStats, "attachments" ) && isArray( arguments.specStats.attachments ) ) {
			return arguments.specStats.attachments
		}
		return []
	}

	/**
	 * Build the JUnit system-out content that lists the attachments of a spec, one
	 * [[ATTACHMENT|absolute path]] line per file, as understood by Jenkins and GitLab.
	 *
	 * @specStats The spec stats
	 *
	 * @return The system-out text, or an empty string when there are no attachments
	 */
	string function getJUnitAttachmentsOutput( required struct specStats ){
		var lines = []
		for ( var attachment in getSpecAttachments( arguments.specStats ) ) {
			arrayAppend( lines, "[[ATTACHMENT|#attachment.path#]]" )
		}
		return arrayToList( lines, chr( 10 ) )
	}

	/**
	 * Encode a value for use inside a double or single quoted XML attribute.
	 * It uses the encodeForXMLAttribute() ESAPI function when the engine provides it
	 * (Adobe, Lucee, BoxLang with bx-esapi) and an xmlFormat() based fallback otherwise,
	 * so the XML reporters also work on a plain BoxLang runtime.
	 *
	 * @value The value to encode
	 *
	 * @return The encoded value
	 */
	string function encodeXMLAttribute( value = "" ){
		if ( isNull( variables.hasXMLAttributeEncoder ) ) {
			variables.hasXMLAttributeEncoder = structKeyExists( getFunctionList(), "encodeForXMLAttribute" );
		}
		if ( variables.hasXMLAttributeEncoder ) {
			return encodeForXMLAttribute( arguments.value );
		}
		// Keep tabs and line breaks, which attribute value normalization would turn into spaces
		return replaceList(
			xmlFormat( arguments.value ),
			"#chr( 9 )#,#chr( 10 )#,#chr( 13 )#",
			"&##x9;,&##xa;,&##xd;"
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

		if (
			server.keyExists( "coldfusion" ) && server.coldfusion.productName.findNoCase( "ColdFusion" ) && !server.keyExists( "boxlang" )
		) {
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
