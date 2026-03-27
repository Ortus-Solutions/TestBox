/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Heuristic "test mention" gap analysis: compares public/remote function names from
 * component metadata against a concatenated test corpus (text of .cfc/.cfm under test roots).
 * This is not line coverage and not proof that a test exercises a function.
 */
component accessors="true" {

	/**
	 * Infer dotted component prefix for a physical source root using application mappings (longest mapping match).
	 */
	public string function inferComponentPrefix( required string sourceRootAbs ){
		var normalized = replace( arguments.sourceRootAbs, "\", "/", "all" );
		normalized = reReplace( normalized, "/+$", "", "all" );
		if ( !len( normalized ) ) {
			return "";
		}
		var bestPhys = "";
		var bestKey  = "";
		try {
			var meta = getApplicationMetadata();
			if ( !isNull( meta ) && structKeyExists( meta, "mappings" ) && isStruct( meta.mappings ) ) {
				var mappings = meta.mappings;
				for ( var key in mappings ) {
					var mapKey = key;
					if ( left( mapKey, 1 ) != "/" ) {
						mapKey = "/" & mapKey;
					}
					var phys = expandPath( mapKey );
					phys = replace( phys, "\", "/", "all" );
					phys = reReplace( phys, "/+$", "", "all" );
					if ( !len( phys ) ) {
						continue;
					}
					if (
						len( normalized ) >= len( phys )
						&& compareNoCase( left( normalized, len( phys ) ), phys ) == 0
						&& ( len( normalized ) == len( phys ) || mid( normalized, len( phys ) + 1, 1 ) == "/" )
					) {
						if ( len( phys ) > len( bestPhys ) ) {
							bestPhys = phys;
							bestKey  = mapKey;
						}
					}
				}
			}
		} catch ( any e0 ) {
		}
		if ( len( bestPhys ) && len( bestKey ) ) {
			var rel = len( normalized ) > len( bestPhys ) ? mid( normalized, len( bestPhys ) + 1, 9999 ) : "";
			rel = reReplace( rel, "^/+|/+$", "", "all" );
			var mapPart = reReplace( bestKey, "^/+|/+$", "", "all" );
			var mapDots = replace( mapPart, "/", ".", "all" );
			if ( len( rel ) ) {
				return mapDots & "." & replace( rel, "/", ".", "all" );
			}
			return mapDots;
		}
		return _inferComponentPrefixFallback( normalized );
	}

	/**
	 * @sourceRoot Absolute directory containing CFCs to scan (e.g. expandPath("/com/myapp")).
	 * @componentPrefix Dotted prefix for component IDs (e.g. "com.myapp" for files under sourceRoot).
	 * @testRootList Comma-separated absolute directories to scan for test/spec text (cfc/cfm).
	 * @excludeFileNames Comma list of file names to skip (case-insensitive), e.g. "accessLog.cfc,application.cfc".
	 * @excludePathPrefixes Comma list of relative path prefixes under sourceRoot to skip, e.g. "application".
	 * @recurseTestRoots Same as TestBox directory runner: when true, include all nested files under each test root (matches getSpecPaths / addDirectories recurse).
	 */
	struct function analyze(
		required string sourceRoot,
		required string componentPrefix,
		required string testRootList,
		string excludeFileNames = "",
		string excludePathPrefixes = "",
		boolean recurseTestRoots = true
	){
		var opts = {
			"sourceRoot"          : _normalizeDir( arguments.sourceRoot ),
			"componentPrefix"     : trim( arguments.componentPrefix ),
			"excludeFileNames"    : _listToArrayLower( arguments.excludeFileNames ),
			"excludePathPrefixes" : _pathPrefixList( arguments.excludePathPrefixes )
		};

		var testRoots = [];
		for ( var tr in listToArray( arguments.testRootList ) ) {
			tr = trim( tr );
			if ( len( tr ) ) {
				arrayAppend( testRoots, tr );
			}
		}
		var testBlob = _buildTestBlob( testRoots, opts.sourceRoot, arguments.recurseTestRoots );

		var uncovered = [];
		var covered   = [];
		var skipped   = [];

		var cfcFiles = _listCfcFiles( opts.sourceRoot );
		for ( var fp in cfcFiles ) {
			var rel = _relativePath( fp, opts.sourceRoot );
			if ( _shouldSkipPath( rel, opts ) ) {
				continue;
			}
			var componentId = _toComponentId( rel, opts.componentPrefix );
			var md          = {};
			try {
				md = getComponentMetadata( componentId );
			} catch ( any e ) {
				arrayAppend(
					skipped,
					{
						"componentId" : componentId,
						"file"          : replace( rel, "\", "/", "all" ),
						"reason"        : "metadata",
						"message"       : structKeyExists( e, "message" ) ? e.message : "",
						"detail"        : structKeyExists( e, "detail" ) ? toString( e.detail ) : ""
					}
				);
				continue;
			}
			if ( !structKeyExists( md, "functions" ) || !isArray( md.functions ) ) {
				continue;
			}
			var displayFile = replace( rel, "\", "/", "all" );
			for ( var fn in md.functions ) {
				if ( !structKeyExists( fn, "name" ) || _ignoreFunction( fn ) ) {
					continue;
				}
				var fl   = lCase( fn.name );
				var row  = {
					"componentId" : componentId,
					"file"        : displayFile,
					"function"    : fn.name,
					"fn_lower"    : fl,
					"access"      : structKeyExists( fn, "access" ) ? fn.access : "public"
				};
				if ( find( fl, testBlob ) ) {
					arrayAppend( covered, row );
				} else {
					arrayAppend( uncovered, row );
				}
			}
		}

		var total = arrayLen( covered ) + arrayLen( uncovered );
		return {
			"stats"     : {
				"totalFunctions"     : total,
				"coveredHeuristic"   : arrayLen( covered ),
				"missingHeuristic"   : arrayLen( uncovered ),
				"skippedComponents"  : arrayLen( skipped )
			},
			"uncovered" : uncovered,
			"covered"   : covered,
			"skipped"   : skipped
		};
	}

	private string function _inferComponentPrefixFallback( required string normalizedPath ){
		var segs = listToArray( reReplace( arguments.normalizedPath, "/+$", "", "all" ), "/" );
		var n    = arrayLen( segs );
		if ( n >= 2 ) {
			return segs[ n - 1 ] & "." & segs[ n ];
		}
		if ( n == 1 ) {
			return segs[ 1 ];
		}
		return "";
	}

	private string function _normalizeDir( required string p ){
		var s = replace( arguments.p, "\", "/", "all" );
		if ( !directoryExists( s ) && directoryExists( expandPath( arguments.p ) ) ) {
			s = expandPath( arguments.p );
			s = replace( s, "\", "/", "all" );
		}
		if ( !s.endsWith( "/" ) ) {
			s &= "/";
		}
		return s;
	}

	private array function _listToArrayLower( required string s ){
		if ( !len( trim( s ) ) ) {
			return [];
		}
		var out = [];
		for ( var p in listToArray( s ) ) {
			arrayAppend( out, lCase( trim( p ) ) );
		}
		return out;
	}

	private array function _pathPrefixList( required string s ){
		var out = [];
		if ( !len( trim( s ) ) ) {
			return out;
		}
		for ( var p in listToArray( s ) ) {
			var t = trim( replace( p, "\", "/", "all" ) );
			t     = reReplace( t, "^/+|/+$", "", "all" );
			if ( len( t ) ) {
				arrayAppend( out, lCase( t ) );
			}
		}
		return out;
	}

	private boolean function _shouldSkipPath( required string relForward, required struct opts ){
		var rel = lCase( replace( arguments.relForward, "\", "/", "all" ) );
		var fn  = listLast( rel, "/" );
		for ( var ex in opts.excludeFileNames ) {
			if ( compareNoCase( ex, fn ) == 0 ) {
				return true;
			}
		}
		for ( var px in opts.excludePathPrefixes ) {
			if ( !len( px ) ) {
				continue;
			}
			if ( rel == px || ( len( rel ) > len( px ) && left( rel, len( px ) + 1 ) == px & "/" ) ) {
				return true;
			}
		}
		return false;
	}

	private string function _relativePath( required string fullPath, required string root ){
		var r = replaceNoCase( arguments.fullPath, arguments.root, "", "one" );
		r     = reReplace( r, "^[\\/]+", "" );
		return replace( r, "\", "/", "all" );
	}

	private string function _toComponentId( required string relForward, required string prefix ){
		var base = arguments.prefix;
		var p    = reReplaceNoCase( arguments.relForward, "\.cfc$", "", "all" );
		p        = replace( p, "\", "/", "all" );
		p        = replace( p, "/", ".", "all" );
		return base & "." & p;
	}

	private array function _listCfcFiles( required string root ){
		var files = directoryList( arguments.root, true, "path", "*.cfc" );
		arraySort( files, "textnocase", "asc" );
		return files;
	}

	private boolean function _ignoreFunction( required struct fnMeta ){
		if ( !structKeyExists( arguments.fnMeta, "access" ) ) {
			return true;
		}
		if ( arrayFindNoCase( [ "public", "remote" ], arguments.fnMeta.access ) == 0 ) {
			return true;
		}
		var ignored = [ "init", "onmissingmethod" ];
		return arrayFindNoCase( ignored, arguments.fnMeta.name ) > 0;
	}

	private string function _buildTestBlob( required array testRoots, required string sourceRootHint, boolean recurseTestRoots = true ){
		var parts = [];
		for ( var tr in arguments.testRoots ) {
			var base = trim( tr );
			if ( !len( base ) ) {
				continue;
			}
			if ( !directoryExists( base ) && directoryExists( expandPath( base ) ) ) {
				base = expandPath( base );
			}
			if ( !directoryExists( base ) ) {
				continue;
			}
			var files = directoryList( base, arguments.recurseTestRoots, "path", "", "asc", "file" );
			for ( var fp in files ) {
				if ( !fileExists( fp ) ) {
					continue;
				}
				var ext = listLast( fp, "." );
				if ( !arrayFindNoCase( [ "cfc", "cfm" ], ext ) ) {
					continue;
				}
				try {
					arrayAppend( parts, lCase( fileRead( fp ) ) );
				} catch ( any e ) {
				}
			}
		}
		return arrayToList( parts, chr( 10 ) );
	}

	/**
	 * Render gap analysis HTML via GapAnalysisReporter (mirrors CoverageService delegating to CFM templates).
	 */
	any function renderReport(
		required testbox.system.TestBox testbox,
		required struct gapReport,
		required struct gapRunnerSummary,
		required array runnerErrors,
		boolean ran = false,
		boolean fullPage = true,
		boolean justReturn = false
	){
		var rep = new testbox.system.reports.GapAnalysisReporter();
		return rep.renderHtml(
			testbox = arguments.testbox,
			options = {
				"gapReport" : arguments.gapReport,
				"gapRunnerSummary" : arguments.gapRunnerSummary,
				"runnerErrors" : arguments.runnerErrors,
				"ran" : arguments.ran,
				"fullPage" : arguments.fullPage
			},
			justReturn = arguments.justReturn
		);
	}

}
