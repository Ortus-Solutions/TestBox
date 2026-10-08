/** Runner environment hooks must work in ordinary CFML web requests as well as BoxLang. */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe(
			title = "HTML runner environment settings",
			body  = function(){
				it( "runs normally when optional worker settings are empty", function(){
					var report = new tests.resources.runners.HTMLRunnerHarness().execute()
					expect( report.totalPass ).toBe( 2 )
					expect( report.totalFail ).toBe( 0 )
					expect( report.totalError ).toBe( 0 )
				} )
				it( "reads worker selection and writes lifecycle progress through the portable Env helper", function(){
					var prefix    = getTempDirectory() & "testbox-runner-" & createUUID()
					var selection = prefix & "-selection.json"
					var progress  = prefix & "-progress.jsonl"
					fileWrite( selection, serializeJSON( { "labels" : "selected" } ) )
					try {
						var report = new tests.resources.runners.HTMLRunnerHarness().execute( selection, progress )
						expect( report.totalPass ).toBe( 1 )
						expect( report.totalFail ).toBe( 0 )
						expect( report.totalError ).toBe( 0 )
						var events = fileRead( progress )
							.listToArray( chr( 10 ) )
							.map( function( line ){
								return deserializeJSON( line )
							} )
						expect(
							events
								.filter( function( event ){
									return event.type == "bundleReady"
								} )
								.len()
						).toBe( 1 )
						expect(
							events
								.filter( function( event ){
									return event.type == "specEnd" && event.data.status == "Passed"
								} )
								.len()
						).toBe( 1 )
					} finally {
						fileDelete( selection )
						if ( fileExists( progress ) ) {
							fileDelete( progress )
						}
					}
				} )
			},
			skip = server.keyExists( "boxlang" ) && server.boxlang.cliMode
		)
	}

}
