/** Reusable HTTP endpoint. TestBox owns discovery, selection, SSE and cancellation; providers own environments. */
component {

	function init(
		required any provider,
		string directory      = "tests.specs",
		string bundlesPattern = "*Spec*.bx|*Test*.bx|*Spec*.cfc|*Test*.cfc",
		numeric maxWorkers    = 32,
		struct durations      = {},
		string storageRoot    = "",
		boolean localOnly     = true
	){
		variables.provider       = arguments.provider;
		variables.directory      = arguments.directory;
		variables.bundlesPattern = arguments.bundlesPattern;
		variables.maxWorkers     = arguments.maxWorkers;
		variables.durations      = arguments.durations;
		variables.localOnly      = arguments.localOnly;
		variables.storageRoot    = len( arguments.storageRoot )
		 ? arguments.storageRoot
		 : getTempDirectory() & "testbox-parallel-" & hash( getBaseTemplatePath() );
		return this;
	}

	struct function capabilities(){
		return {
			"workers"      : true,
			"maxWorkers"   : variables.maxWorkers,
			"cancellation" : true
		};
	}

	/** Callers may narrow configured roots, but may not discover unrelated directories. */
	struct function selection( struct options = {} ){
		if ( len( options.shard ?: "" ) ) {
			throw(
				type    = "TestBox.Parallel.InvalidSelection",
				message = "Use the standard serial runner for independent CI shards."
			)
		}
		if ( options.coverageEnabled ?: false ) {
			throw(
				type    = "TestBox.Parallel.InvalidSelection",
				message = "Parallel coverage aggregation is not supported by this runner."
			);
		}
		var directory = len( trim( options.directory ?: "" ) ) ? trim( options.directory ) : variables.directory;
		for ( var requested in listToArray( directory ) ) {
			var allowed = false;
			for ( var configured in listToArray( variables.directory ) ) {
				if ( requested == configured || left( requested, len( configured ) + 1 ) == configured & "." ) {
					allowed = true;
				}
			}
			if (
				!allowed ||
				!reFind( "^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)*$", requested )
			) {
				throw(
					type    = "TestBox.Parallel.InvalidSelection",
					message = "Directory is outside this runner's configured test roots."
				);
			}
		}
		var testbox = new testbox.system.TestBox(
			labels         = options.labels ?: "",
			excludes       = options.excludes ?: "",
			bundlesPattern = len( options.bundlesPattern ?: "" )
			 ? options.bundlesPattern
			 : variables.bundlesPattern
		).addDirectories( directory, structKeyExists( options, "recurse" ) ? options.recurse : true );
		var allowedBundles = testbox.getBundles();
		var bundles        = len( options.bundles ?: "" ) ? listToArray( options.bundles ) : allowedBundles;
		var seen           = {};
		for ( var bundle in bundles ) {
			if ( seen.keyExists( bundle ) || !arrayFindNoCase( allowedBundles, bundle ) ) {
				throw(
					type    = "TestBox.Parallel.InvalidSelection",
					message = "Unknown or duplicate bundle: " & bundle
				);
			}
			seen[ bundle ] = true;
		}
		if ( !bundles.len() ) {
			throw( type = "TestBox.Parallel.InvalidSelection", message = "No bundles matched this selection." );
		}
		var workers = structKeyExists( options, "workers" ) ? options.workers : 1;
		if ( !isNumeric( workers ) || workers < 1 || workers != int( workers ) || workers > variables.maxWorkers ) {
			throw(
				type    = "TestBox.Parallel.InvalidSelection",
				message = "Workers must be an integer between 1 and " & variables.maxWorkers & "."
			);
		}
		// A single bundle/suite/spec needs one environment, regardless of the requested concurrency.
		return {
			"bundles" : bundles,
			"workers" : min( workers, bundles.len() ),
			"testbox" : testbox
		};
	}

	string function runDirectory( required string runId ){
		if ( !reFind( "^[a-f0-9]{32}$", arguments.runId ) ) {
			throw(
				type    = "TestBox.Parallel.InvalidSelection",
				message = "A 32-character lowercase hexadecimal run identity is required."
			);
		}
		return variables.storageRoot & "/" & arguments.runId;
	}

	/** Claim once before provisioning. Reconnecting EventSource clients cannot launch duplicate workers. */
	struct function claim( required string runId ){
		var directory = runDirectory( arguments.runId );
		if ( !directoryExists( variables.storageRoot ) ) {
			var root = createObject( "java", "java.io.File" ).init( variables.storageRoot )
			if ( !root.mkdirs() && !root.isDirectory() ) {
				throw(
					type    = "TestBox.Parallel.InvalidStorage",
					message = "Cannot create the parallel runner's storage directory."
				)
			}
		}
		lock name="testbox-parallel-#hash( directory )#" type="exclusive" timeout=10 {
			if ( directoryExists( directory ) || fileExists( directory ) ) {
				throw(
					type    = "TestBox.Parallel.DuplicateRun",
					message = "This run identity has already been used. Start a new run."
				);
			}
			directoryCreate( directory );
			var file = createObject( "java", "java.io.File" ).init( directory );
			file.setReadable( false, false );
			file.setReadable( true, true );
			file.setWritable( false, false );
			file.setWritable( true, true );
			file.setExecutable( false, false );
			file.setExecutable( true, true );
		}
		return {
			"runId"            : arguments.runId,
			"output"           : directory & "/environment",
			"cancellationFile" : directory & "/cancel"
		};
	}

	boolean function cancel( required string runId ){
		var directory = runDirectory( arguments.runId );
		if ( !directoryExists( directory ) || fileExists( directory & "/summary.json" ) ) {
			return false;
		}
		fileWrite( directory & "/cancel", "" );
		return true;
	}

	function serve(){
		setting requesttimeout="#999999#" showdebugoutput="#false#";
		if ( variables.localOnly && !listFind( "127.0.0.1,::1,0:0:0:0:0:0:0:1", cgi.remote_addr ) ) {
			cfheader( statusCode = 403 );
			return;
		}
		var action = url.action ?: "view";
		if ( action == "asset" ) {
			asset( url.asset ?: "" );
			return;
		}
		if ( action == "health" || action == "capabilities" ) {
			json( action == "health" ? { "ready" : true } : capabilities() );
			return;
		}
		try {
			if ( action == "cancel" ) {
				if ( cgi.request_method != "POST" ) {
					cfheader( statusCode = 405 );
					cfheader( name = "Allow", value = "POST" );
					return;
				}
				json( { "cancelling" : cancel( url.runId ?: "" ) } );
				return;
			}
			if ( url.dryRun ?: false ) {
				var selected = selection( url );
				selected.testbox.setBundles( selected.bundles );
				var discovery           = selected.testbox.dryRun();
				discovery[ "parallel" ] = capabilities();
				json( discovery );
				return;
			}
			if ( action == "view" && !( url.streaming ?: false ) ) {
				if ( !server.keyExists( "boxlang" ) ) {
					throw(
						type    = "TestBox.Parallel.BoxLangViewRequired",
						message = "The native RUN IDE view requires BoxLang. Use the coordinator or CLI protocol on CFML engines."
					)
				}
				url.runnerUrl            = cgi.script_name;
				url.directory            = url.directory ?: variables.directory;
				request.testboxAssetBase = cgi.script_name & "?action=asset&asset=";
				include "/testbox/bx/tests/index.bxm";
				return;
			}
			if ( action != "run" && !( url.streaming ?: false ) ) {
				throw( type = "TestBox.Parallel.InvalidSelection", message = "Unknown parallel runner action." );
			}
			var selected           = selection( url );
			var context            = claim( url.runId ?: "" );
			context[ "durations" ] = variables.durations;
			context[ "filters" ]   = {};
			for (
				var key in [
					"labels",
					"excludes",
					"testSuites",
					"testSpecs"
				]
			) {
				context.filters[ key ] = url[ key ] ?: "";
			}
		} catch ( any error ) {
			cfheader( statusCode = error.type == "TestBox.Parallel.DuplicateRun" ? 409 : 400 );
			json( { "message" : error.message } );
			return;
		}
		var stream = new testbox.system.util.StreamingService();
		stream.initializeStream();
		var coordinator = new testbox.system.parallel.Coordinator( variables.provider )
		var result      = coordinator.run(
			selected.bundles,
			selected.workers,
			context,
			function( type, data ){
				stream.streamEvent( type, data );
			}
		);
		fileWrite( runDirectory( context.runId ) & "/summary.json", serializeJSON( result ) );
	}

	private function json( required struct data ){
		cfcontent( type = "application/json; charset=utf-8", reset = true );
		writeOutput( serializeJSON( arguments.data ) );
	}

	private function asset( required string path ){
		var root = createObject( "java", "java.io.File" )
			.init( expandPath( "/testbox/bx/tests/assets" ) )
			.getCanonicalPath();
		var file  = createObject( "java", "java.io.File" ).init( root & "/" & arguments.path ).getCanonicalPath();
		var types = {
			"js"  : "application/javascript",
			"css" : "text/css",
			"svg" : "image/svg+xml"
		};
		var extension = listLast( arguments.path, "." );
		if (
			!createObject( "java", "java.io.File" )
				.init( file )
				.toPath()
				.startsWith( createObject( "java", "java.io.File" ).init( root ).toPath() ) ||
			!fileExists( file ) ||
			!types.keyExists( extension )
		) {
			cfheader( statusCode = 404 );
			return;
		}
		cfcontent(
			type  = types[ extension ],
			file  = file,
			reset = true
		);
	}

}
