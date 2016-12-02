/**
* My BDD Test
*/
component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	}

/*********************************** BDD SUITES ***********************************/

	function run(){
		// all your suites go here.
		describe( title="Debug", body=function(){

			it( "can have custom labels", function(){
				debug( var=[1,2,3,4], label="My Custom Label" );
				var buffer = getDebugBuffer();
				expect( buffer[ 1 ].label ).toBe( "My Custom Label" );
			});

			it( "can have generic labels", function(){
				debug( var=[1,2,3,4] );
				var buffer = getDebugBuffer();
				expect( buffer[ 2 ].label ).toBe( "/Debug/can have generic labels" );
			});
			

			it( "can do top functionality", function(){
				var nested = [
					1, 2, 3, 4,
					[ 1, 2, 3, 4, [ 1, 2, 3, 4 ] ]
				];
				debug( var=nested, top=1 );
			});

			it( "passes through a format option, defaulting to html", function() {
				var values = [ 1, 2, 3, 4 ];
				debug( var = values );
				debug( var = values, format = "text" );
				var buffer = getDebugBuffer();
				expect( buffer ).toBeArray();
				expect( buffer ).toHaveLength( 5 );
				expect( buffer[ 4 ] ).toHaveKey( "format" );
				expect( buffer[ 4 ].format ).toBe( "html" );
				expect( buffer[ 5 ] ).toHaveKey( "format" );
				expect( buffer[ 5 ].format ).toBe( "text" );
			} );

			describe( "another Suite", function(){
				it( "can have generic labels too", function(){
					debug( var=[1,2,3,4] );
					var buffer = getDebugBuffer();
					expect( buffer[ 6 ].label ).toBe( "/Debug/another Suite/can have generic labels too" );
				});
			});

		});
	}

}