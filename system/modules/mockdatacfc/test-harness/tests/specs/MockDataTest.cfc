component extends="coldbox.system.testing.BaseTestCase" appMapping="root" {

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
		super.beforeAll();
		setup();
	}

	function afterAll(){
		super.afterAll();
	}

	/*********************************** BDD SUITES ***********************************/

	function run(){
		describe( "MockData CFC", function(){
			beforeEach( function( currentSpec ){
				variables.mockdataCFC = getInstance( "MockData@MockDataCFC" );
			} );

			it( "can be created", function(){
				expect( mockDataCFC ).toBeComponent();
			} );

			it( "can generate with defaults", function(){
				var r = mockDataCFC.mock();
				expect( r.len() ).toBe( 10 );
			} );

			it( "can generate autoincrementing IDs", function(){
				var r = mockDataCFC.mock( id = "autoincrement" );
				expect( r[ 1 ].id ).toBe( 1 );
				expect( r[ 10 ].id ).toBe( 10 );
			} );

			it( "can generate uuids", function(){
				var r = mockDataCFC.mock( id = "uuid" );
				expect( r[ 1 ].id ).toBeUUID();
			} );

			it( "can generate names", function(){
				var r = mockDataCFC.mock( name = "name" );
				expect( r[ 1 ].name ).toInclude( " " );
			} );

			it( "can generate ages", function(){
				var r = mockDataCFC.mock( age = "age" );
				expect( r[ 1 ].age ).toBeGTE( 18 ).toBeLTE( 75 );
			} );

			it( "can generate all ages", function(){
				var r = mockDataCFC.mock( age = "all_age" );
				expect( r[ 1 ].age ).toBeGTE( 1 ).toBeLTE( 100 );
			} );

			it( "can generate emails", function(){
				var r = mockDataCFC.mock( email = "email" );
				expect( r[ 1 ].email ).toBeEmail();
			} );

			it( "can generate ssn", function(){
				var r = mockDataCFC.mock( ssn = "ssn" );
				expect( r[ 1 ].ssn ).toBeSSN();
			} );

			it( "can generate telephones", function(){
				var r = mockDataCFC.mock( phone = "tel" );
				expect( r[ 1 ].phone ).notToBeEmpty();
			} );

			it( "can generate dates", function(){
				var r = mockDataCFC.mock( createdOn = "date" );
				expect( r[ 1 ].createdOn ).toBeDate();
			} );

			it( "can generate date times", function(){
				var r = mockDataCFC.mock( createdOn = "datetime" );
				expect( r[ 1 ].createdOn ).toBeDate();
			} );

			it( "can generate numbers", function(){
				var r = mockDataCFC.mock( value = "num" );
				expect( r[ 1 ].value ).toBeNumeric().toBeLTE( 10 );
			} );

			it( "can generate numbers with randomness", function(){
				var r = mockDataCFC.mock( value = "num:5" );
				expect( r[ 1 ].value ).toBeNumeric().toBeLTE( 5 );

				var r = mockDataCFC.mock( value = "num:5:6" );
				expect( r[ 1 ].value )
					.toBeNumeric()
					.toBeLTE( 6 )
					.toBeGTE( 5 );
			} );

			it( "can generate one ofs", function(){
				var r = mockDataCFC.mock( gender = "oneof:male:female" );
				expect( r[ 1 ].gender ).toMatch( "(male|female)" );
			} );

			it( "can generate lorem", function(){
				var r = mockDataCFC.mock( notes = "lorem" );
				expect( r[ 1 ].notes ).toinclude( "lorem" );
			} );

			it( "can generate bacon lorem", function(){
				var r = mockDataCFC.mock( notes = "baconlorem" );
				expect( r[ 1 ].notes ).toinclude( "bacon" );
			} );

			it( "can generate sentences", function(){
				var r = mockDataCFC.mock( notes = "sentence" );
				expect( r[ 1 ].notes ).notToBeEmpty();
			} );

			it( "can generate words", function(){
				var r = mockDataCFC.mock( notes = "words" );
				expect( r[ 1 ].notes ).notToBeEmpty();
			} );

			it( "can generate custom data", function(){
				var r = mockDataCFC.mock(
					test = function( index ){
						return "hello";
					}
				);
				expect( r[ 1 ].test ).toBe( "hello" );
			} );

			it( "can generate a website", function(){
				var r = mockDataCFC.mock( homepage = "website" );
				expect( r[ 1 ].homepage ).toBeUrl();
			} );
			it( "can generate https only websites", function(){
				var r = mockDataCFC.mock( homepage = "website_https" );
				r.each( function( item ){
					expect( item.homepage ).toInclude( "https" );
				} );
			} );
			it( "can generate http only websites", function(){
				var r = mockDataCFC.mock( homepage = "website_http" );
				r.each( function( item ){
					expect( item.homepage ).toInclude( "http:" );
				} );
			} );

			it( "can generate a url", function(){
				var r = mockDataCFC.mock( homepage = "url" );
				debug( r );
				expect( r[ 1 ].homepage ).toBeUrl();
			} );

			it( "can generate an image url", function(){
				var r = mockDataCFC.mock( homepage = "imageurl" );
				debug( r );
				expect( r[ 1 ].homepage ).toBeUrl();
			} );

			it( "can generate a string", function(){
				var r = mockDataCFC.mock( test = "string" );
				debug( r );
				expect( r[ 1 ].test ).toHaveLength( 10 );
			} );

			it( "can generate an alpha string", function(){
				var r = mockDataCFC.mock( test = "string-alpha" );
				debug( r );
				expect( r[ 1 ].test ).toHaveLength( 10 );
			} );
			it( "can generate a secure string", function(){
				var r = mockDataCFC.mock( test = "string-secure" );
				debug( r );
				expect( r[ 1 ].test ).toHaveLength( 10 );
			} );
			it( "can generate a numeric string", function(){
				var r = mockDataCFC.mock( test = "string-numeric" );
				debug( r );
				expect( r[ 1 ].test ).toHaveLength( 10 );
			} );

			it( "can generate a big string", function(){
				var r = mockDataCFC.mock( test = "string:200" );
				debug( r );
				expect( r[ 1 ].test ).toHaveLength( 200 );
			} );

			it( "can generate an ip address", function(){
				var r = mockDataCFC.mock( test = "ipaddress" );
				debug( r );
				expect(
					reFindNoCase(
						"^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$",
						r[ 1 ].test
					)
				).toBeTrue();
			} );

			it( "can generate a struct $returnType", function(){
				var r = mockDataCFC.mock(
					$returnType = "struct",
					test        = "string:200",
					name        = "name"
				);
				debug( r );
				expect( r ).toBeStruct().toHaveKey( "test,name" );
			} );
		} );
	}

}
