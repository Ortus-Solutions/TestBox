/** Worker event transport using existing TestBox callbacks, without an HTTP stream. */
component extends="testbox.system.util.StreamingService" {

	function init( required string path ){
		super.init();
		variables.path = arguments.path;
		return this;
	}

	function streamEvent( required string eventType, required any data ){
		var payload = {};
		// Never serialize raw exceptions, debug buffers or application objects.
		for ( var key in data ) {
			if ( isSimpleValue( data[ key ] ) && !listFindNoCase( "debugBuffer,failStacktrace", key ) ) {
				payload[ key ] = isNumeric( data[ key ] ) || isBoolean( data[ key ] )
				 ? data[ key ]
				 : left( data[ key ], 8192 );
			}
		}
		if ( data.keyExists( "error" ) && isStruct( data.error ) ) {
			payload.errorMessage = left( data.error.message ?: "", 8192 );
		}
		if ( payload.keyExists( "failMessage" ) ) {
			payload.failMessage = left( payload.failMessage, 8192 );
		}
		// Concurrent asyncAll callbacks use the same event file safely.
		lock name="testbox-progress-#hash( variables.path )#" type="exclusive" timeout=10 {
			fileAppend(
				variables.path,
				serializeJSON( { "type" : eventType, "data" : payload } ) & chr( 10 ),
				"UTF-8"
			);
		}
	}

	struct function createStreamingCallbacks(){
		var callbacks           = super.createStreamingCallbacks();
		var service             = this;
		callbacks.onBundleReady = function( target, testResults, suites ){
			service.streamEvent(
				"bundleReady",
				{
					"path"       : getMetadata( target ).name,
					"totalSpecs" : service.countSpecs( suites ),
					"timestamp"  : getTickCount()
				}
			);
		};
		// BDD descriptors exist only after bundleStart, once run() has declared suites.
		callbacks.onSuiteStart = function( target, testResults, suite ){
			var suites = structKeyExists( target, "$suites" ) ? target.$suites : [ suite ];
			service.streamEvent(
				"suiteStart",
				{
					"id"               : suite.id,
					"bundlePath"       : getMetadata( target ).name,
					"name"             : suite.name,
					"bundleTotalSpecs" : service.countSpecs( suites ),
					"timestamp"        : getTickCount()
				}
			);
		};
		return callbacks;
	}

	numeric function countSpecs( required array suites ){
		var total = 0;
		for ( var suite in arguments.suites ) {
			total += ( suite.specs ?: [] ).len() + countSpecs( suite.suites ?: [] );
		}
		return total;
	}

}
