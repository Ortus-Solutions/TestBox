/**
 * Fixture for AttachmentsTest: a xUnit test that attaches a file.
 */
component extends="testbox.system.BaseSpec" {

	function testAttaches(){
		attach( "/tmp/testbox/xunit.png", "screenshot" )
	}

}
