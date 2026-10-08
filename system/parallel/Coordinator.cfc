/** Portable TestBox worker coordination; providers own environments and transport. */
component {

	function init( required any provider ){
		variables.provider = arguments.provider;
		return this;
	}

	struct function run(
		required array bundles,
		numeric workers = 1,
		struct context  = {},
		any emit        = function( type, data ){
		}
	){
		if ( workers < 1 || workers != int( workers ) || !bundles.len() || workers > bundles.len() ) {
			throw(
				type    = "TestBox.Parallel.InvalidSelection",
				message = "Select at least one bundle and between one and the selected bundle count workers."
			);
		}
		var seen = {};
		for ( var bundle in bundles ) {
			if ( seen.keyExists( bundle ) ) {
				throw( type = "TestBox.Parallel.DuplicateBundle", message = "Duplicate bundle: " & bundle );
			}
			seen[ bundle ] = true;
		}
		variables.emit                    = arguments.emit;
		variables.sequence                = 0;
		variables.started                 = getTickCount();
		variables.context                 = context;
		variables.context[ "runId" ]      = context.runId ?: lCase( replace( createUUID(), "-", "", "all" ) );
		variables.context[ "workers" ]    = workers;
		variables.context[ "bundles" ]    = bundles;
		variables.handles                 = [];
		variables.results                 = [];
		variables.errors                  = [];
		variables.cancelled               = false;
		variables.transportLost           = false;
		variables.preparationMilliseconds = 0;
		variables.cleanupMilliseconds     = 0;
		var groups                        = partition( bundles, workers, context.durations ?: {} );
		publish(
			"testRunStart",
			{
				"totalBundles"       : bundles.len(),
				"workers"            : workers,
				"workerBundleCounts" : groups.map( function( group ){
					return group.len();
				} )
			}
		);
		try {
			var preparationStarted            = getTickCount();
			variables.context[ "onProgress" ] = function( message ){
				publish( "runPhase", { "phase" : "prepare", "message" : message } );
			};
			publish(
				"runPhase",
				{
					"phase"   : "prepare",
					"message" : "Preparing shared environment"
				}
			);
			try {
				if ( variables.transportLost || variables.provider.isCancelled( variables.context ) ) {
					throw( type = "TestBox.Parallel.Cancelled", message = "Cancelled before preparation" );
				}
				variables.provider.prepareRun( variables.context );
			} finally {
				variables.preparationMilliseconds = getTickCount() - preparationStarted;
			}
			publish( "runPhase", { "phase" : "ready", "message" : "Shared setup ready" } );
			for ( var i = 1; i <= workers; i++ ) {
				if ( variables.transportLost || variables.provider.isCancelled( variables.context ) ) {
					variables.cancelled = true;
					break;
				}
				var descriptor = {
					"workerId" : i,
					"bundles"  : groups[ i ],
					"run"      : variables.context
				};
				var workerStarted = getTickCount();
				var handle        = variables.provider.startWorker( descriptor );
				variables.handles.append( {
					"workerId" : i,
					"handle"   : handle,
					"bundles"  : groups[ i ],
					"started"  : workerStarted,
					"done"     : false
				} );
				publish( "workerStart", { "workerId" : i, "totalBundles" : groups[ i ].len() } );
			}
			observe();
		} catch ( any error ) {
			if ( variables.transportLost || variables.provider.isCancelled( variables.context ) ) {
				variables.cancelled = true;
				publish( "runCancelling", {} );
			} else {
				recordError( 0, error.message );
			}
		} finally {
			cleanup();
		}
		var result = aggregate( bundles );
		publish(
			"testRunEnd",
			{
				"results"      : result,
				"totalPass"    : result.totalPass,
				"totalFail"    : result.totalFail,
				"totalError"   : result.totalError,
				"totalSkipped" : result.totalSkipped,
				"cancelled"    : variables.cancelled
			}
		);
		if ( variables.transportLost ) {
			result.passed                 = false;
			result.parallel.cancelled     = true;
			result.parallel.transportLost = true;
		}
		return result;
	}

	array function partition(
		required array bundles,
		required numeric workers,
		struct durations = {}
	){
		return new testbox.system.parallel.ShardPlan().partition( bundles, workers, durations )
	}

	private function observe(){
		var pending = variables.handles.len();
		while ( pending ) {
			if ( variables.transportLost || variables.provider.isCancelled( variables.context ) ) {
				variables.cancelled = true;
				publish( "runCancelling", {} );
				return;
			}
			for ( var worker in variables.handles ) {
				if ( worker.done ) {
					continue;
				}
				var observation = variables.provider.pollWorker( worker.handle );
				for ( var event in observation.events ) {
					var data           = event.data;
					data[ "workerId" ] = worker.workerId;
					// Worker-local run events cannot reset or terminate the parent run.
					if ( !listFind( "testRunStart,testRunEnd", event.type ) ) {
						publish( event.type, data );
					}
				}
				if ( observation.done ) {
					worker.done = true;
					pending--;
					var result                   = observation.result;
					result[ "workerId" ]         = worker.workerId;
					result[ "wallMilliseconds" ] = getTickCount() - worker.started;
					result[ "assignedBundles" ]  = worker.bundles.len();
					variables.results.append( result );
					if ( !result.complete ) {
						recordError( worker.workerId, result.error ?: "Worker did not complete its selection." );
					}
					publish(
						"workerEnd",
						{
							"workerId"     : worker.workerId,
							"complete"     : result.complete,
							"totalPass"    : result.report.totalPass ?: 0,
							"totalFail"    : result.report.totalFail ?: 0,
							"totalError"   : result.report.totalError ?: 0,
							"totalBundles" : arrayLen( result.report.bundleStats ?: [] ),
							"totalSkipped" : result.report.totalSkipped ?: 0,
							"hasReport"    : result.report.keyExists( "bundleStats" ),
							"seconds"      : result.seconds ?: 0
						}
					);
				}
			}
			if ( pending ) {
				sleep( 100 );
			}
		}
	}

	private function cleanup(){
		var cleanupStarted                        = getTickCount();
		variables.context[ "onShutdownProgress" ] = function( message ){
			publish( "runPhase", { "phase" : "cancelling", "message" : message } );
		};
		publish(
			"runPhase",
			{
				"phase"   : "cleanup",
				"message" : "Finalizing owned environment cleanup"
			}
		);
		for ( var worker in variables.handles ) {
			if ( structKeyExists( variables.provider, "stopWorkers" ) ) {
				break;
			}
			try {
				variables.provider.stopWorker( worker.handle );
			} catch ( any error ) {
				recordError( worker.workerId, error.message );
			}
		}
		if ( structKeyExists( variables.provider, "stopWorkers" ) ) {
			try {
				variables.provider.stopWorkers(
					variables.handles.map( function( worker ){
						return worker.handle;
					} ),
					variables.context
				);
			} catch ( any error ) {
				recordError( 0, error.message );
			}
		}
		try {
			variables.provider.finishRun( variables.context );
		} catch ( any error ) {
			recordError( 0, error.message );
		}
		variables.cleanupMilliseconds = getTickCount() - cleanupStarted;
	}

	private struct function aggregate( required array expected ){
		var result = {
			"totalBundles" : 0,
			"totalSuites"  : 0,
			"totalSpecs"   : 0,
			"totalPass"    : 0,
			"totalFail"    : 0,
			"totalError"   : 0,
			"totalSkipped" : 0,
			"bundleStats"  : [],
			"version"      : "",
			"coverage"     : {},
			"labels"       : [],
			"excludes"     : []
		};
		var actual = [];
		for ( var worker in variables.results ) {
			for ( var metadata in [ "version", "CFMLEngine", "CFMLEngineVersion" ] ) {
				if ( !len( result[ metadata ] ?: "" ) && worker.report.keyExists( metadata ) ) {
					result[ metadata ] = worker.report[ metadata ];
				}
			}
			for ( var field in [ "labels", "excludes" ] ) {
				for ( var label in ( worker.report[ field ] ?: [] ) ) {
					if ( !arrayFindNoCase( result[ field ], label ) ) {
						result[ field ].append( label );
					}
				}
			}
			for (
				var key in [
					"totalSuites",
					"totalSpecs",
					"totalPass",
					"totalFail",
					"totalError",
					"totalSkipped"
				]
			) {
				result[ key ] += worker.report[ key ] ?: 0;
			}
			for ( var bundle in ( worker.report.bundleStats ?: [] ) ) {
				result.bundleStats.append( bundle );
				actual.append( bundle.path );
			}
		}
		var sortedExpected = duplicate( expected );
		sortedExpected.sort( "text" );
		actual.sort( "text" );
		var coverageMatched = actual.toList() == sortedExpected.toList();
		if ( !coverageMatched && !variables.cancelled ) {
			recordError( 0, "Returned bundle coverage differs from the selected bundle set." );
		}
		result[ "totalBundles" ]  = actual.len();
		result[ "totalDuration" ] = getTickCount() - variables.started;
		var timing                = {
			"preparationMilliseconds" : variables.preparationMilliseconds,
			"cleanupMilliseconds"     : variables.cleanupMilliseconds,
			"reportedWorkers"         : variables.results.len(),
			"specsPerSecond"          : result.totalDuration > 0 ? result.totalSpecs * 1000 / result.totalDuration : 0
		};
		if ( variables.results.len() ) {
			var durations = variables.results.map( function( worker ){
				return worker.wallMilliseconds;
			} );
			timing[ "fastestWorkerMilliseconds" ] = arrayMin( durations );
			timing[ "slowestWorkerMilliseconds" ] = arrayMax( durations );
			timing[ "workerSpreadMilliseconds" ]  = timing.slowestWorkerMilliseconds -
			timing.fastestWorkerMilliseconds;
		}
		result.totalError += variables.errors.len();
		result[ "parallel" ] = {
			"runId"            : variables.context.runId,
			"workers"          : variables.context.workers,
			"coverageMatched"  : coverageMatched,
			"cancelled"        : variables.cancelled,
			"transportLost"    : variables.transportLost,
			"errors"           : variables.errors,
			"workerStats"      : variables.results,
			"timing"           : timing,
			"wallMilliseconds" : result.totalDuration
		};
		result[ "passed" ] = coverageMatched && !variables.cancelled && result.totalFail == 0 &&
		result.totalError == 0;
		return result;
	}

	private function recordError( required numeric workerId, required string message ){
		variables.errors.append( { "workerId" : workerId, "message" : message } );
		publish( "workerError", { "workerId" : workerId, "message" : message } );
	}

	private function publish( required string type, required struct data ){
		variables.sequence++;
		data[ "runId" ]    = variables.context.runId;
		data[ "sequence" ] = variables.sequence;
		// Observer failures must never prevent provider cleanup.
		if ( !variables.transportLost ) {
			try {
				variables.emit( type, data );
			} catch ( any disconnected ) {
				variables.transportLost = true;
				variables.cancelled     = true;
			}
		}
	}

}
