/**
* This tests the BDD functionality in TestBox.
*/
component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		application.coldbox = 0;
	}

	function afterAll(){

	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "A suite", function(){

			// before each spec in THIS suite group
			beforeEach(function( currentSpec ){
				application.coldbox++;
				debug( "beforeEach #arguments.currentSpec#: application.coldbox = #application.coldbox#" );
			});

			// after each spec in THIS suite group
			afterEach(function( currentSpec ){
				debug( "afterEach #arguments.currentSpec#: application.coldbox = #application.coldbox#" );
			});

			// around each spec in THIS suite group
			aroundEach(function( spec ){
				// execute the spec manually now, we can decorate things here too.
				spec.body();
			});

			it("before should be 1", function(){
				expect( application.coldbox ).toBe( 1 );
			});

			describe( "A nested suite", function(){

				// before each spec in THIS suite group
				beforeEach(function( currentSpec ){
					application.coldbox *= 2;
					debug( "beforeEach #arguments.currentSpec#: application.coldbox = #application.coldbox#" );
				});

				// around each spec in THIS suite group
				aroundEach(function( spec ){
					// execute the spec manually now, we can decorate things here too.
					spec.body();
				});

				it( "before should be 4", function(){
					expect(	application.coldbox ).toBe( 4 );
				});

				describe( "Another nested suite", function(){
					// before each spec in THIS suite group
					beforeEach(function( currentSpec ){
						application.coldbox++;
						debug( "beforeEach #arguments.currentSpec#: application.coldbox = #application.coldbox#" );
					});

					it( "before should be 11", function(){
						expect(	application.coldbox ).toBe( 11 );
					});
				});

			});


		});



	}

}