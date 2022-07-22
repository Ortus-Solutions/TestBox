/**
 * My BDD Test
 */
component extends="testbox.system.BaseSpec" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		// The following should NOT fail
		describe(
			"Thread Scope Corruption",
			function(){
				it( "check for thread scope corruption", function(){
					thread name="testThread" {
						thread.result = "I Exist";
						sleep( 10 );
					}
					thread action="join" name=testThread;

					systemOutput( cfthread );
					expect( cfthread.testThread ).toHaveKey( "result" );
					expect( cfthread.result ).toBe( "I Exist" );
					// normal keys in the thread scope
					loop list="ELAPSEDTIME,NAME,OUTPUT,PRIORITY,STARTTIME,STATUS,STACKTRACE" index="local.key" {
						expect( cfthread.testThread ).toHaveKey( key );
					}
				} );
			},
			"async",
			true
		);
	}

}
