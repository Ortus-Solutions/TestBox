/**
 * ********************************************************************************
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ********************************************************************************
 * I am the ABSTRACT base class for collecting code coverage data for a directory
 * of files and generating a query of data that can be consumed by the different
 * reporting interfaces.
 *
 * Concrete providers subclass me and implement:
 *   - isProviderAvailable() : whether this engine can capture coverage
 *   - beginCapture()/endCapture() : start/stop + reset capture
 *   - getLineMetricsMap()   : per-line hit counts for a single file
 *   - compileAndLoad()      : force-load a file so the engine records metrics
 *
 * Everything a provider needs to tell us is a plain struct keyed by 1-based line
 * number -> run count. That keeps the query-building identical for every provider.
 */
component accessors=true {

	/**
	 * Constructor
	 */
	function init(){
		variables.CR   = chr( 13 );
		variables.LF   = chr( 10 );
		variables.CRLF = CR & LF;

		// for file globbing
		variables.pathPatternMatcher = new testbox.system.modules.globber.models.PathPatternMatcher();

		return this;
	}

	/**
	 * Configure the main data collection class.
	 *
	 * @return true if enabled, false if disabled
	 */
	boolean function configure(){
		return isProviderAvailable();
	}

	/**
	 * Implement me: is this provider able to capture coverage on the current engine?
	 *
	 * @return true if available, false if not
	 */
	boolean function isProviderAvailable(){
		return false;
	}

	/**
	 * Implement me: reset the system for a new test.  Turns on line coverage and
	 * resets in-memory statistics.
	 */
	CoverageGenerator function beginCapture(){
		return this;
	}

	/**
	 * Implement me: end the capture of data.  Clears up memory and optionally turns
	 * off line profiling.
	 *
	 * @leaveLineProfilingOn Set to true to leave line profiling enabled on the server
	 */
	CoverageGenerator function endCapture( leaveLineProfilingOn = false ){
		return this;
	}

	/**
	 * Implement me: return per-line coverage for a single file.
	 *
	 * The returned struct must be keyed by 1-based line number, where each value is
	 * the NUMBER of times that line ran (0 or more).
	 *
	 * @filePath the absolute path to the file to gather coverage for
	 *
	 * @return struct of lineNum -> count
	 */
	struct function getLineMetricsMap( required string filePath ){
		return {};
	}

	/**
	 * Implement me (optional): force a file to be compiled and loaded so the engine
	 * records coverage metrics for it even though it never ran.  A no-op by default.
	 *
	 * @filePath the absolute path to the file to compile and load
	 */
	void function compileAndLoad( required string filePath ){
		// default no-op
	}

	/**
	 *
	 * @pathToCapture The full path to a folder of code.  Searched recursively
	 * @whitelist     Comma-delimited list or array of file paths to include
	 * @blacklist     Comma-delimited list or array of file paths to exclude
	 *
	 * @return query of data
	 */
	query function generateData(
		required string pathToCapture,
		any whitelist = "",
		any blacklist = ""
	){
		// Convert lists to an array.
		if ( isSimpleValue( arguments.whitelist ) ) {
			arguments.whitelist = arguments.whitelist.listToArray();
		}
		if ( isSimpleValue( arguments.blacklist ) ) {
			arguments.blacklist = arguments.blacklist.listToArray();
		}

		// Get a recursive list of all CFM and CFC files in  project root.
		var fileList = directoryList( arguments.pathToCapture, true, "path", "*.cf?" );

		// start data structure
		var qryData = queryNew(
			"filePath,relativeFilePath,filePathHash,numLines,numCoveredLines,numExecutableLines,percCoverage,lineData",
			"varchar,varchar,varchar,integer,integer,integer,decimal,object"
		);

		for ( var theFile in fileList ) {
			theFile = theFile.replace( "\", "/", "all" );

			var relativeFilePath = replaceNoCase( theFile, arguments.pathToCapture, "" );

			// Skip this file if it doesn't match our patterns
			// Pass a path relative to our root folder
			if (
				!isPathAllowed(
					relativeFilePath,
					arguments.whitelist,
					arguments.blacklist
				)
			) {
				continue;
			}

			var fileContents = fileRead( theFile );
			// Replace Windows CRLF with CR
			fileContents     = replaceNoCase( fileContents, CRLF, CR, "all" );
			// Replace lone LF with CR
			fileContents     = replaceNoCase( fileContents, LF, CR, "all" );
			// Break on CR, keeping empty lines
			var fileLines    = fileContents.listToArray( CR, true );

			// new file: theFile
			var strFiledata = {
				filePath           : theFile,
				relativeFilePath   : relativeFilePath,
				numLines           : arrayLen( fileLines ),
				numCoveredLines    : 0,
				numExecutableLines : 0,
				percCoverage       : 0,
				filePathHash       : hash( theFile )
			};
			// Add this to query later
			var lineData = createObject( "java", "java.util.LinkedHashMap" ).init();

			var lineMetricMap = getLineMetricsMap( theFile );
			var noDataForFile = false;
			// If we don't have any metrics for this file, attempt to force the file
			// to load, then check again. If it STILL has nothing, count every line
			// against us as a fallback.
			if ( !structCount( lineMetricMap ) ) {
				// Force the engine to compile and load the file even though it was never run.
				compileAndLoad( theFile );
				// Check for metrics again
				lineMetricMap = getLineMetricsMap( theFile );

				if ( isNull( lineMetricMap ) || !structCount( lineMetricMap ) ) {
					lineMetricMap     = structNew();
					var noDataForFile = true;
				}
			}
			var currentLineNum  = 0;
			var previousLineRan = 0;
			// Hoist the "do we have any metrics for this file" test out of the per-line
			// loop. structCount() on the provider's map is a dynamic call; asking it
			// once per source line (per file) is needless overhead on large captures.
			var hasMetrics      = structCount( lineMetricMap ) > 0;

			for ( var line in fileLines ) {
				currentLineNum++;
				// One int conversion per line, reused by the existence check and the read.
				var lineNumber = javacast( "int", currentLineNum );
				if ( hasMetrics && structKeyExists( lineMetricMap, lineNumber ) ) {
					var covered  = lineMetricMap[ lineNumber ];
					var previous = previousLineRan;

					// Let the provider apply engine-specific bug-for-bug workarounds
					// (e.g. FR's flaky closing-`}` / closing-CF-tag detection). The base
					// does no normalization; providers override normalizeLineCovered().
					covered = normalizeLineCovered(
						line,
						covered,
						theFile,
						currentLineNum,
						previous
					);

					// A null return means the provider wants to EXCLUDE this line
					// entirely (not counted as executable).
					if ( isNull( covered ) ) {
						continue;
					}

					lineData[ currentLineNum ] = covered;

					strFiledata.numExecutableLines++;
					if ( covered ) {
						strFiledata.numCoveredLines++;
					}
					var previousLineRan = covered;
				} else if ( noDataForFile ) {
					// As a hack, if there is no data for this file, just count every line against us.
					strFiledata.numExecutableLines++;
				}
			}

			if ( strFiledata.numExecutableLines ) {
				strFiledata.percCoverage = strFiledata.numCoveredLines / strFiledata.numExecutableLines;
			} else {
				// If there's no executable lines in the file, show it as 100% even though we can't divide by zero
				strFiledata.percCoverage = 1;
			}
			queryAddRow( qryData, strFiledata );
			qryData[ "lineData" ][ qryData.recordCount ] = lineData;
		}

		// Return the data
		return qryData;
	}

	/**
	 * Provider hook: normalize a single line's covered state to work around
	 * engine-specific reporting bugs (e.g. FusionReactor on CF engines has flaky
	 * closing-tag/brace/paren detection). The base applies NO normalization — it
	 * returns the covered value unchanged. Providers override this to apply their
	 * own bug-for-bug workarounds.
	 * <p>
	 * Providers may indicate that a line should be EXCLUDED entirely from coverage
	 * (not counted as executable) by returning {@code null}.
	 *
	 * @line            the raw source text of the current line
	 * @covered         the covered value (0/1) already pulled from the provider's metrics
	 * @theFile         the absolute path of the file being processed
	 * @lineNum         the 1-based line number
	 * @previousLineRan whether the previous line was counted as covered (0/1)
	 *
	 * @return the (possibly adjusted) covered value, or null to exclude the line
	 */
	function normalizeLineCovered(
		line,
		covered,
		theFile,
		lineNum,
		previousLineRan
	){
		return covered;
	}

	/**
	 * Determines if a path is valid given the whitelist and black list.  White and black lists
	 * use standard file globbing patterns.
	 *
	 * @path      The relative path to check.
	 * @whitelist paths to allow
	 * @blacklist paths to exclude
	 */
	function isPathAllowed(
		required string path,
		required array whitelist,
		required array blacklist
	){
		// Check whitelist
		if (
			arrayLen( arguments.whitelist ) && !pathPatternMatcher.matchPatterns(
				arguments.whitelist,
				arguments.path
			)
		) {
			return false;
		}
		// Check blacklist
		if (
			arrayLen( arguments.blacklist ) && pathPatternMatcher.matchPatterns(
				arguments.blacklist,
				arguments.path
			)
		) {
			return false;
		}

		// We passed all the checks
		return true;
	}

}
