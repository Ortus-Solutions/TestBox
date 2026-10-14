/**
 * bindSpecStats() / restoreSpecStats(): must work when the thread local is empty, including Adobe 2023 without null support.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Spec stats binding", function(){
			it( "returns an empty string when nothing was bound", function(){
				var spec     = new testbox.system.BaseSpec()
				var previous = spec.bindSpecStats( { attachments : [] } )
				expect( previous ).toBeString()
				expect( previous ).toBe( "" )
				spec.restoreSpecStats( previous )
			} )

			it( "restores the outer stats for nested binds", function(){
				var spec  = new testbox.system.BaseSpec()
				var outer = { name : "outer" }
				var inner = { name : "inner" }
				var none  = spec.bindSpecStats( outer )
				var prev  = spec.bindSpecStats( inner )
				expect( prev ).toBe( outer )
				spec.restoreSpecStats( prev )
				expect( spec.bindSpecStats( outer ) ).toBe( outer )
				spec.restoreSpecStats( none )
			} )

			it( "clears the binding when restoring an empty previous value", function(){
				var spec = new testbox.system.BaseSpec()
				spec.restoreSpecStats( spec.bindSpecStats( { name : "x" } ) )
				expect( function(){
					spec.attach( "/tmp/x.png" )
				} ).toThrow( "TestBox.InvalidContext" )
			} )
		} )
	}

}
