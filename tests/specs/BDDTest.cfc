/**
* This tests the BDD functionality in TestBox.
*/
component extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		print( "<h1>BDD Testing is Awesome!</h1>" );
		console( "Executed beforeAll() at #now()# " );
		application.coldbox = 0;
	}

	function afterAll(){
		console( "Executed afterAll() at #now()#" );
		structClear( application );
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		/**
		* describe() starts a suite group of spec tests.
		* Arguments:
		* @title The title of the suite, Usually how you want to name the desired behavior
		* @body A closure that will resemble the tests to execute.
		* @labels The list or array of labels this suite group belongs to
		* @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
		* @skip A flag that tells TestBox to skip this suite group from testing if true
		*/
		describe( title="A spec", labels="luis", body=function(){

			// before each spec in THIS suite group
			beforeEach(function(){
				application.coldbox = 0;
				application.coldbox++;
				debug( "beforeEach suite: coldbox = #application.coldbox#" );
			});

			// after each spec in THIS suite group
			afterEach(function(){
				foo = 0;
			});

			/**
			* it() describes a spec to test. Usually the title is prefixed with the suite name to create an expression.
			* Arguments:
			* @title The title of the spec
			* @spec A closure that represents the test to execute
			* @labels The list or array of labels this spec belongs to
			* @skip A flag that tells TestBox to skip this spec from testing if true
			*/
			it(title="is just a closure so it can contain code", body=function(){
				expect( application.coldbox ).toBe( 1 );
			},labels="luis");

			// more than 1 expectation
			it("can have more than one expectation test", function(){
				application.coldbox = application.coldbox * 8;
				// type checks
				expect( application.coldbox )
					.toBeTypeOf( 'numeric' )
					.toBeNumeric();
				// delta ranges
				expect( application.coldbox ).toBeCloseTo( expected=10, delta=2 );
				// negations
				expect( application.coldbox ).notToBe( 4 );
				debug( " >1 expectation tests: coldbox = #application.coldbox#" );
			});

			// negations
			it("can have negative expectations", function(){
				application.coldbox = application.coldbox * 8;
				// type checks
				expect( application.coldbox ).notToBeTypeOf( 'usdate' );
				// dynamic type methods
				expect( application.coldbox ).notToBeArray();
				// delta ranges
				expect( application.coldbox ).notToBeCloseTo( expected=10, delta=2 );
			});

			it( "can get private properties", function(){
				var oTest = new testbox.tests.resources.Test();
				expect( getProperty( oTest, "reload" ) ).toBeFalse();
			});

			// xit() skips
			xit("can have tests that can be skipped easily like this one", function(){
				fail( "xit() this should skip" );
			});

			// acf dynamic skips
			it( title="can have tests that execute if the right environment exists (Lucee only)", body=function(){
				expect( server ).toHaveKey( "Lucee" );
			}, skip=( !isLucee() ));

			// Lucee dynamic skips
			it( title="can have tests that execute if the right environment exists (acf only)", body=function(){
				expect( server ).notToHaveKey( "Lucee" );
			}, skip=( isLucee() ));

			// specs with a random skip closure
			it(title="can have a skip that is executed at runtime", body=function(){
				fail( "Skipped programmatically, this should fail" );
			},skip=function(){ return true; });

			// null expectations
			it( "can have null expectations", function(){
				expect(	javaCast("null", "") ).toBeNull();
				expect(	123 ).notToBeNull();
			});

			// discrete math
			it( "can have discrete math", function(){
				expect( "d" ).toBeGT( "c" );
				expect( 4 ).toBeGT( 1 );

				expect( 4 ).toBeGTE( 4 );
				expect( 1 ).toBeLT( 10 );
				expect( 10 ).toBeLTE( 10 );
			});

		});

		// Custom Matchers
		describe("Custom Matchers", function(){

			beforeEach(function(){
				// add custom matchers
				addMatchers({
					toBeReallyFalse : function( expectation, args={} ){
						arguments.expectation.message = ( structKeyExists( args, "message" ) ? args.message : "[#arguments.expectation.actual#] is not really false" );
						if( arguments.expectation.isNot )
							return ( arguments.expectation.actual eq true );
						else
							return ( arguments.expectation.actual eq false );
					},
					toBeReallyTrue = function( expectation, args={} ){
						arguments.expectation.message = ( structKeyExists( args, "message" ) ? args.message : "[#arguments.expectation.actual#] is not really true" );
						if( arguments.expectation.isNot )
							return ( arguments.expectation.actual eq false );
						else
							return ( arguments.expectation.actual eq true );
					}
				});
				variables.foo = false;
			});

			it("are cool and foo should be really false", function(){
				expect( variables.foo ).toBeReallyFalse();
			});

			it("are still cool and the negation of foo should be really true", function(){
				expect( variables.foo ).notToBeReallyTrue();
			});

			// Custom Matchers
			describe("Nested suite: Testing loading via a CFC", function(){

				beforeEach(function(){
					// add custom matcher via CFC
					addMatchers( new testbox.tests.resources.CustomMatcher() );
					variables.foofoo = false;
				});

				it("should be awesome", function(){
					expect( variables.foofoo ).toBeAwesome();
					debug( " foofoo should be awesome #variables.foofoo#" );
				});

				it("should know its maker", function(){
					expect( "Luis Majano" ).toBeLuisMajano();
				});

				describe("Yet another nested suite", function(){

					it("should have cascaded beforeEach() call from parent", function(){
						expect( foofoo ).toBeAwesome();
					});

					it("should have cascaded beforeEach() call from grandparent", function(){
						expect( foo ).toBeFalse();
					});

				});

			});

			// Another suite
			describe( "Another Nested Suite", function(){

				it( "can also be awesome", function(){
					expect(	foo ).toBeFalse();
				});

			});

		});

		// Skip by env suite
		describe(title="A Lucee only suite", body=function(){

			it("should only execute for Lucee", function(){
				expect( server ).toHaveKey( "Lucee" );
			});

		}, skip=( !isLucee() ));

		// xdescribe() skips the entire suite
		xdescribe("A suite that is skipped via xdescribe()", function(){
			it("will never execute this", function(){
				fail( "This should not have executed" );
			});
		});

		describe("A calculator test suite", function(){
			// before each spec in THIS suite group
			beforeEach(function(){
				// using request until Lucee fixes their closure bugs
				request.calc = calc = new testbox.tests.resources.Calculator();
			});

			// after each spec in THIS suite group
			afterEach(function(){
				structdelete( variables, "calc" );
			});

			it("Can have a separate beforeEach for this suite", function(){
				expect( request.calc ).toBeComponent();
			});

			xit("can add incorrectly and fail", function(){
				var r = calc.add( 2, 2 );
				expect( r ).toBe( 5 );
			});

			it("cannot divide by zero", function(){
				expect( function(){
					request.calc.divide( 4, 0 );
				}).toThrow( regex="zero" );
			});

			it("cannot divide by zero with message regex", function(){
				expect( function(){
					request.calc.divide( 3, 0 );
				}).toThrow( regex="zero" );
			});

			it( "can do throws with no message", function(){
				expect(	function(){
					request.calc.divideNoMessage();
				} ).toThrow( type="DivideByZero" );
			});

			it( "can do throws with message and detail regex", function(){
				expect(	function(){
					request.calc.divideWithDetail();
				} ).toThrow( regex="(zero|impossible)" );

				expect(	function(){
					request.calc.divideWithDetail();
				} ).toThrow( regex="impossible" );
			});

			it("can use a mocked stub", function(){
				c = createStub().$("getData", 4);
				r = request.calc.add( 4, c.getData() );
				expect( r ).toBe( 8 );
				expect( c.$once( "getData") ).toBeTrue();
			});

			xit("can produce errors", function(){
				exxpect();
			});

		});

	}

	private function isLucee(){
		return ( structKeyExists( server, "lucee" ) );
	}

}