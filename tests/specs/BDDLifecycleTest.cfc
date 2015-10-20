/**
* This tests the BDD functionality in TestBox.
*/
component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		coldbox = 0;
	}

	function afterAll(){

	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "A suite", function(){

			// before each spec in THIS suite group
			beforeEach(function( currentSpec ){
				coldbox++;
				debug( "beforeEach #arguments.currentSpec#: coldbox = #coldbox#" );
			});

			// after each spec in THIS suite group
			afterEach(function( currentSpec ){
				debug( "afterEach #arguments.currentSpec#: coldbox = #coldbox#" );
			});

			// around each spec in THIS suite group
			aroundEach(function( spec ){
				// execute the spec manually now, we can decorate things here too.
				spec.body();
			});

			it("before should be 1", function(){
				expect( coldbox ).toBe( 1 );
			});

			describe( "A nested suite", function(){

				// before each spec in THIS suite group
				beforeEach(function( currentSpec ){
					coldbox = coldbox * 2;
					debug( "beforeEach #arguments.currentSpec#: coldbox = #coldbox#" );
				});

				// around each spec in THIS suite group
				aroundEach(function( spec ){
					// execute the spec manually now, we can decorate things here too.
					spec.body();
				});

				it( "before should be 4", function(){
					expect(	coldbox ).toBe( 4 );
				});

				describe( "Another nested suite", function(){
					// before each spec in THIS suite group
					beforeEach(function( currentSpec ){
						coldbox++;
						debug( "beforeEach #arguments.currentSpec#: coldbox = #coldbox#" );
					});

					it( "before should be 11", function(){
						expect(	coldbox ).toBe( 11 );
					});
				});

			});


		});



	}

}