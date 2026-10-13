/**
 * Fixture for the AgentReporter tests. It is intentionally NOT named *Test or *Spec so runners do not discover it.
 * It produces: 2 passes, 2 failures, 1 error, 1 skip, one of the failures nested.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Math", function(){
			it( "passes", function(){
				expect( 1 + 1 ).toBe( 2 );
			} );

			it( "fails with a message", function(){
				expect( 3 ).toBe( 4 );
			} );

			it( "errors", function(){
				throw( type = "Fixture.Boom", message = "kaboom" );
			} );

			xit( "is skipped", function(){
				expect( true ).toBeTrue();
			} );

			describe( "nested", function(){
				it( "passes too", function(){
					expect( true ).toBeTrue();
				} );

				it( "fails with a very long message", function(){
					fail( repeatString( "long message ", 100 ) );
				} );
			} );
		} );
	}

}
