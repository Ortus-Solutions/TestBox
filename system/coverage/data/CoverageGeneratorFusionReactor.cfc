/**
 * ********************************************************************************
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ********************************************************************************
 * I am the FusionReactor coverage provider. I capture per-line coverage via the
 * FusionReactor Agent's "cflpi" (CFML line performance instrumentation).
 *
 * I only ever touch the FusionReactor public API. All query-building and path
 * filtering lives in my {@link CoverageGenerator} base class.
 */
component extends="CoverageGenerator" accessors=true {

	/**
	 * Constructor
	 */
	function init(){
		super.init();
		return this;
	}

	/**
	 * Whether FusionReactor's line performance instrumentation is currently loaded.
	 *
	 * @return true if FR is available, false if not
	 */
	boolean function isProviderAvailable(){
		try {
			variables.fragentClass = createObject( "java", "com.intergral.fusionreactor.agent.Agent" );
			// Do a quick test to ensure the line performance instrumentation is loaded.
			// This will return null for non-supported versions of FR
			var instrumentation = fragentClass.getAgentInstrumentation().get( "cflpi" );
		} catch ( Any e ) {
			return false;
		}

		if ( isNull( instrumentation ) ) {
			return false;
		}

		// Detect the template compiler used to force-load un-run files.
		if ( listFindNoCase( "Railo,Lucee", server.coldfusion.productname ) ) {
			variables.templateCompiler = new data.TemplateCompiler_Lucee();
		} else {
			variables.templateCompiler = new data.TemplateCompiler_Adobe();
		}

		return true;
	}

	/**
	 * Reset system for a new test.  Turns on line coverage and resets in-memory statistics
	 */
	CoverageGenerator function beginCapture(){
		// Turn on line profiling
		fragentClass
			.getAgentInstrumentation()
			.get( "cflpi" )
			.setActive( true );
		// Clear any data in memory
		fragentClass
			.getAgentInstrumentation()
			.get( "cflpi" )
			.reset();

		return this;
	}

	/**
	 * End the capture of data.  Clears up memory and optionally turns off line profiling
	 *
	 * @leaveLineProfilingOn Set to true to leave line profiling enabled on the server
	 */
	CoverageGenerator function endCapture( leaveLineProfilingOn = false ){
		// Turn off line profiling
		if ( !leaveLineProfilingOn ) {
			fragentClass
				.getAgentInstrumentation()
				.get( "cflpi" )
				.setActive( false );
		}
		// Clear any data in memory
		fragentClass
			.getAgentInstrumentation()
			.get( "cflpi" )
			.reset();

		return this;
	}

	/**
	 * Return per-line coverage for a single file, keyed by 1-based line number.
	 *
	 * @filePath the absolute path to the file to gather coverage for
	 *
	 * @return struct of lineNum -> count
	 */
	struct function getLineMetricsMap( required string filePath ){
		var jFile         = createObject( "java", "java.io.File" ).init( arguments.filePath );
		var rawMap        = fragentClass
			.getAgentInstrumentation()
			.get( "cflpi" )
			.getLineMetrics( jFile.getCanonicalPath() );
		if ( isNull( rawMap ) ) {
			return {};
		}

		// Translate FR's map of Integer -> LineMetric into a plain struct of
		// Integer -> count (the ONLY shape the base class understands).
		// FR can hand us a java.util.Map OR a java.util.concurrent.ConcurrentHashMap
		// depending on version; both expose keySet()/get().
		var result = createObject( "java", "java.util.LinkedHashMap" ).init();
		for ( var lineKey in rawMap.keySet() ) {
			var lineMetric = rawMap.get( lineKey );
			result[ javacast( "int", lineKey ) ] = javacast( "int", lineMetric.getCount() );
		}

		return result;
	}

	/**
	 * Force a file to be compiled and loaded (via the engine's template compiler)
	 * so FR records metrics for it even though it never ran.
	 *
	 * @filePath the absolute path to the file to compile and load
	 */
	void function compileAndLoad( required string filePath ){
		if ( structKeyExists( variables, "templateCompiler" ) ) {
			variables.templateCompiler.compileAndLoad( arguments.filePath );
		}
	}

	/**
	 * FusionReactor / CF-engine bug-for-bug workarounds. FR's line metrics are
	 * flaky on closing tags, braces, and parens, and on a CFC's first line. These
	 * are engine-specific so they live HERE, not in the shared base class.
	 *
	 * Returns null to EXCLUDE a line from coverage entirely.
	 *
	 * @line             the raw source text of the current line
	 * @covered          the covered value (0/1) pulled from FR's metrics
	 * @theFile          the absolute path of the file being processed
	 * @lineNum          the 1-based line number
	 * @previousLineRan  whether the previous line was counted as covered (0/1)
	 *
	 * @return the adjusted covered value, or null to exclude the line
	 */
	function normalizeLineCovered( line, covered, theFile, lineNum, previousLineRan ){
		// On Adobe, the first line of classes seems to always report as being executable but not running whether it's a comment or a component declaration
		if (
			arguments.theFile.right( 4 ) == ".cfc" && arguments.lineNum == 1 && !arguments.covered && arguments.line.startsWith(
				"/" & "*"
			)
		) {
			return nullValue();
		}

		// On Adobe, the first line of CFCs seems to always report as being executable but not running whether it's a comment or a component declaration
		if (
			arguments.theFile.right( 4 ) == ".cfc" && arguments.lineNum == 1 && !arguments.covered && arguments.line.startsWith(
				"component"
			)
		) {
			return 1;
		}

		// Ignore any tag based comments.  Some are reporting as covered, others aren't.  They really all should be ignored.
		if ( reFindNoCase( "^<!---.*--->$", trim( arguments.line ) ) ) {
			return nullValue();
		}

		// Ignore any CFscript tags.  They don't consistently report and they aren't really executable in themselves
		if ( reFindNoCase( "<(\/)?cfscript>", trim( arguments.line ) ) ) {
			return nullValue();
		}

		// Count as covered any closing CF tags where the previous line ran.  Ending tags don't always seem to get picked up.
		if ( !arguments.covered && arguments.previousLineRan && reFindNoCase( "<\/cf.*>", trim( arguments.line ) ) ) {
			return arguments.previousLineRan;
		}

		// Count as covered any closing script braces where the previous line ran.  E.x, I've seen trailing } in a switch statement not picked up
		if ( !arguments.covered && arguments.previousLineRan && trim( arguments.line ) == "}" ) {
			return arguments.previousLineRan;
		}

		// Count as covered any closing parenthesis where the previous line ran.
		if ( !arguments.covered && arguments.previousLineRan && ( trim( arguments.line ) == ");" || trim( arguments.line ) == ")" ) ) {
			return arguments.previousLineRan;
		}

		// Count as covered any cffunction or cfargument tag where the previous line ran.
		if ( !arguments.covered && reFindNoCase( "^<cf(function|argument)", trim( arguments.line ) ) && arguments.previousLineRan ) {
			return arguments.previousLineRan;
		}

		return arguments.covered;
	}

}