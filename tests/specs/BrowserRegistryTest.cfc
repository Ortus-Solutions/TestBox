/**
 * testbox.system.browser.BrowserRegistry with fake managers: no browser needed, every engine.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "BrowserRegistry", () => {
			beforeEach( () => {
				variables.registry = new testbox.system.browser.BrowserRegistry();
				variables.closed   = { count : 0 };
			} );

			it( "closes the managers of a run when the run ends", () => {
				var before = registry.managerCount();
				var runId  = registry.startRun();
				registry.register( fakeManager() );
				registry.register( fakeManager() );
				expect( registry.managerCount() ).toBe( before + 2 );

				registry.endRun( runId );
				expect( closed.count ).toBe( 2 );
				expect( registry.managerCount() ).toBe( before );
				// Safe to call twice
				registry.endRun( runId );
				expect( closed.count ).toBe( 2 );
			} );

			it( "does not close a manager its owner released", () => {
				var runId = registry.startRun();
				var key   = registry.register( fakeManager() );
				registry.release( key );
				registry.endRun( runId );
				expect( closed.count ).toBe( 0 );
			} );

			it( "keeps the managers of the outer run during a nested run", () => {
				var outerId = registry.startRun();
				registry.register( fakeManager() );
				var innerId = registry.startRun();
				registry.register( fakeManager() );

				registry.endRun( innerId );
				expect( closed.count ).toBe( 1 );
				registry.endRun( outerId );
				expect( closed.count ).toBe( 2 );
			} );

			it( "closes the managers of a run whose thread is gone when a run starts", () => {
				var staleId                          = "stale-" & createUUID();
				server.testboxBrowserRuns[ staleId ] = {
					"thread"   : createObject( "java", "java.lang.Thread" ).init(),
					"managers" : { "a" : fakeManager() }
				};
				var runId = registry.startRun();
				registry.endRun( runId );
				expect( closed.count ).toBe( 1 );
				expect( server.testboxBrowserRuns ).notToHaveKey( staleId );
			} );

			it( "closes the managers of an earlier request on the same thread when a run starts", () => {
				var staleId                          = "stale-" & createUUID();
				server.testboxBrowserRuns[ staleId ] = {
					"thread"   : createObject( "java", "java.lang.Thread" ).currentThread(),
					"managers" : { "a" : fakeManager() }
				};
				var runId = registry.startRun();
				registry.endRun( runId );
				expect( closed.count ).toBe( 1 );
				expect( server.testboxBrowserRuns ).notToHaveKey( staleId );
			} );

			it( "closes the other managers when one fails to close", () => {
				var runId = registry.startRun();
				registry.register( {
					close : () => {
						throw( type = "FakeManager.Broken", message = "driver gone" );
					}
				} );
				registry.register( fakeManager() );
				registry.endRun( runId );
				expect( closed.count ).toBe( 1 );
			} );
		} );
	}

	/**
	 * A fake manager that counts its close() calls in variables.closed.
	 */
	private struct function fakeManager(){
		var counter = variables.closed;
		return {
			close : () => {
				counter.count++;
			}
		};
	}

}
