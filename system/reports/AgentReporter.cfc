/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * A token-efficient JSON reporter designed for AI agents and automation.
 *
 * By default it emits a single minified JSON line with the totals and only the
 * failed/errored specs.  A passing run is a few dozen tokens.
 *
 * Output shape:
 * {
 *   "ok"        : false,
 *   "totals"    : { "pass":120, "fail":2, "error":1, "skipped":3, "specs":126, "ms":4210 },
 *   "failures"  : [ { "bundle":"tests.specs.FooTest", "spec":"Foo > can add", "status":"failed",
 *                     "message":"Expected [3] to be [4]", "at":"tests/specs/FooTest.cfc:42" } ],
 *   "truncated" : 0
 * }
 *
 * Options:
 * - detail           : "summary" (totals only), "failures" (default) or "all" (adds a compact `specs` list)
 * - maxFailures      : Max failures listed, default 20.  0 = unlimited. Overflow is reported in `truncated`
 * - maxMessageLength : Max characters of each failure message, default 300. 0 = unlimited
 * - includeStack     : Add a `stack` array ( "file:line" ) to each failure, default false
 * - stackDepth       : Frames kept when includeStack is true, default 3
 * - includeSkipped   : Add a `skipped` array of spec paths, default false
 * - includeDebug     : Add a `debug` array with any debug() output of the run, default false
 */
