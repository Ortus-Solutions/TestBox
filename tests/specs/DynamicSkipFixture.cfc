/**
 * Lightweight fixture used to verify that a string `skip` annotation is
 * resolved as a function-name reference on the target. The `alwaysSkip`
 * method always returns true so the bundle is treated as skipped regardless
 * of the runtime.
 */
component extends="testbox.system.BaseSpec" skip="alwaysSkip" {

	function alwaysSkip(){
		return true
	}

	function run(){
		describe( title = "Skipped via function reference", body = function(){
			it( title = "never runs", body = function(){
				fail( "this should never execute" )
			} )
		} )
	}

}
