/** Exercise the included web runner without replacing its execution path. */
component {

	function execute( string selection = "", string progress = "" ){
		var originalURL      = duplicate( url )
		var originalSettings = configureSettings( selection, progress )
		structClear( url )
		url.bundles  = "tests.resources.runners.HTMLRunnerBundle"
		url.reporter = "json"
		try {
			savecontent variable="local.output" {
				include "/testbox/system/runners/HTMLRunner.cfm"
			}
			return deserializeJSON( local.output )
		} finally {
			restoreSettings( originalSettings )
			structClear( url )
			structAppend( url, originalURL )
		}
	}
	private struct function configureSettings( required string selection, required string progress ){
		var javaSystem = new testbox.system.util.Env().getJavaSystem()
		var original   = {}
		var settings   = {
			"TESTBOX_PARALLEL_SELECTION" : selection,
			"TESTBOX_PARALLEL_PROGRESS"  : progress
		}
		for ( var key in settings ) {
			if ( javaSystem.getProperties().containsKey( key ) ) {
				original[ key ] = javaSystem.getProperty( key )
			}
			javaSystem.setProperty( key, settings[ key ] )
		}
		return original
	}
	private function restoreSettings( required struct original ){
		var javaSystem = new testbox.system.util.Env().getJavaSystem()
		for (
			var key in [
				"TESTBOX_PARALLEL_SELECTION",
				"TESTBOX_PARALLEL_PROGRESS"
			]
		) {
			if ( original.keyExists( key ) ) {
				javaSystem.setProperty( key, original[ key ] )
			} else {
				javaSystem.clearProperty( key )
			}
		}
	}

}
