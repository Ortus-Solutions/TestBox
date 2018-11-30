/**
* ********************************************************************************
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ********************************************************************************
* I collect code coverage data for a directory of files and generate
* a query of data that can be consumed by different reporting interfaces.
*/
component accessors=true {
	
	function init() {
		// Classes needed to work.
		variables.pathPatternMatcher = new PathPatternMatcher();
		
		// Detect server
		if( listFindNoCase( "Railo,Lucee", server.coldfusion.productname ) ) {
			variables.templateCompiler = new TemplateCompiler_Lucee();
		} else {
			variables.templateCompiler = new TemplateCompiler_Adobe();
		}
		
		try {
			variables.fragentClass = createObject( 'java', 'com.intergral.fusionreactor.agent.Agent' );
			// Do a quick test to ensure the line performance instrumentation is loaded.  This will return null for non-supported versions of FR
			var instrumentation = fragentClass.getAgentInstrumentation().get("cflpi");
		} catch( Any e ) {
			throw( message='Error loading the FusionReactor agent class.  Please ensure FusionReactor is installed', detail=e.message );
		}
		
		if( isNull( instrumentation ) ) {
			throw( message='FusionReactor''s instrumentation returned null for [cflpi].', detail='Please ensure you''re using a supported version of FusionReactor.' );
		}
	
		//writeDump( fragentClass.getAgentInstrumentation().get("cflpi").getSourceFiles() ); //abort;
		//writeDump( fragentClass.getAgentInstrumentation().get("cflpi") ); abort;
						
		variables.CR = chr( 13 );
		variables.LF = chr( 10 );
		variables.CRLF = CR & LF;

		return this;
	}
	
	/**
	* Reset system for a new test.  Turns on line coverage and resets in-memory statistics
	*/
	function beginCapture() {
		// Turn on line profiling
		fragentClass.getAgentInstrumentation().get("cflpi").setActive( true );
		// Clear any data in memory
		fragentClass.getAgentInstrumentation().get("cflpi").reset();
	}
	
	/**
	* End the capture of data.  Clears up memory and optionally turns off line profiling
	* @leaveLineProfilingOn Set to true to leave line profiling enabled on the server
	*/
	function endCapture( leaveLineProfilingOn=false  ) {
		// Turn off line profiling
		if( !leaveLineProfilingOn ) {
			fragentClass.getAgentInstrumentation().get("cflpi").setActive( false ); 			
		}
		// Clear any data in memory
		fragentClass.getAgentInstrumentation().get("cflpi").reset();
	}
	
	/**
	* @pathToCapture The full path to a folder of code.  Searched recursivley
	* @whitelist Comma-delimeted list or array of file paths to include
	* @blacklist Comma-delimeted list or array of file paths to exclude
	*
	* @Returns query of data
	*/
	query function generateData(
		required string pathToCapture,
		any whitelist='',		
		any blacklist=''
	) {
		// Convert lists to an array.
		if( isSimpleValue( arguments.whitelist ) ) { arguments.whitelist = arguments.whitelist.listToArray(); }
		if( isSimpleValue( arguments.blacklist ) ) { arguments.blacklist = arguments.blacklist.listToArray(); }
		
		// Get a recursive list of all CFM and CFC files in  project root.
		var fileList = directoryList( arguments.pathToCapture, true, "path", "*.cf*");
		
		// start data structure
		var qryData = queryNew( "filePath,relativeFilePath,filePathHash,numLines,numCoveredLines,numExecutableLines,percCoverage,lineData",
			"varchar,varchar,varchar,integer,integer,integer,decimal,object" );

		for( var theFile in fileList ) {
			theFile=theFile.replace("\","/","all");
			pathToCapture=pathToCapture.replace("\","/","all");

			var relativeFilePath = replaceNoCase( theFile, arguments.pathToCapture, '' );
			
			// Skip this file if it doesn't match our patterns
			// Pass a path relative to our root folder
			if( !isPathAllowed( relativeFilePath, arguments.whitelist, arguments.blacklist ) ) {
				continue;
			}
			
			var fileContents = fileRead( theFile );
			// Replace Windows CRLF with CR
			fileContents = replaceNoCase( fileContents, CRLF, CR, 'all' );
			// Replace lone LF with CR
			fileContents = replaceNoCase( fileContents, LF, CR, 'all' );
			// Break on CR, keeping empty lines 
			var fileLines = fileContents.listToArray( CR, true );
			
			// new file: theFile
			var strFiledata = {
				filePath = theFile,
				relativeFilePath = relativeFilePath,
				numLines = arrayLen( fileLines ),
				numCoveredLines = 0,
				numExecutableLines = 0,
				percCoverage = 0,
				filePathHash = hash( theFile )
			};
			// Add this to query later
			var lineData = createObject( 'java', 'java.util.LinkedHashMap' ).init();
			
			var lineMetricMap = fragentClass.getAgentInstrumentation().get("cflpi").getLineMetrics( theFile ) ?: structNew();
			var noDataForFile = false;
			// If we don't have any metrics for this file, and we're on Railo or Lucee, attempt to force the file to load.
			if( !structCount( lineMetricMap ) ) {
				// Force the engine to compile and load the file even though it was never run. 
				templateCompiler.compileAndLoad( theFile );
				// Check for metrics again 
				lineMetricMap = fragentClass.getAgentInstrumentation().get("cflpi").getLineMetrics( theFile );
				
				if( isNull( lineMetricMap ) ) {
					lineMetricMap = structNew(); 
					var noDataForFile = true;
				}
				
			
				
			}
			
			var currentLineNum=0;
			var previousLineRan=0;
			
			for( var line in fileLines ) {
				currentLineNum++;
				if( structCount( lineMetricMap ) && lineMetricMap.containsKey( javaCast( 'int', currentLineNum ) ) ) {
					var lineMetric = lineMetricMap.get(  javaCast( 'int', currentLineNum ) );
					var covered = lineMetric.getCount();
					
					// Overrides for bugginess ************************************************************************
					
					// Ignore any tag based comments.  Some are reporting as covered, others aren't.  They really all should be ignored.
					if( reFindNoCase( '^<!---.*--->$', trim( line) ) ) {
						continue;
					}
					
					// Ignore any CFscript tags.  They don't consistently report and they aren't really executable in themselves
					if( reFindNoCase( '<(\/)?cfscript>', trim( line) )) {
						continue;
					}
					
					// Count as covered any closing CF tags where the previous line ran.  Ending tags don't always seem to get picked up.
					if( !covered && reFindNoCase( '<\/cf.*>', trim( line) ) && previousLineRan ) {
						covered = previousLineRan;
					}
										
					// Count as covered any cffunction or cfargument tag where the previous line ran.  
					if( !covered && reFindNoCase( '^<cf(function|argument)', trim( line) ) && previousLineRan ) {
						covered = previousLineRan;
					}
					
					// Overrides for bugginess ************************************************************************
					
					lineData[ currentLineNum ] = covered;
					
					strFiledata.numExecutableLines++;
					if( covered ) {
						strFiledata.numCoveredLines++;
					}
					var previousLineRan=covered;
				} else if( noDataForFile ) {
					// As a hack, if there is no data for this file, just count every line against us.
					strFiledata.numExecutableLines++;
				}
				
			}
			
			if( strFiledata.numExecutableLines ) {
				strFiledata.percCoverage = strFiledata.numCoveredLines/strFiledata.numExecutableLines;				
			}
			queryAddRow( qryData, strFiledata );
			qryData[ 'lineData' ][ qryData.recordCount ] = lineData;
		
		}
		
		// Return the data
		return qryData;

	}
	
	/**
	* Determines if a path is valid given the whitelist and black list.  White and black lists
	* use standard file globbing patterns.
	*
	* @path The relative path to check.
	* @whitelist paths to allow
	* @blacklist paths to exclude
	*/
	function isPathAllowed(
		required string path,
		required array whitelist,
		required array blacklist
	) {
			// Check whitelist
			if( arraylen( arguments.whitelist ) && !pathPatternMatcher.matchPatterns( arguments.whitelist, arguments.path ) ) {
				return false;
			}
			// Check blacklist
			if( arraylen( arguments.blacklist ) && pathPatternMatcher.matchPatterns( arguments.blacklist, arguments.path ) ) {
				return false;
			}
			
			// We passed all the checks
			return true;					
	}
	
}