/**
 * This tests the BDD functionality in TestBox.
 */
component extends="testbox.system.BaseSpec" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		// print( "<h2>BDD Testing is Awesome!</h2>" );
		console( "Executed beforeAll() at #now()# " );
	}

	function afterAll(){
		console( "Executed afterAll() at #now()#" );
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		/**
		 * describe() starts a suite group of spec tests.
		 * Arguments:
		 *
		 * @title    The title of the suite, Usually how you want to name the desired behavior
		 * @body     A closure that will resemble the tests to execute.
		 * @labels   The list or array of labels this suite group belongs to
		 * @asyncAll If you want to parallelize the execution of the defined specs in this suite group.
		 * @skip     A flag that tells TestBox to skip this suite group from testing if true
		 */
		describe(
			title  = "A spec",
			labels = "luis",
			body   = function(){
				// before each spec in THIS suite group
				beforeEach( function(){
					coldbox = 0;
					coldbox++;
					debug( "beforeEach suite: coldbox = #coldbox#" );
				} );

				// after each spec in THIS suite group
				afterEach( function(){
					foo = 0;
				} );

				describe( "A nice /suite/with/slashes", function(){
					it( "can have slashes/inthe/it", function(){
						expect( true ).toBeTrue();
					} );
				} );

				it( "can match strings with no case sensitivity", function(){
					expect( "Luis" ).toMatch( "^luis" );
				} );
				it( "can match strings with case sensitivity", function(){
					expect( "Luis" ).notToMatchWithCase( "^luis" );
					expect( "luis" ).ToMatchWithCase( "^luis" );
				} );

				/**
				 * it() describes a spec to test. Usually the title is prefixed with the suite name to create an expression.
				 * Arguments:
				 *
				 * @title  The title of the spec
				 * @spec   A closure that represents the test to execute
				 * @labels The list or array of labels this spec belongs to
				 * @skip   A flag that tells TestBox to skip this spec from testing if true
				 */
				it(
					title = "is just a closure so it can contain code",
					body  = function(){
						expect( coldbox ).toBe( 1 );
					},
					labels = "luis"
				);

				it( "can satisfy truth tests", function(){
					expect( 1 ).toSatisfy( function( num ){
						return arguments.num > 0;
					} );
					expect( 0 ).notToSatisfy( function( num ){
						return arguments.num > 0;
					} );

					expect( this ).toSatisfy( function( target ){
						return isObject( arguments.target );
					} );
				} );

				it( "can validate instance types", function(){
					expect( this ).toBeInstanceOf( "testbox.system.BaseSpec" );
					expect( now() ).toBeInstanceOf( "java.util.Date" );
					expect( [] ).toBeInstanceOf( "java.util.List" );
					expect( {} ).toBeInstanceOf( "java.util.Map" );
					expect( queryNew( "" ) ).notToBeInstanceOf( "Query" );
				} );

				it( "can validate json", function(){
					var data = serializeJSON( { name : "luis", when : now() } );
					expect( "luis" ).notToBeJSON();
					expect( data ).toBeJSON();
				} );

				// more than 1 expectation
				it( "can have more than one expectation test", function(){
					coldbox = coldbox * 8;
					// type checks
					expect( coldbox ).toBeTypeOf( "numeric" ).toBeNumeric();
					// delta ranges
					expect( coldbox ).toBeCloseTo( expected = 10, delta = 2 );
					// negations
					expect( coldbox ).notToBe( 4 );
					debug( " >1 expectation tests: coldbox = #coldbox#" );
				} );

				// ToInclude and ToBeIn
				it( "can check includes with strings", function(){
					expect( "Hola luis, how are you" ).toInclude( "luis" );
					expect( "Hola luis, how are you" ).notToInclude( "pete" );
				} );
				it( "can check includes with arrays", function(){
					expect( [ "l", "lui", "luis", "joe" ] ).toInclude( "luis" );
					expect( [ "l", "lui", "joe" ] ).notToInclude( "luis" );
				} );
				it( "can check an expected needle to exist in a string", function(){
					expect( "luis" ).toBeIn( "Hola luis, how are you" );
					expect( "joe" ).notToBeIn( "Hola luis, how are you" );
				} );
				it( "can check an expected needle to exist in an array", function(){
					expect( "luis" ).toBeIn( [ "l", "lui", "luis", "joe" ] );
					expect( "luis" ).notToBeIn( [ "l", "lui", "joe" ] );
				} );

				// toStartWith
				it( "can check if a string starts with the actual value", function(){
					expect( "hello world" ).toStartWith( "hello" );
					expect( "world peace" ).notToStartWith( "hello" );
				} );
				it( "can check if a string starts with the actual value with case-sensitivity", function(){
					expect( "Hello world" ).toStartWithCase( "Hello" );
					expect( "Hello peace" ).notToStartWithCase( "hello" );
				} );

				// toEndWith
				it( "can check if a string ends with the actual value", function(){
					expect( "hello world" ).toEndWith( "LD" );
					expect( "world peace" ).notToEndWith( "world" );
				} );
				it( "can check if a string ends with the actual value with case-sensitivity", function(){
					expect( "Hello world" ).toEndWithCase( "ld" );
					expect( "Hello peace" ).notToEndWithCase( "peeee" );
				} );

				// negations
				it( "can have negative expectations", function(){
					coldbox = coldbox * 8;
					// type checks
					expect( coldbox ).notToBeTypeOf( "usdate" );
					// dynamic type methods
					expect( coldbox ).notToBeArray();
					// delta ranges
					expect( coldbox ).notToBeCloseTo( expected = 10, delta = 2 );
				} );

				it( "can get private properties", function(){
					var oTest = new testbox.tests.resources.Test();
					expect( getProperty( oTest, "reload" ) ).toBeFalse();
				} );

				// xit() skips
				xit( "can have tests that can be skipped easily like this one", function(){
					fail( "xit() this should skip" );
				} );

				// acf dynamic skips
				it(
					title = "can have tests that execute if the right environment exists (Lucee only)",
					body  = function(){
						expect( server ).toHaveKey( "Lucee" );
					},
					skip = ( !isLucee() )
				);

				// Lucee dynamic skips
				it(
					title = "can have tests that execute if the right environment exists (acf only)",
					body  = function(){
						expect( server ).notToHaveKey( "Lucee" );
					},
					skip = ( isLucee() )
				);

				// specs with a random skip closure
				it(
					title = "can have a skip that is executed at runtime",
					body  = function(){
						fail( "Skipped programmatically, this should fail" );
					},
					skip = function( spec ){
						spec.name &= " - skipping this because I can!!!";
						return true;
					}
				);

				// null expectations
				it( "can have null expectations", function(){
					expect( javacast( "null", "" ) ).toBeNull();
					expect( 123 ).notToBeNull();
				} );

				// discrete math
				it( "can have discrete math", function(){
					expect( "d" ).toBeGT( "c" );
					expect( 4 ).toBeGT( 1 );

					expect( 4 ).toBeGTE( 4 );
					expect( 1 ).toBeLT( 10 );
					expect( 10 ).toBeLTE( 10 );
				} );

				it( "can test a collection", function(){
					expectAll( [ 2, 4, 6, 8 ] ).toSatisfy( function( x ){
						return 0 == x % 2;
					} );
					expectAll( { a : 2, b : 4, c : 6 } ).toSatisfy( function( x ){
						return 0 == x % 2;
					} );
					// and we can chain matchers
					expectAll( [ 2, 4, 6, 8 ] ).toBeGTE( 2 ).toBeLTE( 8 );
				} );

				it( "can fail any element of a collection", function(){
					try {
						// we need to verify the expectation fails
						expectAll( [ 2, 4, 10, 8 ] ).toBeLT( 10 );
						fail( "expectAll() failed to detect a bad element" );
					} catch ( any e ) {
						expect( e.message ).toBe( "The actual [10] is not less than [10]" );
					}
				} );

				it( "can process structure key expectations", function(){
					var s = { "data" : {}, "error" : {}, "name" : {}, "age" : 0 };

					expect( s ).toHaveKey( "error" );
					expect( s ).notToHaveKey( "luis" );

					// Multiple
					expect( s ).toHaveKey( "data,error,name,age" );
					expect( function(){
						expect( s ).toHaveKey( "data,error,name,age2" );
					} ).toThrow();
					expect( s ).notToHaveKey( "luis,joe,tom" );
					expect( function(){
						expect( s ).toHaveKey( "luis,joe,data" );
					} ).toThrow();
				} );
			}
		);

		// Custom Matchers
		describe( "Custom Matchers", function(){
			beforeEach( function(){
				// add custom matchers
				addMatchers( {
					toBeReallyFalse : function( expectation, args = {} ){
						expectation.message = (
							structKeyExists( args, "message" ) ? args.message : "[#expectation.actual#] is not really false"
						);
						if ( expectation.isNot ) return ( expectation.actual eq true );
						else return ( expectation.actual eq false );
					},
					toBeReallyTrue : function( expectation, args = {} ){
						expectation.message = (
							structKeyExists( args, "message" ) ? args.message : "[#expectation.actual#] is not really true"
						);
						if ( expectation.isNot ) return ( expectation.actual eq false );
						else return ( expectation.actual eq true );
					}
				} );
				foo = false;
			} );

			it( "are cool and foo should be really false", function(){
				expect( foo ).toBeReallyFalse();
			} );

			it( "are still cool and the negation of foo should be really true", function(){
				expect( foo ).notToBeReallyTrue();
			} );

			// Custom Matchers
			describe( "Nested suite: Testing loading via a CFC", function(){
				beforeEach( function(){
					// add custom matcher via CFC
					addMatchers( new testbox.tests.resources.CustomMatcher() );
					foofoo = false;
				} );

				it( "should be awesome", function(){
					expect( foofoo ).toBeAwesome();
					debug( " foofoo should be awesome #foofoo#" );
				} );

				it( "should know its maker", function(){
					expect( "Luis Majano" ).toBeLuisMajano();
				} );

				describe( "Yet another nested suite", function(){
					it( "should have cascaded beforeEach() call from parent", function(){
						expect( foofoo ).toBeAwesome();
					} );

					it( "should have cascaded beforeEach() call from grandparent", function(){
						expect( foo ).toBeFalse();
					} );
				} );
			} );

			// Another suite
			describe( "Another Nested Suite", function(){
				it( "can also be awesome", function(){
					expect( foo ).toBeFalse();
				} );
			} );
		} );

		// skip() by inline function call
		describe(
			title = "A suite that gets skipped inline via skip()",
			body  = function(){
				it( "should be skipped", function(){
					skip();
				} );
			}
		);

		// Skip by env suite
		describe(
			title = "A Lucee only suite",
			body  = function(){
				it( "should only execute for Lucee", function(){
					expect( server ).toHaveKey( "Lucee" );
				} );
			},
			skip = ( !isLucee() )
		);

		// xdescribe() skips the entire suite
		xdescribe( "A suite that is skipped via xdescribe()", function(){
			it( "will never execute this", function(){
				fail( "This should not have executed" );
			} );
		} );

		describe( "A calculator test suite", function(){
			// before each spec in THIS suite group
			beforeEach( function(){
				// using request until Lucee fixes their closure bugs
				request.calc = calc = new testbox.tests.resources.Calculator();
			} );

			// after each spec in THIS suite group
			afterEach( function(){
				structDelete( variables, "calc" );
			} );

			it( "Can have a separate beforeEach for this suite", function(){
				expect( request.calc ).toBeComponent();
			} );

			xit( "can add incorrectly and fail", function(){
				var r = calc.add( 2, 2 );
				expect( r ).toBe( 5 );
			} );

			it( "cannot divide by zero", function(){
				expect( function(){
					request.calc.divide( 4, 0 );
				} ).toThrow( regex = "zero" );
			} );

			it( "cannot divide by zero with message regex", function(){
				expect( function(){
					request.calc.divide( 3, 0 );
				} ).toThrow( regex = "zero" );
			} );

			it( "can do throws with no message", function(){
				expect( function(){
					request.calc.divideNoMessage();
				} ).toThrow( type = "DivideByZero" );
			} );

			it( "can do throws with message and detail regex", function(){
				expect( function(){
					request.calc.divideWithDetail();
				} ).toThrow( regex = "(zero|impossible)" );

				expect( function(){
					request.calc.divideWithDetail();
				} ).toThrow( regex = "impossible" );
			} );

			it( "can use a mocked stub", function(){
				c = createStub().$( "getData", 4 );
				r = calc.add( 4, c.getData() );
				expect( r ).toBe( 8 );
				expect( c.$once( "getData" ) ).toBeTrue();
			} );

			xit( "can produce errors", function(){
				exxpect();
			} );

			it( "can mock any type of data", function(){
				var data = mockData( name: "name", age: "age", id: "uuid" );
				debug( data );
				expect( data ).notToBeEmpty();
			} );

			it( "can load the output utilities into request.testbox", function(){
				expect( request.testbox ).toHaveKey( "clearDebugBuffer,console,debug,print,println" );
			} );
		} );

		describe( "In depth throwing exceptions", function(){
			it( "throws a FooException", function(){
				expect( function(){
					throw( type = "FooException" );
				} ).toThrow( "FooException" );
			} );
			it( "won't throw a FooException because nothing is thrown", function(){
				expect( function(){
				} ).notToThrow( "FooException" );
			} );
			it( "won't throw a FooException because a different exception is thrown", function(){
				expect( function(){
					throw( type = "DifferentException" );
				} ).notToThrow( "FooException" );
			} );
			it( "will fail when no regex provided if any exception occurs", function(){
				// Exception Inception!
				expect( function(){
					expect( function(){
						throw( type = "AnyException" );
					} ).notToThrow();
				} ).toThrow( "TestBox.AssertionFailed" );
			} );
		} );
	}

	private function isLucee(){
		return ( structKeyExists( server, "lucee" ) );
	}

}
