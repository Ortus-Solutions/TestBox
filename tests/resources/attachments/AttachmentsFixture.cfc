/**
 * Fixture for AttachmentsTest: specs that attach files and pass or fail.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Attachments Fixture", function(){
			it( "passes with an attachment", function(){
				attach( "/tmp/testbox/passed.png", "screenshot" )
			} )

			it( "fails with attachments", function(){
				attach( path = "/tmp/testbox/trace & more.zip", type = "trace", name = "The <trace>" )
				attach( "/tmp/testbox/notes.txt" )
				fail( "expected failure" )
			} )

			it( "errors with an attachment", function(){
				attach( "/tmp/testbox/error.log", "log" )
				throw( type = "Fixture.Boom", message = "expected error" )
			} )
		} )
	}

}
