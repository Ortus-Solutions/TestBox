/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * Tracks the bx-playwright managers that browser specs open during a TestBox run, so every browser closes
 * when the run ends, even when a bundle afterAll() threw or a spec aborted the request.
 *
 * TestBox.runRaw() calls startRun() before the bundles and endRun() in a finally block. startRun() also
 * closes the managers of earlier runs that can no longer be running: their thread is gone, or the same
 * thread now runs a new request (pooled web server threads), which happens when a run never reached its
 * finally block. Managers opened outside of a run are left to their owner and to bx-playwright, which closes
 * every open manager when the module unloads and when the JVM shuts down.
 *
 * The state lives in the server scope. It is only used on BoxLang, where browser specs run, but this
 * component compiles on every engine because TestBox calls it on every engine.
 */
component {

	variables.LOCK_NAME = "testbox-browser-registry"

	/**
	 * Start tracking a TestBox run on the current thread, after closing the managers of stale runs.
	 *
	 * @return The run id, to pass to endRun()
	 */
	string function startRun(){
		var runId= createUUID()
		var stack= getRunStack()
		lock name="#variables.LOCK_NAME#" type="exclusive" timeout="30" {
			var runs = getRuns()
			for ( var staleId in findStaleRuns( runs, stack ) ) {
				closeManagers( runs[ staleId ].managers )
				structDelete( runs, staleId )
			}
			runs[ runId ] = { "thread" : currentThread(), "managers" : {} }
		}
		pushRun( runId )
		return runId
	}

	/**
	 * Stop tracking a run and close every manager it opened. Safe to call more than once.
	 *
	 * @runId The id returned by startRun()
	 */
	function endRun( required string runId ){
		var managers= {}
		lock name   ="#variables.LOCK_NAME#" type="exclusive" timeout="30" {
			var runs = getRuns()
			if ( structKeyExists( runs, arguments.runId ) ) {
				managers = runs[ arguments.runId ].managers
				structDelete( runs, arguments.runId )
			}
		}
		popRun( arguments.runId )
		closeManagers( managers )
		return this
	}

	/**
	 * Track a manager opened by the current run. Managers opened outside of a run are not tracked.
	 *
	 * @manager The bx-playwright manager
	 *
	 * @return The registration key, to pass to release(), or an empty string when there is no current run
	 */
	string function register( required any manager ){
		var stack = getRunStack()
		if ( !arrayLen( stack ) ) {
			return ""
		}
		var runId= stack[ arrayLen( stack ) ]
		var key  = createUUID()
		lock name="#variables.LOCK_NAME#" type="exclusive" timeout="30" {
			var runs = getRuns()
			if ( structKeyExists( runs, runId ) ) {
				runs[ runId ].managers[ key ] = arguments.manager
			}
		}
		return key
	}

	/**
	 * Stop tracking a manager its owner closes.
	 *
	 * @key The key returned by register()
	 */
	function release( required string key ){
		if ( !len( arguments.key ) ) {
			return this
		}
		lock name="#variables.LOCK_NAME#" type="exclusive" timeout="30" {
			for ( var runId in getRuns() ) {
				structDelete( getRuns()[ runId ].managers, arguments.key )
			}
		}
		return this
	}

	/**
	 * How many managers are tracked, for all runs.
	 *
	 * @return The number of tracked managers
	 */
	numeric function managerCount(){
		var count= 0
		lock name="#variables.LOCK_NAME#" type="readonly" timeout="30" {
			for ( var runId in getRuns() ) {
				count += structCount( getRuns()[ runId ].managers )
			}
		}
		return count
	}

	/**
	 * The runs that can no longer be running: their thread died, or it is the current thread and the run
	 * is not one of the runs of the current request (a nested TestBox run keeps its outer run).
	 *
	 * @runs  The tracked runs
	 * @stack The run ids of the current request
	 *
	 * @return The stale run ids
	 */
	private array function findStaleRuns( required struct runs, required array stack ){
		var thread = currentThread()
		var stale  = []
		for ( var runId in arguments.runs ) {
			var runThread = arguments.runs[ runId ].thread
			if (
				!runThread.isAlive() ||
				( runThread.equals( thread ) && !arrayFind( arguments.stack, runId ) )
			) {
				stale.append( runId )
			}
		}
		return stale
	}

	/**
	 * Close managers, ignoring the ones that fail to close.
	 *
	 * @managers The managers, by registration key
	 */
	private function closeManagers( required struct managers ){
		for ( var key in arguments.managers ) {
			try {
				arguments.managers[ key ].close()
			} catch ( any e ) {
				// Already closed or its driver is gone: keep closing the rest
			}
		}
	}

	/**
	 * The tracked runs, by run id, shared by every request of the server.
	 */
	private struct function getRuns(){
		if ( !structKeyExists( server, "testboxBrowserRuns" ) ) {
			lock name="#variables.LOCK_NAME#-init" type="exclusive" timeout="30" {
				if ( !structKeyExists( server, "testboxBrowserRuns" ) ) {
					server.testboxBrowserRuns = {}
				}
			}
		}
		return server.testboxBrowserRuns
	}

	/**
	 * The run ids of the current request, innermost last. A copy on engines that pass arrays by value:
	 * change it with pushRun() and popRun().
	 */
	private array function getRunStack(){
		return request.testboxBrowserRunStack ?: []
	}

	/**
	 * Add a run to the runs of the current request.
	 *
	 * @runId The run id
	 */
	private function pushRun( required string runId ){
		var stack = getRunStack()
		arrayAppend( stack, arguments.runId )
		request.testboxBrowserRunStack = stack
	}

	/**
	 * Remove a run from the runs of the current request.
	 *
	 * @runId The run id
	 */
	private function popRun( required string runId ){
		var stack    = getRunStack()
		var position = arrayFind( stack, arguments.runId )
		if ( position ) {
			arrayDeleteAt( stack, position )
		}
		request.testboxBrowserRunStack = stack
	}

	/**
	 * The current Java thread.
	 */
	private function currentThread(){
		return createObject( "java", "java.lang.Thread" ).currentThread()
	}

}
