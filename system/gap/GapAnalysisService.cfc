/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Heuristic gap analysis: compares public/remote function names from component metadata
 * to concatenated test/spec file text. This is not line coverage and not proof a test exercises a function.
 * Use TestBox.getGapAnalysisService(); renderRunnerEmbed() feeds the Simple reporter; renderReport() renders full HTML.
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
		var fp   = replace( arguments.fullPath, "\", "/", "all" );
		var rSrc = replace( arguments.root, "\", "/", "all" );
		if ( !rSrc.endsWith( "/" ) ) {
			rSrc &= "/";
		}
		var r = replaceNoCase( fp, rSrc, "", "one" );
		r     = reReplace( r, "^/+", "" );
		return r;
	}

	private string function _toComponentId( required string relForward, required string prefix ){
		var base = arguments.prefix;
		var p    = reReplaceNoCase( arguments.relForward, "\.cfc$", "", "all" );
		p        = replace( p, "\", "/", "all" );
		p        = replace( p, "/", ".", "all" );
		return base & "." & p;
	}

	private array function _listCfcFiles( required string root ){
		var raw = directoryList( arguments.root, true, "path", "", "asc", "file" );
		var files = [];
		for ( var fp in raw ) {
			if ( !fileExists( fp ) ) {
				continue;
			}
			if ( compareNoCase( listLast( fp, "." ), "cfc" ) == 0 ) {
				arrayAppend( files, fp );
			}
		}
		arraySort( files, "textnocase", "asc" );
		return files;
	}

	private boolean function _ignoreFunction( required struct fnMeta ){
		if ( structKeyExists( arguments.fnMeta, "access" ) && arrayFindNoCase( [ "public", "remote" ], arguments.fnMeta.access ) == 0 ) {
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
	 * Build runner summary and URLs from the current request (url + cgi) for the HTML runner and Simple embed.
	 *
	 * @testbox               The TestBox core object
	 * @sourceRootAbs         Resolved source root (optional when resolveOptionalPaths is true)
	 * @componentPrefix       Dotted component prefix (optional when resolveOptionalPaths is true)
	 * @testRootAbs           Resolved test root directories (optional when resolveOptionalPaths is true)
	 * @resolveOptionalPaths  When true (default), fill missing source/prefix/test roots from coverage options and url.directory
	 */
	public struct function buildRunnerSummaryFromRequest(
		required testbox.system.TestBox testbox,
		string sourceRootAbs = "",
		string componentPrefix = "",
		array testRootAbs = [],
		boolean resolveOptionalPaths = true
	){
		var qs      = structKeyExists( cgi, "query_string" ) ? cgi.query_string : "";
		var stripQs = reReplace( qs, "&gapAnalysis=[^&]*", "", "all" );
		stripQs = reReplace( stripQs, "^gapAnalysis=[^&]*&?", "", "all" );
		stripQs = reReplace( stripQs, "^[&]+|[&]+$", "", "all" );
		var testsUrl = len( stripQs ) ? ( cgi.script_name & "?" & stripQs ) : cgi.script_name;
		var gapRunAnalysisUrl = len( stripQs ) ? ( cgi.script_name & "?" & stripQs & "&gapAnalysis=true" ) : ( cgi.script_name & "?gapAnalysis=true" );

		var sr  = trim( toString( arguments.sourceRootAbs ) );
		var cp  = trim( toString( arguments.componentPrefix ) );
		var trs = isArray( arguments.testRootAbs ) ? arguments.testRootAbs : [];

		if ( arguments.resolveOptionalPaths ) {
			if ( !len( sr ) ) {
				try {
					sr = trim( toString( arguments.testbox.getCoverageService().getCoverageOptions().pathToCapture ) );
				} catch ( any e0 ) {
					sr = "";
				}
			}
			if ( !len( cp ) && len( sr ) ) {
				cp = inferComponentPrefix( sr );
			}
			if ( !arrayLen( trs ) && len( trim( toString( structKeyExists( url, "directory" ) ? url.directory : "" ) ) ) ) {
				trs = [];
				for ( var dir in listToArray( structKeyExists( url, "directory" ) ? url.directory : "" ) ) {
					dir = trim( dir );
					if ( !len( dir ) ) {
						continue;
					}
					arrayAppend( trs, expandPath( "/" & replace( dir, ".", "/", "all" ) ) );
				}
			}
		}

		var gapRunnerSummary = {
			"directory" : structKeyExists( url, "directory" ) ? url.directory : "",
			"recurse" : structKeyExists( url, "recurse" ) ? url.recurse : true,
			"bundles" : structKeyExists( url, "bundles" ) ? url.bundles : "",
			"coveragePathToCapture" : structKeyExists( url, "coveragePathToCapture" ) ? url.coveragePathToCapture : "",
			"sourceRootAbs" : sr,
			"componentPrefix" : cp,
			"testRootAbs" : trs,
			"testsUrl" : testsUrl
		};

		return {
			"gapRunnerSummary" : gapRunnerSummary,
			"gapRunAnalysisUrl" : gapRunAnalysisUrl,
			"testsUrl" : testsUrl
		};
	}

	/**
	 * Render HTML for embedding in the Simple reporter (same role as CoverageService.renderStats).
	 *
	 * @testbox    The TestBox core object
	 * @fullPage   When false, omit outer document wrapper for inclusion in the Simple report
	 */
	public any function renderRunnerEmbed( required testbox.system.TestBox testbox, boolean fullPage = false ){
		var built = buildRunnerSummaryFromRequest( arguments.testbox, "", "", [], true );
		return renderReport(
			testbox = arguments.testbox,
			gapReport = { "stats" : {}, "uncovered" : [], "covered" : [], "skipped" : [] },
			gapRunnerSummary = built.gapRunnerSummary,
			runnerErrors = [],
			ran = false,
			fullPage = arguments.fullPage,
			justReturn = true,
			gapEmbedCompact = true,
			gapRunAnalysisUrl = built.gapRunAnalysisUrl
		);
	}

	/**
	 * Render gap analysis HTML via GapAnalysisReporter and assets/gapAnalysis.cfm.
	 *
	 * @testbox             The TestBox core object
	 * @gapReport           Result struct from analyze() or empty stub for parameter-only views
	 * @gapRunnerSummary    Runner parameters and resolved paths for the template
	 * @runnerErrors        Messages when analysis could not run
	 * @ran                 Whether analyze() completed
	 * @fullPage            When true, emit DOCTYPE and asset includes for a standalone page
	 * @justReturn          When true, skip setting the response content type
	 * @gapEmbedCompact     When true, use the compact header for Simple reporter embed
	 * @gapRunAnalysisUrl   URL to open full gap analysis with the same query string
	 */
	any function renderReport(
		required testbox.system.TestBox testbox,
		required struct gapReport,
		required struct gapRunnerSummary,
		required array runnerErrors,
		boolean ran = false,
		boolean fullPage = true,
		boolean justReturn = false,
		boolean gapEmbedCompact = false,
		string gapRunAnalysisUrl = ""
	){
		var rep = new testbox.system.reports.GapAnalysisReporter();
		return rep.renderHtml(
			testbox = arguments.testbox,
			options = {
				"gapReport" : arguments.gapReport,
				"gapRunnerSummary" : arguments.gapRunnerSummary,
				"runnerErrors" : arguments.runnerErrors,
				"ran" : arguments.ran,
				"fullPage" : arguments.fullPage,
				"gapEmbedCompact" : arguments.gapEmbedCompact,
				"gapRunAnalysisUrl" : arguments.gapRunAnalysisUrl
			},
			justReturn = arguments.justReturn
		);
	}

}
