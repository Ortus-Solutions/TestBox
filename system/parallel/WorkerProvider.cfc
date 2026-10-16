/**
 * Optional starting point for providers. Override startWorker, pollWorker and stopWorker.
 * Override prepareRun/finishRun for shared immutable resources and stopWorkers for
 * concurrent shutdown with a single grace deadline. Never stop resources you do not own.
 */
component implements="testbox.system.parallel.IWorkerProvider" {

	/** Adapt existing environment helpers without writing another provider class. */
	function init( any start, any poll, any stop ){
		variables.adapters = {}
		for ( var name in [ "start", "poll", "stop" ] ) {
			if ( structKeyExists( arguments, name ) ) {
				if ( !isCustomFunction( arguments[ name ] ) ) {
					throw(
						type    = "TestBox.Parallel.InvalidProvider",
						message = "Worker adapters must be functions."
					)
				}
				variables.adapters[ name ] = arguments[ name ]
			}
		}
		return this
	}


	function prepareRun( required struct context ){
	}

	boolean function isCancelled( required struct context ){
		return len( context.cancellationFile ?: "" ) && fileExists( context.cancellationFile );
	}

	struct function startWorker( required struct context ){
		if ( structKeyExists( variables.adapters ?: {}, "start" ) ) {
			return variables.adapters.start( context )
		}
		throw(
			type    = "TestBox.Parallel.ProviderRequired",
			message = "Implement startWorker() in your environment provider before running parallel tests."
		);
	}

	struct function pollWorker( required struct worker ){
		if ( structKeyExists( variables.adapters ?: {}, "poll" ) ) {
			return variables.adapters.poll( worker )
		}
		throw(
			type    = "TestBox.Parallel.ProviderRequired",
			message = "Implement pollWorker() in your environment provider."
		);
	}

	function stopWorker( required struct worker ){
		if ( structKeyExists( variables.adapters ?: {}, "stop" ) ) {
			return variables.adapters.stop( worker )
		}
		throw(
			type    = "TestBox.Parallel.ProviderRequired",
			message = "Implement stopWorker() in your environment provider."
		);
	}

	function finishRun( required struct context ){
	}

}
