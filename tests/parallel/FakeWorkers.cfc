/** Deterministic transport for framework contract tests; no application collaborators. */
component {

	function init( string failure = "" ){
		variables.failure = failure;
		this.started      = [];
		this.stopped      = [];
		this.finished     = false;
		return this;
	}

	function prepareRun( context ){
	}

	function isCancelled( context ){
		return variables.failure == "cancel" && this.started.len() > 0;
	}

	function startWorker( context ){
		if ( variables.failure == "startup" && context.workerId == 2 ) {
			throw( message = "Startup failed" );
		}
		this.started.append( context.workerId );
		return {
			"workerId" : context.workerId,
			"bundles"  : context.bundles,
			"polls"    : 0
		};
	}

	function pollWorker( worker ){
		worker.polls++;
		if ( worker.polls == 1 ) {
			return {
				"done"   : false,
				"events" : [
					{
						"type" : "specEnd",
						"data" : { "status" : "Passed", "name" : "spec" }
					}
				]
			};
		}
		var stats = [];
		for ( var bundle in worker.bundles ) {
			stats.append( { "path" : bundle } );
		}
		if ( variables.failure == "coverage" ) {
			stats = [];
		}
		return {
			"done"   : true,
			"events" : [],
			"result" : {
				"complete" : true,
				"seconds"  : 1,
				"report"   : {
					"totalPass"    : worker.bundles.len(),
					"totalFail"    : 0,
					"totalError"   : 0,
					"totalSkipped" : 0,
					"totalSpecs"   : worker.bundles.len(),
					"totalSuites"  : 1,
					"bundleStats"  : stats
				}
			}
		};
	}

	function stopWorker( worker ){
		this.stopped.append( worker.workerId );
		if ( variables.failure == "cleanup" ) {
			throw( message = "Cleanup failed" );
		}
	}

	function finishRun( context ){
		this.finished = true;
	}

}
