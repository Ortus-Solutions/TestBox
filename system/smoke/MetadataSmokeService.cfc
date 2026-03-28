/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Optional reflection smoke checks: validate component metadata (and optionally dummy-invoke public/remote
 * methods with synthetic required args). Not line coverage and not proof of correct behavior.
 * Use TestBox.getMetadataSmokeService(); renderRunnerEmbed() feeds the Simple reporter; renderReport() renders full HTML.
 */
component accessors="true" {

	public struct function runSmokeFromManifestFile(
		required string manifestAbsolutePath,
		boolean runInvocations = false
	) {
		var out = _initSmokeResult();

		if ( !fileExists( arguments.manifestAbsolutePath ) ) {
			out.success = false;
			out.errorMessage = "Manifest not found: #arguments.manifestAbsolutePath#";
			return out;
		}

		var raw = deserializeJSON( fileRead( arguments.manifestAbsolutePath ) );
		var components = parseManifestItems( raw );
		return _runSmokeForComponentPaths( out, components, arguments.runInvocations );
	}

	/**
	 * Same checks as a manifest file using in-memory data: an array of dotted paths, or an envelope struct with `items` (see parseManifestItems).
	 */
	public struct function runSmokeFromManifestItems(
		required any manifestItemsOrRaw,
		boolean runInvocations = false
	) {
		var out = _initSmokeResult();
		var components = isArray( arguments.manifestItemsOrRaw ) ? arguments.manifestItemsOrRaw : parseManifestItems( arguments.manifestItemsOrRaw );
		return _runSmokeForComponentPaths( out, components, arguments.runInvocations );
	}

	/**
	 * Run metadata smoke for a single component (minimal memory; suitable for one CFC per request).
	 */
	public struct function runSmokeForSingleComponent(
		required string componentPath,
		boolean runInvocations = false
	) {
		var out = _initSmokeResult();
		_processOneComponentPath( out, trim( arguments.componentPath ), arguments.runInvocations );
		return out;
	}

	/**
	 * Walk *.cfc under a source root and process each component in order without building a full manifest array in memory.
	 * Uses the same exclusion rules as scanDirectoryToManifestItems.
	 */
	public struct function runSmokeFromDirectoryInline(
		required string absoluteComponentRoot,
		required string dottedPrefix,
		struct options = {},
		boolean runInvocations = false
	) {
		var out = _initSmokeResult();
		var rootPath = normalizeDirectoryPath( arguments.absoluteComponentRoot );
		if ( !directoryExists( rootPath ) ) {
			out.success = false;
			out.errorMessage = "Component root not found: #rootPath#";
			return out;
		}

		var excludeFileNames = structKeyExists( arguments.options, "excludeFileNames" ) ? arguments.options.excludeFileNames : "";
		var excludePrefixes = structKeyExists( arguments.options, "excludeRelativePathPrefixes" ) ? arguments.options.excludeRelativePathPrefixes : "";
		var excludeIds = structKeyExists( arguments.options, "excludeComponentIds" ) ? arguments.options.excludeComponentIds : "";

		var files = directoryList( rootPath, true, "path", "*.cfc" );
		arraySort( files, "textnocase", "asc" );

		for ( var f in files ) {
			var fileName = lCase( listLast( f, "\/" ) );
			if ( len( excludeFileNames ) && listFindNoCase( excludeFileNames, fileName ) ) {
				continue;
			}

			var rel = replaceNoCase( f, rootPath, "", "one" );
			rel = reReplace( rel, "^[\\/]+", "" );

			if ( len( excludePrefixes ) ) {
				var skipByPrefix = false;
				for ( var pfx in listToArray( excludePrefixes ) ) {
					pfx = trim( pfx );
					if ( !len( pfx ) ) {
						continue;
					}
					var pfxRe = "^" & reReplace( pfx, "([\.\[\]\{\}\(\)\*\+\?\^\$\|\\])", "\\$1", "all" ) & "[\\/]";
					if ( reFindNoCase( pfxRe, rel ) ) {
						skipByPrefix = true;
						break;
					}
				}
				if ( skipByPrefix ) {
					continue;
				}
			}

			rel = reReplaceNoCase( rel, "\.cfc$", "" );
			rel = replace( rel, "\", ".", "all" );
			rel = replace( rel, "/", ".", "all" );
			var componentId = arguments.dottedPrefix & "." & rel;

			if ( len( excludeIds ) && listFindNoCase( excludeIds, componentId ) ) {
				continue;
			}

			_processOneComponentPath( out, componentId, arguments.runInvocations );
			if ( !out.success ) {
				return out;
			}
		}

		return out;
	}

	private struct function _initSmokeResult() {
		return {
			"success"             : true,
			"errorMessage"        : "",
			"componentCount"      : 0,
			"discovered"          : 0,
			"attempted"           : 0,
			"skippedComponents"   : []
		};
	}

	private struct function _runSmokeForComponentPaths(
		required struct out,
		required array componentPaths,
		boolean runInvocations = false
	) {
		for ( var componentPath in arguments.componentPaths ) {
			_processOneComponentPath( arguments.out, componentPath, arguments.runInvocations );
			if ( !arguments.out.success ) {
				return arguments.out;
			}
		}
		return arguments.out;
	}

	private function _processOneComponentPath(
		required struct out,
		required string componentPath,
		boolean runInvocations = false
	) {
		arguments.out.componentCount++;

		var md = {};
		try {
			md = getComponentMetadata( arguments.componentPath );
		} catch ( any mdErr ) {
			arrayAppend( arguments.out.skippedComponents, arguments.componentPath );
			return;
		}

		var instance = "";
		var canInvoke = false;
		if ( arguments.runInvocations ) {
			try {
				instance = createObject( "component", arguments.componentPath );
				canInvoke = true;
			} catch ( any createErr ) {
				canInvoke = false;
			}
		}

		if ( !structKeyExists( md, "functions" ) || !isArray( md.functions ) ) {
			return;
		}

		for ( var fn in md.functions ) {
			if ( !structKeyExists( fn, "name" ) || shouldIgnoreFunction( fn ) ) {
				continue;
			}

			if ( !len( trim( fn.name ) ) ) {
				arguments.out.success = false;
				arguments.out.errorMessage = "Function names must not be blank for #arguments.componentPath#.";
				return;
			}
			if ( !structKeyExists( fn, "access" ) ) {
				arguments.out.success = false;
				arguments.out.errorMessage = "Function access metadata missing for #arguments.componentPath#.#fn.name#.";
				return;
			}
			if ( arrayFindNoCase( [ "public", "remote" ], fn.access ) EQ 0 ) {
				arguments.out.success = false;
				arguments.out.errorMessage = "Only public/remote functions should be audited: #arguments.componentPath#.#fn.name#.";
				return;
			}

			arguments.out.discovered++;
			if ( arguments.runInvocations && canInvoke ) {
				try {
					invoke( instance, fn.name, buildArgsForFunction( fn ) );
				} catch ( any invokeErr ) {
				}
			}
			arguments.out.attempted++;
		}
	}

	public array function parseManifestItems( required any rawJson ) {
		if ( isArray( arguments.rawJson ) ) {
			return arguments.rawJson;
		}
		if ( isStruct( arguments.rawJson ) && structKeyExists( arguments.rawJson, "items" ) && isArray( arguments.rawJson.items ) ) {
			return arguments.rawJson.items;
		}
		return [];
	}

	public array function scanDirectoryToManifestItems(
		required string absoluteComponentRoot,
		required string dottedPrefix,
		struct options = {}
	) {
		var excludeFileNames = structKeyExists( arguments.options, "excludeFileNames" ) ? arguments.options.excludeFileNames : "";
		var excludePrefixes = structKeyExists( arguments.options, "excludeRelativePathPrefixes" ) ? arguments.options.excludeRelativePathPrefixes : "";
		var excludeIds = structKeyExists( arguments.options, "excludeComponentIds" ) ? arguments.options.excludeComponentIds : "";

		var rootPath = normalizeDirectoryPath( arguments.absoluteComponentRoot );
		var files = directoryList( rootPath, true, "path", "*.cfc" );
		arraySort( files, "textnocase", "asc" );
		var items = [];

		for ( var f in files ) {
			var fileName = lCase( listLast( f, "\/" ) );
			if ( len( excludeFileNames ) && listFindNoCase( excludeFileNames, fileName ) ) {
				continue;
			}

			var rel = replaceNoCase( f, rootPath, "", "one" );
			rel = reReplace( rel, "^[\\/]+", "" );

			if ( len( excludePrefixes ) ) {
				var skipByPrefix = false;
				for ( var pfx in listToArray( excludePrefixes ) ) {
					pfx = trim( pfx );
					if ( !len( pfx ) ) {
						continue;
					}
					var pfxRe = "^" & reReplace( pfx, "([\.\[\]\{\}\(\)\*\+\?\^\$\|\\])", "\\$1", "all" ) & "[\\/]";
					if ( reFindNoCase( pfxRe, rel ) ) {
						skipByPrefix = true;
						break;
					}
				}
				if ( skipByPrefix ) {
					continue;
				}
			}

			rel = reReplaceNoCase( rel, "\.cfc$", "" );
			rel = replace( rel, "\", ".", "all" );
			rel = replace( rel, "/", ".", "all" );
			var componentId = arguments.dottedPrefix & "." & rel;

			if ( len( excludeIds ) && listFindNoCase( excludeIds, componentId ) ) {
				continue;
			}

			arrayAppend( items, componentId );
		}

		return items;
	}

	public void function writeManifestEnvelope(
		required string outputAbsolutePath,
		required array items,
		struct envelope = {}
	) {
		var desc = structKeyExists( arguments.envelope, "description" ) ? arguments.envelope.description : "Component manifest for metadata smoke checks.";
		var lim = structKeyExists( arguments.envelope, "limitations" ) && isArray( arguments.envelope.limitations )
			? arguments.envelope.limitations
			: [];
		var manifest = {
			"generatedAt" : createObject( "java", "java.time.Instant" ).now().toString(),
			"description" : desc,
			"limitations" : lim,
			"items"       : arguments.items
		};
		fileWrite( arguments.outputAbsolutePath, serializeJSON( manifest ) );
	}

	public boolean function shouldIgnoreFunction( required struct fnMeta ) {
		if ( !structKeyExists( arguments.fnMeta, "access" ) ) {
			return true;
		}
		if ( arrayFindNoCase( [ "public", "remote" ], arguments.fnMeta.access ) EQ 0 ) {
			return true;
		}
		if ( !structKeyExists( arguments.fnMeta, "name" ) ) {
			return true;
		}
		var ignored = [ "init", "onmissingmethod" ];
		return arrayFindNoCase( ignored, arguments.fnMeta.name ) GT 0;
	}

	public struct function buildArgsForFunction( required struct fnMeta ) {
		var args = {};
		if ( !structKeyExists( arguments.fnMeta, "parameters" ) || !isArray( arguments.fnMeta.parameters ) ) {
			return args;
		}
		for ( var p in arguments.fnMeta.parameters ) {
			if ( !structKeyExists( p, "name" ) || !structKeyExists( p, "required" ) || !p.required ) {
				continue;
			}
			var pType = structKeyExists( p, "type" ) ? p.type : "any";
			args[ p.name ] = defaultValueForType( pType );
		}
		return args;
	}

	public any function defaultValueForType( required string typeName ) {
		var t = lCase( trim( arguments.typeName ) );
		switch ( t ) {
			case "numeric":
			case "number":
			case "int":
			case "integer":
			case "long":
			case "float":
			case "double":
				return 0;
			case "boolean":
			case "bool":
				return false;
			case "string":
			case "uuid":
			case "guid":
				return "";
			case "array":
				return [];
			case "struct":
				return {};
			case "query":
				return queryNew( "" );
			case "date":
			case "datetime":
			case "timestamp":
				return now();
			case "binary":
				return toBinary( toBase64( "x" ) );
			default:
				if ( left( t, 4 ) == "com." ) {
					try {
						return createObject( "component", arguments.typeName );
					} catch ( any cfcErr ) {
					}
				}
				if ( reFind( "^[a-z0-9_]+$", t ) ) {
					try {
						return entityNew( arguments.typeName );
					} catch ( any entErr ) {
					}
				}
				return "";
		}
	}

	private string function normalizeDirectoryPath( required string p ) {
		var s = replace( arguments.p, "\", "/", "all" );
		return reReplace( s, "/+$", "", "all" );
	}

	/**
	 * Resolve manifest path for the HTML runner: use the path as-is if it already exists on disk, otherwise expandPath (mapping-relative).
	 */
	public string function resolveManifestAbsolutePath( required string manifestInput ) {
		var p = trim( arguments.manifestInput );
		if ( !len( p ) ) {
			return "";
		}
		if ( fileExists( p ) ) {
			return p;
		}
		return expandPath( p );
	}

	/**
	 * Build “back to tests” and “re-run metadata smoke” URLs from the current request (HTML runner).
	 */
	public struct function buildSmokeRunnerSummaryFromRequest(
		required testbox.system.TestBox testbox,
		string metadataSmokeManifest = "",
		boolean metadataSmokeInvoke = false,
		string metadataSmokeComponent = "",
		string metadataSmokeDirectoryRootWeb = "",
		string metadataSmokeDirectoryPrefixForUrl = "",
		string metadataSmokeExcludeFileNames = "",
		string metadataSmokeExcludePathPrefixes = "",
		string metadataSmokeExcludeComponentIds = ""
	) {
		var qs = structKeyExists( cgi, "query_string" ) ? cgi.query_string : "";
		var stripQs = qs;
		stripQs = reReplace( stripQs, "&metadataSmoke(Invoke|Manifest|Format|Component|DirectoryRoot|DirectoryPrefix|ExcludeFileNames|ExcludePathPrefixes|ExcludeComponentIds)=[^&]*", "", "all" );
		stripQs = reReplace( stripQs, "&metadataSmoke=[^&]*", "", "all" );
		stripQs = reReplace( stripQs, "^metadataSmoke(Invoke|Manifest|Format|Component|DirectoryRoot|DirectoryPrefix|ExcludeFileNames|ExcludePathPrefixes|ExcludeComponentIds)=[^&]*&?", "", "all" );
		stripQs = reReplace( stripQs, "^metadataSmoke=[^&]*&?", "", "all" );
		stripQs = reReplace( stripQs, "^[&]+|[&]+$", "", "all" );
		var testsUrl = len( stripQs ) ? ( cgi.script_name & "?" & stripQs ) : cgi.script_name;

		var sep = find( "?", testsUrl ) ? "&" : "?";
		var smokeRunUrl = testsUrl & sep & "metadataSmoke=true";
		if ( len( trim( arguments.metadataSmokeManifest ) ) ) {
			smokeRunUrl &= "&metadataSmokeManifest=" & urlEncodedFormat( trim( arguments.metadataSmokeManifest ) );
		}
		if ( len( trim( arguments.metadataSmokeComponent ) ) ) {
			smokeRunUrl &= "&metadataSmokeComponent=" & urlEncodedFormat( trim( arguments.metadataSmokeComponent ) );
		}
		if ( len( trim( arguments.metadataSmokeDirectoryRootWeb ) ) && len( trim( arguments.metadataSmokeDirectoryPrefixForUrl ) ) ) {
			smokeRunUrl &= "&metadataSmokeDirectoryRoot=" & urlEncodedFormat( trim( arguments.metadataSmokeDirectoryRootWeb ) );
			smokeRunUrl &= "&metadataSmokeDirectoryPrefix=" & urlEncodedFormat( trim( arguments.metadataSmokeDirectoryPrefixForUrl ) );
			if ( len( trim( arguments.metadataSmokeExcludeFileNames ) ) ) {
				smokeRunUrl &= "&metadataSmokeExcludeFileNames=" & urlEncodedFormat( trim( arguments.metadataSmokeExcludeFileNames ) );
			}
			if ( len( trim( arguments.metadataSmokeExcludePathPrefixes ) ) ) {
				smokeRunUrl &= "&metadataSmokeExcludePathPrefixes=" & urlEncodedFormat( trim( arguments.metadataSmokeExcludePathPrefixes ) );
			}
			if ( len( trim( arguments.metadataSmokeExcludeComponentIds ) ) ) {
				smokeRunUrl &= "&metadataSmokeExcludeComponentIds=" & urlEncodedFormat( trim( arguments.metadataSmokeExcludeComponentIds ) );
			}
		}
		if ( arguments.metadataSmokeInvoke ) {
			smokeRunUrl &= "&metadataSmokeInvoke=true";
		}
		return {
			"testsUrl"    : testsUrl,
			"smokeRunUrl" : smokeRunUrl
		};
	}

	/**
	 * Compact HTML for the Simple reporter (same role as GapAnalysisService.renderRunnerEmbed).
	 */
	public any function renderRunnerEmbed( required testbox.system.TestBox testbox, boolean fullPage = false ) {
		var sum = buildSmokeRunnerSummaryFromRequest( arguments.testbox, "", false );
		return renderReport(
			testbox = arguments.testbox,
			smokeResult = {
				"success" : true, "errorMessage" : "", "componentCount" : 0, "discovered" : 0, "attempted" : 0, "skippedComponents" : []
			},
			runnerErrors = [],
			ran = false,
			manifestPath = "",
			invokeEnabled = false,
			metadataSmokeComponent = "",
			metadataSmokeDirectoryRootWeb = "",
			metadataSmokeDirectoryPrefixForUrl = "",
			metadataSmokeExcludeFileNamesForUrl = "",
			metadataSmokeExcludePathPrefixesForUrl = "",
			metadataSmokeExcludeComponentIdsForUrl = "",
			smokeEmbedCompact = true,
			fullPage = arguments.fullPage,
			justReturn = true
		);
	}

	/**
	 * Full-page HTML for metadata smoke (used by HTMLRunner.cfm).
	 */
	public any function renderReport(
		required testbox.system.TestBox testbox,
		required struct smokeResult,
		required array runnerErrors,
		boolean ran = false,
		string manifestPath = "",
		boolean invokeEnabled = false,
		string metadataSmokeComponent = "",
		string metadataSmokeDirectoryRootWeb = "",
		string metadataSmokeDirectoryPrefixForUrl = "",
		string metadataSmokeExcludeFileNamesForUrl = "",
		string metadataSmokeExcludePathPrefixesForUrl = "",
		string metadataSmokeExcludeComponentIdsForUrl = "",
		boolean smokeEmbedCompact = false,
		boolean fullPage = true,
		boolean justReturn = false
	) {
		var manifestForUrl = arguments.manifestPath;
		if ( find( "(", manifestForUrl ) && find( ")", manifestForUrl ) ) {
			manifestForUrl = "";
		}
		if ( len( trim( arguments.metadataSmokeComponent ) ) ) {
			manifestForUrl = "";
		}
		if ( len( trim( arguments.metadataSmokeDirectoryRootWeb ) ) && len( trim( arguments.metadataSmokeDirectoryPrefixForUrl ) ) ) {
			manifestForUrl = "";
		}
		var smokeRunnerSummary = buildSmokeRunnerSummaryFromRequest(
			testbox = arguments.testbox,
			metadataSmokeManifest = manifestForUrl,
			metadataSmokeInvoke = arguments.invokeEnabled,
			metadataSmokeComponent = arguments.metadataSmokeComponent,
			metadataSmokeDirectoryRootWeb = arguments.metadataSmokeDirectoryRootWeb,
			metadataSmokeDirectoryPrefixForUrl = arguments.metadataSmokeDirectoryPrefixForUrl,
			metadataSmokeExcludeFileNames = arguments.metadataSmokeExcludeFileNamesForUrl,
			metadataSmokeExcludePathPrefixes = arguments.metadataSmokeExcludePathPrefixesForUrl,
			metadataSmokeExcludeComponentIds = arguments.metadataSmokeExcludeComponentIdsForUrl
		);
		var rep = new testbox.system.reports.MetadataSmokeReporter();
		return rep.renderHtml(
			testbox = arguments.testbox,
			options = {
				"smokeResult"        : arguments.smokeResult,
				"runnerErrors"       : arguments.runnerErrors,
				"ran"                : arguments.ran,
				"manifestPath"       : arguments.manifestPath,
				"invokeEnabled"      : arguments.invokeEnabled,
				"smokeRunnerSummary" : smokeRunnerSummary,
				"smokeEmbedCompact"  : arguments.smokeEmbedCompact,
				"fullPage"           : arguments.fullPage
			},
			justReturn = arguments.justReturn
		);
	}

}
