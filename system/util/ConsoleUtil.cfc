/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Shared console formatting helpers for reporters and CLI runners.
 */
component {

	// Static initialization block — runs once when the component is first loaded
	static {
		COLORS = {
			reset     : chr( 27 ) & "[0m",
			bold      : chr( 27 ) & "[1m",
			dim       : chr( 27 ) & "[2m",
			underline : chr( 27 ) & "[4m",
			blink     : chr( 27 ) & "[5m",
			reverse   : chr( 27 ) & "[7m",
			hidden    : chr( 27 ) & "[8m",
			black     : chr( 27 ) & "[30m",
			red       : chr( 27 ) & "[31m",
			green     : chr( 27 ) & "[32m",
			yellow    : chr( 27 ) & "[33m",
			blue      : chr( 27 ) & "[34m",
			magenta   : chr( 27 ) & "[35m",
			cyan      : chr( 27 ) & "[36m",
			white     : chr( 27 ) & "[37m",
			bgBlack   : chr( 27 ) & "[40m",
			bgRed     : chr( 27 ) & "[41m",
			bgGreen   : chr( 27 ) & "[42m",
			bgYellow  : chr( 27 ) & "[43m",
			bgBlue    : chr( 27 ) & "[44m",
			bgMagenta : chr( 27 ) & "[45m",
			bgCyan    : chr( 27 ) & "[46m",
			bgWhite   : chr( 27 ) & "[47m"
		};
		statusIndicators = {
			console : {
				passed  : "✅",
				pass    : "✅",
				failed  : "❌",
				error   : "💥",
				skipped : "⏭️ "
			},
			text : {
				passed  : "√",
				pass    : "√",
				failed  : "X",
				error   : "!!",
				skipped : "-"
			}
		};
	}

	function init(){
		return this;
	}

	/**
	 * Apply one or more ANSI styles to text.
	 *
	 * @style A + delimited list of styles (for example: bold+cyan)
	 * @text  The text to colorize
	 *
	 * @return The styled text with ANSI escape sequences
	 */
	function color( required string style, required string text ){
		if ( !len( arguments.style ) ) {
			return arguments.text;
		}

		var styleArray  = listToArray( arguments.style, "+" );
		var styleString = "";

		for ( var thisStyle in styleArray ) {
			styleString &= static.COLORS[ thisStyle ];
		}

		return "#static.COLORS.reset##styleString##arguments.text##static.COLORS.reset#";
	}

	/**
	 * Resolve the default style used for a test status.
	 *
	 * @status A test status such as passed, failed, error, or skipped
	 *
	 * @return The style token string used by color()
	 */
	function getStatusStyle( required string status ){
		switch ( lCase( trim( arguments.status ) ) ) {
			case "error":
				return "magenta+bold";
			case "failed":
				return "red+bold";
			case "skipped":
				return "dim+white";
			default:
				return "green";
		}
	}

	/**
	 * Get the visual status indicator for console or text output.
	 *
	 * @status A test status such as passed, failed, error, or skipped
	 * @format The indicator set to use: console or text
	 *
	 * @return The indicator token for the requested status and format
	 */
	function getStatusIndicator( required string status, string format = "console" ){
		var normalizedStatus = lCase( trim( arguments.status ) );
		var indicatorFormat  = lCase( trim( arguments.format ) );

		if ( !structKeyExists( static.statusIndicators, indicatorFormat ) ) {
			indicatorFormat = "console";
		}
		if ( !structKeyExists( static.statusIndicators[ indicatorFormat ], normalizedStatus ) ) {
			normalizedStatus = "passed";
		}

		return static.statusIndicators[ indicatorFormat ][ normalizedStatus ];
	}

	/**
	 * Print text using the status-derived style.
	 *
	 * @status A test status such as passed, failed, error, or skipped
	 * @text   The text to style
	 *
	 * @return Styled text for the provided status
	 */
	function printByStatus( required string status, required string text ){
		return color( getStatusStyle( arguments.status ), arguments.text );
	}

	/**
	 * Resolve a bundle rollup status from its aggregate counters.
	 *
	 * @bundle The bundle stats structure containing totals
	 *
	 * @return pass, error, or skipped
	 */
	function getBundleStatus( required struct bundle ){
		var bundleStatus = "pass";

		if ( arguments.bundle.totalFail > 0 || arguments.bundle.totalError > 0 ) {
			bundleStatus = "error";
		}
		if ( arguments.bundle.totalSkipped == arguments.bundle.totalSpecs ) {
			bundleStatus = "skipped";
		}

		return bundleStatus;
	}

	/**
	 * Build the leading bundle indicator string for a given output format.
	 *
	 * @bundle The bundle stats structure containing name/path and totals
	 * @format The indicator format: console or text
	 *
	 * @return A formatted bundle indicator string
	 */
	function getBundleIndicator( required struct bundle, string format = "console" ){
		var bundleStatus = getBundleStatus( arguments.bundle );
		var bundleName   = arguments.bundle.name ?: arguments.bundle.path ?: "";

		if ( lCase( trim( arguments.format ) ) == "console" ) {
			var bundleStyle = "green";
			if ( bundleStatus == "error" ) {
				bundleStyle = "bold+red";
			}
			if ( bundleStatus == "skipped" ) {
				bundleStyle = "dim+white";
			}

			return getStatusIndicator( bundleStatus, "console" ) & " " & color( bundleStyle, bundleName );
		}

		return getStatusIndicator( bundleStatus, arguments.format );
	}

	/**
	 * Build the standard TestBox banner.
	 *
	 * @version The TestBox version to display
	 * @label   The banner label prefix
	 * @format  The output format: console or text
	 *
	 * @return The banner line for terminal output
	 */
	function getBanner(
		required string version,
		string label  = "TestBox v",
		string format = "console"
	){
		var prefix = "█▓▒▒░░░ ";
		var title  = arguments.label & arguments.version;
		var suffix = " ░░░▒▒▓█";

		if ( lCase( trim( arguments.format ) ) == "console" ) {
			return color( "bold+cyan", prefix ) & color( "bold+green", title ) & color( "bold+cyan", suffix );
		}

		return prefix & title & suffix;
	}

	/**
	 * Build a horizontal divider line, optionally styled.
	 *
	 * @width     The number of characters in the divider
	 * @character The repeated character to use
	 * @style     Optional ANSI style token string
	 *
	 * @return The divider line
	 */
	function getDivider(
		numeric width    = 80,
		string character = "=",
		string style     = ""
	){
		var divider = repeatString( arguments.character, arguments.width );
		return len( arguments.style ) ? color( arguments.style, divider ) : divider;
	}

	/**
	 * Generate non-breaking spaces for aligned text layout in report templates.
	 *
	 * @count Number of spaces to return
	 *
	 * @return A string with non-breaking spaces
	 */
	function space( count = 1 ){
		return repeatString( "#chr( 160 )#", arguments.count );
	}

	/**
	 * Generate a single tab equivalent (4 spaces).
	 *
	 * @return Four non-breaking spaces
	 */
	function tab(){
		return space( 4 );
	}

}