component extends="BaseReporter" {

	// Reporter option defaults
	variables.DEFAULTS = {
		"detail"           : "failures",
		"maxFailures"      : 20,
		"maxMessageLength" : 300,
		"includeStack"     : false,
		"stackDepth"       : 3,
		"includeSkipped"   : false,
		"includeDebug"     : false
	};

	/**
	 * Get the name of the reporter
	 */
	function getName(){
		return "Agent";
	}

	/**
	 * Do the reporting thing here using the incoming test results
	 * The report should return back in whatever format they desire and should set any
	 * Specific browser types if needed.
	 *
	 * @results    The instance of the TestBox TestResult object to build a report on
	 * @testbox    The TestBox core object
	 * @options    A structure of options this reporter needs to build the report with
	 * @justReturn Boolean flag that if set just returns the content with no content type and buffer reset
	 */
	any function runReport(
		required testbox.system.TestResult results,
		required testbox.system.TestBox testbox,
		struct options     = {},
		boolean justReturn = false
	){
		if ( !arguments.justReturn ) {
			resetHTMLResponse();
			getPageContextResponse().setContentType( "application/json" );
		}

		// prepare incoming params
		prepareIncomingParams();

		var opts      = buildOptions( arguments.options );
		// Arrays are passed by value on Adobe, structs by reference: collect through a struct
		var collector = { "failures" : [], "specs" : [], "skipped" : [] };
		var debugOut  = [];

		// Walk every bundle
		for ( var thisBundle in arguments.results.getBundleStats() ) {
			// Global bundle exceptions (compile errors, beforeAll failures, etc)
			if ( !isSimpleValue( thisBundle.globalException ) ) {
				var bundleFailure = [
					"bundle"  : thisBundle.path,
					"spec"    : "",
					"status"  : "error",
					"message" : cleanMessage(
						( thisBundle.globalException.type ?: "" ) & ": " & ( thisBundle.globalException.message ?: "" ),
						opts.maxMessageLength
					)
				];
				var bundleAt = findOrigin( thisBundle.globalException.tagContext ?: [] );
				if ( len( bundleAt ) ) {
					bundleFailure[ "at" ] = bundleAt;
				}
				if ( opts.includeStack ) {
					bundleFailure[ "stack" ] = buildStack( thisBundle.globalException.tagContext ?: [], opts.stackDepth );
				}
				arrayAppend( collector.failures, bundleFailure );
			}

			if ( opts.includeDebug && arrayLen( thisBundle.debugBuffer ) ) {
				for ( var thisDebug in thisBundle.debugBuffer ) {
					arrayAppend( debugOut, thisDebug );
				}
			}

			// Walk the suites recursively
			for ( var thisSuite in thisBundle.suiteStats ) {
				walkSuite( thisSuite, thisBundle.path, [], opts, collector );
			}
		}

		var failures = collector.failures;

		// Build the report, ordered keys for stable, readable output
		var report = [
			"ok"     : ( results.getTotalFail() + results.getTotalError() == 0 && !arrayLen( failures ) ),
			"totals" : [
				"pass"    : results.getTotalPass(),
				"fail"    : results.getTotalFail(),
				"error"   : results.getTotalError(),
				"skipped" : results.getTotalSkipped(),
				"specs"   : results.getTotalSpecs(),
				"ms"      : results.getTotalDuration()
			]
		];

		if ( opts.detail != "summary" ) {
			var truncated = 0;
			if ( opts.maxFailures > 0 && arrayLen( failures ) > opts.maxFailures ) {
				truncated = arrayLen( failures ) - opts.maxFailures;
				failures  = arraySlice( failures, 1, opts.maxFailures );
			}
			report[ "failures" ]  = failures;
			report[ "truncated" ] = truncated;

			if ( opts.includeSkipped ) {
				report[ "skipped" ] = collector.skipped;
			}
			if ( opts.detail == "all" ) {
				report[ "specs" ] = collector.specs;
			}
			if ( opts.includeDebug ) {
				report[ "debug" ] = debugOut;
			}
		}

		return serializeJSON( report );
	}

	/**
	 * Merge incoming options with the defaults and normalize them
	 */
	private struct function buildOptions( required struct options ){
		var opts = duplicate( variables.DEFAULTS );
		for ( var thisKey in opts ) {
			if ( structKeyExists( arguments.options, thisKey ) && !isNull( arguments.options[ thisKey ] ) ) {
				opts[ thisKey ] = arguments.options[ thisKey ];
			}
		}
		opts.detail = lCase( trim( opts.detail ) );
		if ( !listFindNoCase( "summary,failures,all", opts.detail ) ) {
			opts.detail = "failures";
		}
		opts.maxFailures      = max( 0, val( opts.maxFailures ) );
		opts.maxMessageLength = max( 0, val( opts.maxMessageLength ) );
		opts.stackDepth       = max( 1, val( opts.stackDepth ) );
		opts.includeStack     = isBoolean( opts.includeStack ) && opts.includeStack;
		opts.includeSkipped   = isBoolean( opts.includeSkipped ) && opts.includeSkipped;
		opts.includeDebug     = isBoolean( opts.includeDebug ) && opts.includeDebug;
		return opts;
	}

	/**
	 * Recursively walk a suite and collect its specs
	 */
	private void function walkSuite(
		required struct suiteStats,
		required string bundlePath,
		required array parents,
		required struct opts,
		required struct collector
	){
		var path = duplicate( arguments.parents );
		arrayAppend( path, arguments.suiteStats.name );

		for ( var thisSpec in arguments.suiteStats.specStats ) {
			var specPath = arrayToList( path, " > " ) & " > " & thisSpec.name;
			var status   = lCase( thisSpec.status );

			if ( arguments.opts.detail == "all" ) {
				arrayAppend(
					arguments.collector.specs,
					[
						"bundle" : arguments.bundlePath,
						"spec"   : specPath,
						"status" : status,
						"ms"     : thisSpec.totalDuration
					]
				);
			}

			if ( status == "skipped" ) {
				if ( arguments.opts.includeSkipped ) {
					arrayAppend( arguments.collector.skipped, specPath );
				}
			} else if ( status == "failed" || status == "error" ) {
				arrayAppend( arguments.collector.failures, buildFailure( thisSpec, arguments.bundlePath, specPath, status, arguments.opts ) );
			}
		}

		for ( var thisChild in arguments.suiteStats.suiteStats ) {
			walkSuite(
				thisChild,
				arguments.bundlePath,
				path,
				arguments.opts,
				arguments.collector
			);
		}
	}

	/**
	 * Build one failure entry
	 */
	private any function buildFailure(
		required struct specStats,
		required string bundlePath,
		required string specPath,
		required string status,
		required struct opts
	){
		var message = arguments.specStats.failMessage;
		if ( !len( message ) && isStruct( arguments.specStats.error ) && structKeyExists( arguments.specStats.error, "message" ) ) {
			message = arguments.specStats.error.message;
		}

		var failure = [
			"bundle"  : arguments.bundlePath,
			"spec"    : arguments.specPath,
			"status"  : arguments.status,
			"message" : cleanMessage( message, arguments.opts.maxMessageLength )
		];

		var origin = isArray( arguments.specStats.failOrigin ) ? arguments.specStats.failOrigin : [];
		var at     = findOrigin( origin );
		if ( len( at ) ) {
			failure[ "at" ] = at;
		}
		if ( arguments.opts.includeStack ) {
			failure[ "stack" ] = buildStack( origin, arguments.opts.stackDepth );
		}

		return failure;
	}

	/**
	 * Collapse whitespace and truncate a message
	 */
	private string function cleanMessage( required any message, required numeric maxLength ){
		var clean = trim( reReplace( toString( arguments.message ), "\s+", " ", "all" ) );
		if ( arguments.maxLength > 0 && len( clean ) > arguments.maxLength ) {
			clean = left( clean, arguments.maxLength ) & "...";
		}
		return clean;
	}

	/**
	 * Find the first meaningful frame as "file:line", preferring user code over TestBox internals
	 */
	private string function findOrigin( required array tagContext ){
		var fallback = "";
		for ( var thisFrame in arguments.tagContext ) {
			if ( !isStruct( thisFrame ) || !structKeyExists( thisFrame, "template" ) ) {
				continue;
			}
			var frame = formatFrame( thisFrame );
			if ( !len( fallback ) ) {
				fallback = frame;
			}
			if ( !isInternalFrame( thisFrame.template ) ) {
				return frame;
			}
		}
		return fallback;
	}

	/**
	 * Build an array of "file:line" frames, user code first
	 */
	private array function buildStack( required array tagContext, required numeric depth ){
		var userFrames     = [];
		var internalFrames = [];
		for ( var thisFrame in arguments.tagContext ) {
			if ( !isStruct( thisFrame ) || !structKeyExists( thisFrame, "template" ) ) {
				continue;
			}
			if ( isInternalFrame( thisFrame.template ) ) {
				arrayAppend( internalFrames, formatFrame( thisFrame ) );
			} else {
				arrayAppend( userFrames, formatFrame( thisFrame ) );
			}
		}
		var frames = userFrames;
		for ( var thisFrame in internalFrames ) {
			arrayAppend( frames, thisFrame );
		}
		return arraySlice( frames, 1, min( arguments.depth, arrayLen( frames ) ) );
	}

	/**
	 * Is this template part of TestBox's own engine code?
	 */
	private boolean function isInternalFrame( required string template ){
		var normalized = replace( arguments.template, "\", "/", "all" );
		return findNoCase( "/testbox/system/", normalized ) > 0;
	}

	/**
	 * Format a tag context frame as file:line
	 */
	private string function formatFrame( required struct frame ){
		return relativePath( arguments.frame.template ) & ":" & ( arguments.frame.line ?: 0 );
	}

	/**
	 * Shorten an absolute file path by stripping the web/working root to save tokens
	 */
	private string function relativePath( required string path ){
		var normalized = replace( arguments.path, "\", "/", "all" );
		if ( !structKeyExists( variables, "rootPath" ) ) {
			variables.rootPath = "";
			try {
				variables.rootPath = replace( expandPath( "/" ), "\", "/", "all" );
				if ( right( variables.rootPath, 1 ) != "/" ) {
					variables.rootPath &= "/";
				}
			} catch ( any e ) {
				variables.rootPath = "";
			}
		}
		if ( len( variables.rootPath ) > 1 && left( normalized, len( variables.rootPath ) ) == variables.rootPath ) {
			return mid( normalized, len( variables.rootPath ) + 1, len( normalized ) );
		}
		return normalized;
	}

}
