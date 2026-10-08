/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Presentation logic shared by the HTML reporters (Simple, Min, Dot, Doc).
 *
 * Templates stay markup only: anything that needs a function lives here, because the BoxLang
 * transpiler drops tag-form cffunction declarations from .cfm templates (BL-2736).
 */
component accessors="true" {

	/**
	 * The reporter using this helper, used for the editor links it already knows how to build
	 */
	property name="reporter";

	/**
	 * The merged reporter options
	 */
	property name="options" type="struct";

	/**
	 * Absolute path of the folder holding the inlined report assets
	 */
	property name="assetsDir" type="string";

	// Reporter options and their defaults
	variables.DEFAULTS = {
		"aiAssist"    : true,
		"aiProviders" : [
			{
				"id"   : "chatgpt",
				"name" : "ChatGPT",
				"url"  : "https://chatgpt.com/?q={prompt}"
			},
			{
				"id"   : "claude",
				"name" : "Claude",
				"url"  : "https://claude.ai/new?q={prompt}"
			}
		],
		"aiContextLines"   : 5,
		"aiStackFrames"    : 8,
		"aiPrompt"         : "",
		// image attachments up to this size are embedded in the report, 0 turns it off
		"inlineImageMaxKB" : 2048
	};

	// Attachment file extension to the mime type of an image the report can embed
	variables.IMAGE_TYPES = {
		"png"  : "image/png",
		"jpg"  : "image/jpeg",
		"jpeg" : "image/jpeg",
		"gif"  : "image/gif",
		"webp" : "image/webp"
	};

	// Status presentation. The keys are the lowercased spec/suite/bundle statuses TestBox reports.
	variables.STATUSES = {
		"passed" : {
			"key"   : "passed",
			"label" : "Pass",
			"short" : "pass",
			"icon"  : "check-circle-fill"
		},
		"failed" : {
			"key"   : "failed",
			"label" : "Failed",
			"short" : "failed",
			"icon"  : "x-circle-fill"
		},
		"error" : {
			"key"   : "error",
			"label" : "Error",
			"short" : "error",
			"icon"  : "exclamation-octagon-fill"
		},
		"skipped" : {
			"key"   : "skipped",
			"label" : "Skipped",
			"short" : "skipped",
			"icon"  : "dash-circle"
		}
	};

	// File extension to Prism language
	variables.LANGUAGES = {
		"bx"   : "boxlang",
		"bxs"  : "boxlang",
		"bxm"  : "boxlang",
		"cfc"  : "cfscript",
		"cfs"  : "cfscript",
		"cfm"  : "cfscript",
		"cfml" : "cfscript"
	};

	/**
	 * Constructor
	 *
	 * @reporter The reporter rendering the report
	 * @options  The reporter options
	 * @urlScope The url scope (or a struct standing in for it) the report was requested with
	 */
	function init(
		required reporter,
		struct options  = {},
		struct urlScope = {}
	){
		variables.reporter  = arguments.reporter;
		variables.urlScope  = arguments.urlScope;
		variables.options   = mergeOptions( arguments.options );
		variables.assetsDir = expandPath( "/testbox/system/reports/assets" );
		variables.webRoot   = normalizePath( expandPath( "/" ) );
		return this;
	}

	/**
	 * Merge the incoming reporter options with the defaults
	 */
	struct function mergeOptions( required struct incoming ){
		var merged = duplicate( variables.DEFAULTS );
		for ( var thisKey in merged ) {
			if ( structKeyExists( arguments.incoming, thisKey ) && !isNull( arguments.incoming[ thisKey ] ) ) {
				merged[ thisKey ] = arguments.incoming[ thisKey ];
			}
		}
		// the url can switch the feature off too: ?aiAssist=false
		if ( structKeyExists( variables.urlScope, "aiAssist" ) && isBoolean( variables.urlScope.aiAssist ) ) {
			merged.aiAssist = variables.urlScope.aiAssist;
		}
		merged.aiAssist         = isBoolean( merged.aiAssist ) && merged.aiAssist;
		merged.aiContextLines   = max( 0, val( merged.aiContextLines ) );
		merged.aiStackFrames    = max( 1, val( merged.aiStackFrames ) );
		merged.inlineImageMaxKB = max( 0, val( merged.inlineImageMaxKB ) );
		return merged;
	}

	/************************************** ASSETS ****************************************/

	/**
	 * Read one of the report assets so it can be inlined in the page
	 *
	 * @path The path relative to the assets folder, ex: vendor/alpine.min.js
	 */
	string function asset( required string path ){
		var file = variables.assetsDir & "/" & arguments.path;
		if ( !fileExists( file ) ) {
			throw(
				type    = "TestBox.ReportAssetNotFound",
				message = "The report asset [#arguments.path#] does not exist in [#variables.assetsDir#]"
			);
		}
		return fileRead( file, "utf-8" );
	}

	/**
	 * Get an asset as a data URI
	 *
	 * @path The path relative to the assets folder
	 * @mime The mime type
	 */
	string function dataURI( required string path, string mime = "image/svg+xml" ){
		return "data:#arguments.mime#;base64,#toBase64( fileReadBinary( variables.assetsDir & "/" & arguments.path ) )#";
	}

	/**
	 * A tiny status favicon so a background tab shows the verdict
	 *
	 * @bad Is the run red?
	 */
	string function faviconURI( required boolean bad ){
		var color = arguments.bad ? "%23c8243b" : "%2317824a";
		var mark  = arguments.bad ? "M10 10l12 12M22 10L10 22" : "M9 17l5 5 9-11";
		var svg   = "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'><circle cx='16' cy='16' r='15' fill='#color#'/><path d='#mark#' fill='none' stroke='white' stroke-width='3.4' stroke-linecap='round' stroke-linejoin='round'/></svg>";
		return "data:image/svg+xml," & replace(
			replace( svg, "<", "%3C", "all" ),
			">",
			"%3E",
			"all"
		);
	}

	/**
	 * Serialize a struct so it can sit inside a script tag without being able to close it
	 */
	string function jsonForHtml( required any data ){
		// built with chr(92): a "\u003c" literal is turned back into "<" by some engines
		var slash = chr( 92 );
		return replace(
			replace(
				serializeJSON( arguments.data ),
				"<",
				slash & "u003c",
				"all"
			),
			">",
			slash & "u003e",
			"all"
		);
	}

	/************************************** STATUS & VERDICT ****************************************/

	/**
	 * Presentation data for a status, unknown statuses are treated as skipped
	 *
	 * @status A TestBox status: Passed, Failed, Error, Skipped
	 */
	struct function status( required string status ){
		var key = lCase( trim( arguments.status ) );
		return structKeyExists( variables.STATUSES, key ) ? variables.STATUSES[ key ] : variables.STATUSES.skipped;
	}

	/**
	 * The four statuses in display order
	 */
	array function statusList(){
		return [
			variables.STATUSES.passed,
			variables.STATUSES.failed,
			variables.STATUSES.error,
			variables.STATUSES.skipped
		];
	}

	/**
	 * Count based wording
	 */
	string function plural(
		required numeric count,
		required string singular,
		string plural = ""
	){
		var word = arguments.count == 1 ? arguments.singular : (
			len( arguments.plural ) ? arguments.plural : arguments.singular & "s"
		);
		return "#arguments.count# #word#";
	}

	/**
	 * The number of specs of a bundle in a status
	 *
	 * @bundle The bundle stats
	 * @status A status key: passed, failed, error, skipped
	 */
	numeric function countOf( required struct bundle, required string status ){
		switch ( arguments.status ) {
			case "passed":
				return arguments.bundle.totalPass;
			case "failed":
				return arguments.bundle.totalFail;
			case "error":
				return arguments.bundle.totalError;
			default:
				return arguments.bundle.totalSkipped;
		}
	}

	/**
	 * Is this spec failed or errored?
	 */
	boolean function isProblem( required struct spec ){
		return listFindNoCase( "failed,error", arguments.spec.status ) > 0;
	}

	/**
	 * Does a bundle have failures, errors or a global exception?
	 */
	boolean function bundleHasProblems( required struct bundle ){
		return arguments.bundle.totalFail + arguments.bundle.totalError > 0 || !isSimpleValue(
			arguments.bundle.globalException
		);
	}

	/**
	 * The bundles that carry a global exception (compile errors, beforeAll failures...)
	 *
	 * @bundles The bundle stats
	 */
	array function exceptions( required array bundles ){
		return arguments.bundles.filter( function( thisBundle ){
			return !isSimpleValue( thisBundle.globalException );
		} );
	}

	/**
	 * The verdict shown at the top of every report
	 *
	 * @results The TestResult
	 */
	struct function verdict( required results ){
		var r              = arguments.results;
		var exceptionCount = exceptions( r.getBundleStats() ).len();
		// a bundle that fails to start can leave a negative error total, never let that hide a problem
		var failed         = max( 0, r.getTotalFail() );
		var errored        = max( 0, r.getTotalError() );
		var bad            = failed + errored + exceptionCount > 0;
		var parts          = [];

		if ( exceptionCount ) {
			parts.append( plural( exceptionCount, "bundle exception" ) );
		}
		if ( failed ) {
			parts.append( plural( failed, "failure" ) );
		}
		if ( errored ) {
			parts.append( plural( errored, "error" ) );
		}

		return {
			"bad"      : bad,
			"title"    : bad ? arrayToList( parts, ", " ) : "All #plural( r.getTotalSpecs(), "spec" )# passed",
			"subtitle" : ( bad ? "#r.getTotalPass()# passed, " : "" ) & "#r.getTotalSkipped()# skipped, in #duration( r.getTotalDuration() )#",
			"counts"   : {
				"passed"  : max( 0, r.getTotalPass() ),
				"failed"  : failed,
				"error"   : errored,
				"skipped" : max( 0, r.getTotalSkipped() )
			},
			"tabTitle" : bad ? "FAILED #failed + errored + exceptionCount#" : "PASSED #r.getTotalPass()#",
			"percent"  : {
				"passed"  : percentOf( r.getTotalPass(), r.getTotalSpecs() ),
				"failed"  : percentOf( failed, r.getTotalSpecs() ),
				"error"   : percentOf( errored, r.getTotalSpecs() ),
				"skipped" : percentOf( r.getTotalSkipped(), r.getTotalSpecs() )
			}
		};
	}

	/**
	 * A count as a percentage of a total, 0 when there is nothing to divide by
	 */
	numeric function percentOf( required numeric count, required numeric total ){
		return arguments.total > 0 ? round( ( arguments.count / arguments.total ) * 1000 ) / 10 : 0;
	}

	/**
	 * Milliseconds in a friendly unit
	 */
	string function duration( required numeric ms ){
		return arguments.ms >= 1000 ? "#numberFormat( arguments.ms / 1000, "9.99" )# s" : "#numberFormat( arguments.ms )# ms";
	}

	/************************************** RUN LINKS ****************************************/

	/**
	 * Build the url that re-runs the report scoped to a bundle, suite or spec.
	 * It is a plain link to the runner, so a refresh re-runs the requested target.
	 * Only the requested target is included; all other runner options use their defaults.
	 *
	 * @bundle The bundle path to run
	 * @suite  The suite name to run
	 * @spec   The spec id to run
	 */
	string function runURL(
		string bundle = "",
		string suite  = "",
		string spec   = ""
	){
		var params = [];
		if ( !len( arguments.bundle ) && !len( arguments.suite ) && !len( arguments.spec ) ) {
			return "?";
		}

		if ( len( arguments.bundle ) ) {
			params.append( "testBundles=#encodeQuery( arguments.bundle )#" );
		}
		if ( len( arguments.suite ) ) {
			params.append( "testSuites=#encodeQuery( arguments.suite )#" );
		}
		if ( len( arguments.spec ) ) {
			params.append( "testSpecs=#encodeQuery( arguments.spec )#" );
		}

		return "?" & arrayToList( params, "&" );
	}

	/**
	 * Build the url that re-runs only what failed or errored in this run, from TestResult.getFailedTargets().
	 * The report is the state: no file is kept between runs. When the spec ids would make the url longer than
	 * maxLength, the url runs the failed bundles whole instead. Bundles that failed outside of a spec are not
	 * included: they are broken, not failed.
	 *
	 * @targets   The struct returned by TestResult.getFailedTargets()
	 * @maxLength The longest url that still lists the spec ids
	 *
	 * @return The url, or an empty string when nothing failed
	 */
	string function failedRunURL( required struct targets, numeric maxLength = 2000 ){
		if ( !arrayLen( arguments.targets.bundles ) ) {
			return "";
		}
		var bundles   = "testBundles=#encodeQuery( arrayToList( arguments.targets.bundles ) )#";
		var withSpecs = "?#bundles#&testSpecs=#encodeQuery( arrayToList( arguments.targets.specs ) )#";
		return len( withSpecs ) <= arguments.maxLength ? withSpecs : "?#bundles#";
	}

	/**
	 * Should a bundle be shown? A ?testBundles= list narrows the report to those bundles.
	 *
	 * @bundle The bundle stats
	 */
	boolean function includesBundle( required struct bundle ){
		var only = structKeyExists( variables.urlScope, "testBundles" ) ? variables.urlScope.testBundles : "";
		return !len( only ) || listFindNoCase( only, arguments.bundle.path ) > 0;
	}

	/**
	 * Is this bundle explicitly selected by the current run scope?
	 *
	 * @bundle The bundle stats
	 */
	boolean function isBundleScoped( required struct bundle ){
		var only = structKeyExists( variables.urlScope, "testBundles" ) ? variables.urlScope.testBundles : "";
		return len( only ) > 0 && listFindNoCase( only, arguments.bundle.path ) > 0;
	}

	/**
	 * Link that opens a file in the editor chosen with url.editor
	 */
	string function editorURL( required string template, required numeric line ){
		return variables.reporter.openInEditorURL(
			arguments.template,
			arguments.line,
			structKeyExists( variables.urlScope, "editor" ) && len( variables.urlScope.editor ) ? variables.urlScope.editor : "vscode"
		);
	}

	/**
	 * Reduce an identifier to characters that are safe in an html id, a url and a javascript string.
	 * Spec and bundle ids are hashes already, this guards ids that come from configuration.
	 */
	string function safeId( required string id ){
		return reReplace( arguments.id, "[^A-Za-z0-9_-]", "", "all" );
	}

	/**
	 * Make a url safe to put inside a double quoted html attribute.
	 * Urls built by runURL() are already percent-encoded, only the ampersands need their entity.
	 */
	string function href( required string url ){
		return replace( arguments.url, "&", "&amp;", "all" );
	}

	/************************************** FAILURES ****************************************/

	/**
	 * The message of a failed or errored spec
	 */
	string function specMessage( required struct spec ){
		var kind = lCase( arguments.spec.status );
		if ( kind == "failed" ) {
			return arguments.spec.failMessage;
		}
		if ( kind == "error" && isStruct( arguments.spec.error ) ) {
			return ( arguments.spec.error.message ?: "" ) & ( arguments.spec.error.detail ?: "" );
		}
		return "";
	}

	/**
	 * Flatten every failed and errored spec of the run, in run order.
	 * Each entry carries the bundle, the suite names leading to the spec and the spec itself.
	 *
	 * @bundles The bundle stats
	 */
	array function failures( required array bundles ){
		// Adobe passes arrays by value, so the recursion collects into a struct, which is shared by reference
		var collector = { "items" : [] };
		for ( var thisBundle in arguments.bundles ) {
			collectFailures(
				thisBundle,
				thisBundle.suiteStats,
				[],
				collector
			);
		}
		return collector.items;
	}

	/**
	 * Recursive helper of failures()
	 */
	private void function collectFailures(
		required struct bundle,
		required array suites,
		required array parents,
		required struct collector
	){
		for ( var thisSuite in arguments.suites ) {
			var path = duplicate( arguments.parents );
			path.append( thisSuite.name );
			for ( var thisSpec in thisSuite.specStats ) {
				if ( isProblem( thisSpec ) ) {
					arguments.collector.items.append( {
						"bundle"  : arguments.bundle,
						"suites"  : path,
						"crumb"   : arrayToList( path, " > " ),
						"spec"    : thisSpec,
						"message" : specMessage( thisSpec )
					} );
				}
			}
			collectFailures(
				arguments.bundle,
				thisSuite.suiteStats,
				path,
				arguments.collector
			);
		}
	}

	/**
	 * URL-encode a query string value the same way on every engine. Adobe and Lucee also escape the
	 * unreserved characters . - _ ~ which only makes links noisier, so those are put back.
	 *
	 * @value The value to encode
	 */
	private string function encodeQuery( required string value ){
		var encoded = urlEncodedFormat( arguments.value );
		encoded     = replace( encoded, "%2E", ".", "all" );
		encoded     = replace( encoded, "%2D", "-", "all" );
		encoded     = replace( encoded, "%5F", "_", "all" );
		return replace( encoded, "%7E", "~", "all" );
	}

	/**
	 * Flatten every spec of a bundle in run order. Each entry carries the suite names leading to the spec.
	 *
	 * @bundle The bundle stats
	 */
	array function specs( required struct bundle ){
		var collector = { "items" : [] };
		collectSpecs( arguments.bundle.suiteStats, [], collector );
		return collector.items;
	}

	/**
	 * Recursive helper of specs()
	 */
	private void function collectSpecs(
		required array suites,
		required array parents,
		required struct collector
	){
		for ( var thisSuite in arguments.suites ) {
			var path = duplicate( arguments.parents );
			path.append( thisSuite.name );
			for ( var thisSpec in thisSuite.specStats ) {
				arguments.collector.items.append( { "crumb" : arrayToList( path, " > " ), "spec" : thisSpec } );
			}
			collectSpecs(
				thisSuite.suiteStats,
				path,
				arguments.collector
			);
		}
	}

	/**
	 * The frame that matters for a failed or errored spec: the first one in your code, not in TestBox.
	 * Failures report it in failOrigin, errors in the exception's tag context.
	 *
	 * @spec The spec stats
	 *
	 * @return A struct with template, line and relative, or an empty struct if there is no frame
	 */
	struct function origin( required struct spec ){
		var specFrames = frames( arguments.spec );
		var userFrames = specFrames.filter( function( thisFrame ){
			return thisFrame.user;
		} );
		return arrayLen( userFrames ) ? userFrames[ 1 ] : ( arrayLen( specFrames ) ? specFrames[ 1 ] : {} );
	}

	/**
	 * All frames of a failed or errored spec, user code flagged
	 *
	 * @spec The spec stats
	 */
	array function frames( required struct spec ){
		var context = [];
		if ( isArray( arguments.spec.failOrigin ) && arrayLen( arguments.spec.failOrigin ) ) {
			context = arguments.spec.failOrigin;
		} else if (
			isStruct( arguments.spec.error ) && structKeyExists( arguments.spec.error, "tagContext" ) && isArray(
				arguments.spec.error.tagContext
			)
		) {
			context = arguments.spec.error.tagContext;
		}
		return framesOf( context );
	}

	/**
	 * Normalize a tag context array into frames
	 *
	 * @context The tag context of an exception
	 */
	array function framesOf( required array context ){
		var found = [];
		for ( var thisFrame in arguments.context ) {
			if ( !isStruct( thisFrame ) || !structKeyExists( thisFrame, "template" ) ) {
				continue;
			}
			var template = normalizePath( thisFrame.template );
			found.append( {
				"template" : thisFrame.template,
				"relative" : relativePath( template ),
				"line"     : val( thisFrame.line ?: 0 ),
				"user"     : !isInternal( template ),
				"label"    : thisFrame.id ?: ""
			} );
		}
		return found;
	}

	/**
	 * Is the template part of TestBox's own engine?
	 */
	boolean function isInternal( required string template ){
		return findNoCase( "/testbox/system/", arguments.template ) > 0;
	}

	/**
	 * Read the lines of code around a line.
	 *
	 * @template The absolute file path
	 * @line     The line to center on
	 * @context  The number of lines to show before and after it
	 *
	 * @return An array of { n, text, hit }, empty when the file can't be read
	 */
	array function snippet(
		required string template,
		required numeric line,
		numeric context = 4
	){
		if ( arguments.line < 1 || !fileExists( arguments.template ) ) {
			return [];
		}
		// don't slurp huge generated files
		if ( getFileInfo( arguments.template ).size > 1048576 ) {
			return [];
		}

		var lines = listToArray(
			replace(
				fileRead( arguments.template, "utf-8" ),
				chr( 13 ),
				"",
				"all"
			),
			chr( 10 ),
			true
		);
		var first = max( 1, arguments.line - arguments.context );
		var last  = min( arrayLen( lines ), arguments.line + arguments.context );
		var out   = [];

		// remove the indentation every shown line shares, deeply nested specs would push the code off screen
		var indent = 9999;
		for ( var n = first; n <= last; n++ ) {
			if ( len( trim( lines[ n ] ) ) ) {
				indent = min( indent, len( lines[ n ] ) - len( reReplace( lines[ n ], "^[ \t]+", "" ) ) );
			}
		}
		if ( indent == 9999 ) {
			indent = 0;
		}

		for ( var n = first; n <= last; n++ ) {
			out.append( {
				"n"    : n,
				"text" : len( lines[ n ] ) >= indent ? mid( lines[ n ], indent + 1, len( lines[ n ] ) ) : lines[ n ],
				"hit"  : n == arguments.line
			} );
		}
		return out;
	}

	/**
	 * The code snippet of the frame that matters for a spec
	 *
	 * @spec    The spec stats
	 * @context Lines before and after the failing line, defaults to the aiContextLines option
	 */
	struct function codeFor( required struct spec, numeric context = -1 ){
		var frame = origin( arguments.spec );
		if ( structIsEmpty( frame ) ) {
			return {};
		}
		var lines = snippet(
			frame.template,
			frame.line,
			arguments.context >= 0 ? arguments.context : variables.options.aiContextLines
		);
		return {
			"template" : frame.template,
			"relative" : frame.relative,
			"line"     : frame.line,
			"lang"     : languageOf( frame.template ),
			"lines"    : lines
		};
	}

	/**
	 * The Prism language for a file
	 */
	string function languageOf( required string path ){
		var ext = lCase( listLast( arguments.path, "." ) );
		return structKeyExists( variables.LANGUAGES, ext ) ? variables.LANGUAGES[ ext ] : "clike";
	}

	/************************************** ASK AI ****************************************/

	/**
	 * Build the prompt that asks an AI assistant for help with a failure
	 *
	 * @failure One entry of failures()
	 * @results The TestResult
	 * @testbox The TestBox instance, for its version
	 */
	string function prompt(
		required struct failure,
		required results,
		required testbox
	){
		var spec       = arguments.failure.spec;
		var outcome    = lCase( spec.status ) == "error" ? "errored" : "failed";
		var code       = codeFor( spec );
		var specFrames = frames( spec );
		var rerun      = rerunCommand( arguments.failure );
		var out        = [];

		specFrames = specFrames.slice( 1, min( variables.options.aiStackFrames, arrayLen( specFrames ) ) );

		var intro = "I am running tests with TestBox #arguments.testbox.getVersion()# on #arguments.results.getCFMLEngine()# #arguments.results.getCFMLEngineVersion()#. One spec #outcome#.";

		// a custom template can reshape the whole prompt
		if ( len( variables.options.aiPrompt ) ) {
			var values = {
				"{intro}"   : intro,
				"{spec}"    : "#arguments.failure.crumb# > #spec.displayName#",
				"{status}"  : spec.status,
				"{message}" : arguments.failure.message,
				"{code}"    : codeBlock( code ),
				"{stack}"   : stackBlock( specFrames ),
				"{rerun}"   : rerun
			};
			var custom = variables.options.aiPrompt;
			for ( var thisKey in values ) {
				custom = replace( custom, thisKey, values[ thisKey ], "all" );
			}
			return custom;
		}

		out.append( intro );
		out.append( "Find the likely root cause and suggest a fix. Say whether the test or the code under test is wrong." );
		out.append( "" );
		out.append( "Spec: #arguments.failure.bundle.path# > #arguments.failure.crumb# > #spec.displayName#" );
		out.append( "Status: #lCase( spec.status )#" );
		out.append( "Message: #arguments.failure.message#" );
		if ( !structIsEmpty( code ) && arrayLen( code.lines ) ) {
			out.append( "" );
			out.append( codeBlock( code ) );
		}
		if ( arrayLen( specFrames ) ) {
			out.append( "" );
			out.append( stackBlock( specFrames ) );
		}
		out.append( "" );
		out.append( "Re-run only this spec:" );
		out.append( "  #rerun#" );

		return arrayToList( out, chr( 10 ) );
	}

	/**
	 * The same failure as a small JSON document, in the shape the AgentReporter uses
	 *
	 * @failure One entry of failures()
	 */
	string function agentJSON( required struct failure ){
		var spec  = arguments.failure.spec;
		var where = origin( spec );
		var data  = [
			"bundle" : arguments.failure.bundle.path,
			"spec"   : "#arguments.failure.crumb# > #spec.displayName#",
			"status" : lCase( spec.status ),
			"message": arguments.failure.message
		];
		if ( !structIsEmpty( where ) ) {
			data[ "at" ] = "#where.relative#:#where.line#";
		}
		var specFrames  = frames( spec );
		data[ "stack" ] = specFrames
			.slice( 1, min( 3, arrayLen( specFrames ) ) )
			.map( function( thisFrame ){
				return "#thisFrame.relative#:#thisFrame.line#";
			} );
		data[ "rerun" ] = rerunCommand( arguments.failure );
		return serializeJSON( data );
	}

	/**
	 * The BoxLang runner command that re-runs just this spec
	 */
	string function rerunCommand( required struct failure ){
		return "./testbox/run --bundles=#arguments.failure.bundle.path# --filter-specs=""#arguments.failure.spec.displayName#""";
	}

	/**
	 * A fenced code block for a snippet
	 */
	private string function codeBlock( required struct code ){
		if ( structIsEmpty( arguments.code ) || !arrayLen( arguments.code.lines ) ) {
			return "";
		}
		var text = arguments.code.lines
			.map( function( thisLine ){
				return thisLine.text;
			} )
			.toList( chr( 10 ) );
		return "Code (#arguments.code.relative#:#arguments.code.line#):#chr( 10 )#```#arguments.code.lang#" & chr(
			10
		) & text & chr( 10 ) & "```";
	}

	/**
	 * The stack section of a prompt
	 */
	private string function stackBlock( required array frames ){
		if ( !arrayLen( arguments.frames ) ) {
			return "";
		}
		return "Stack (your code first):#chr( 10 )#" & arguments.frames
			.map( function( thisFrame ){
				return "  #thisFrame.relative#:#thisFrame.line#";
			} )
			.toList( chr( 10 ) );
	}

	/************************************** COVERAGE ****************************************/

	/**
	 * Map a coverage percentage to a status tone using the project's coverage thresholds
	 *
	 * @percent The percentage 0-100
	 * @testbox The TestBox instance
	 */
	string function coverageTone( required numeric percent, required testbox ){
		var tresholds = arguments.testbox.getCoverageService().getCoverageOptions().coverageTresholds;
		return new testbox.system.coverage.browser.CodeBrowser( tresholds ).percentToContextualClass(
			arguments.percent
		);
	}

	/************************************** ATTACHMENTS ****************************************/

	/**
	 * The files attached to a spec, ready to render. Images up to the inlineImageMaxKB option are
	 * embedded as data URIs: a page served over http cannot open file:// links, and a saved report
	 * keeps its screenshots. Each view has a kind (image, video, trace or file), the src of an
	 * embedded image and the command that opens a trace, both empty when they do not apply.
	 *
	 * @spec The spec stats
	 *
	 * @return An array of { name, type, path, kind, href, src, command } structs
	 */
	array function attachments( required struct spec ){
		var views = [];
		var list  = arguments.spec.attachments ?: [];
		if ( !isArray( list ) ) {
			return views;
		}
		for ( var thisAttachment in list ) {
			arrayAppend( views, attachmentView( thisAttachment ) );
		}
		return views;
	}

	/**
	 * Describe one attachment for the report
	 *
	 * @attachment The { path, type, name } attachment
	 */
	struct function attachmentView( required struct attachment ){
		var path      = arguments.attachment.path ?: "";
		var type      = lCase( arguments.attachment.type ?: "" );
		var extension = lCase( listLast( getFileFromPath( path ), "." ) );
		var href      = "";
		if ( len( path ) ) {
			var file = createObject( "java", "java.io.File" ).init( path );
			href     = file.toURI().toString();
		}
		var view = {
			"name"    : arguments.attachment.name ?: getFileFromPath( path ),
			"type"    : type,
			"path"    : path,
			"kind"    : "file",
			"href"    : href,
			"src"     : "",
			"command" : ""
		};
		if ( structKeyExists( variables.IMAGE_TYPES, extension ) ) {
			view.kind = "image";
			view.src  = imageDataURI( path, variables.IMAGE_TYPES[ extension ] );
		} else if ( type == "video" || listFindNoCase( "webm,mp4", extension ) ) {
			view.kind = "video";
		} else if ( type == "trace" ) {
			view.kind    = "trace";
			view.command = "bxPlaywright show-trace ""#path#""";
		}
		return view;
	}

	/**
	 * An image file as a data URI, or an empty string when it is missing, unreadable or larger than
	 * the inlineImageMaxKB option
	 *
	 * @path The absolute path of the image
	 * @mime The mime type of the image
	 */
	string function imageDataURI( required string path, required string mime ){
		var maxBytes = variables.options.inlineImageMaxKB * 1024;
		if ( maxBytes <= 0 || !len( arguments.path ) || !fileExists( arguments.path ) ) {
			return "";
		}
		try {
			var file = createObject( "java", "java.io.File" ).init( arguments.path );
			if ( file.length() > maxBytes ) {
				return "";
			}
			return "data:#arguments.mime#;base64,#toBase64( fileReadBinary( arguments.path ) )#";
		} catch ( any e ) {
			return "";
		}
	}

	/************************************** PATHS ****************************************/

	/**
	 * Normalize a file path to forward slashes
	 */
	string function normalizePath( required string path ){
		return replace( arguments.path, "\", "/", "all" );
	}

	/**
	 * Shorten a path by removing the web root, it saves room and keeps reports portable
	 */
	string function relativePath( required string path ){
		var normalized = normalizePath( arguments.path );
		var root       = variables.webRoot;
		if ( right( root, 1 ) != "/" ) {
			root &= "/";
		}
		if ( len( root ) > 1 && left( normalized, len( root ) ) == root ) {
			return mid( normalized, len( root ) + 1, len( normalized ) );
		}
		return normalized;
	}

}
