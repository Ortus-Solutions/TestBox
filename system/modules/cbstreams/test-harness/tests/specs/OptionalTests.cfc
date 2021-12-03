component extends="testbox.system.BaseSpec"{

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
	}

	function afterAll(){
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "CB Optional", function(){

			story( "I can create optionals", function(){
				given( "nothing to the constructor", function(){
					then( "it should build an empty optional", function(){
                        var optional = new cbstreams.models.Optional();
                        expect( optional.isPresent() ).toBeFalse();
					});
                });
                given( "a java optional", function(){
					then( "it should build it with that optional", function(){
                        var optional = new cbstreams.models.Optional(
                            createObject( "java", "java.util.Optional" ).of( "luis" )
                        );
                        expect( optional.isPresent() ).toBeTrue();
					});
				});
            });
            
            it( "can equal optionals", function(){
                var optional = new cbstreams.models.Optional(
                    createObject( "java", "java.util.Optional" ).of( "luis" )
                );
                expect( optional.isEqual( 
                    createObject( "java", "java.util.Optional" ).of( "joe" )
                 ) ).toBeFalse();

                 expect( optional.isEqual( 
                    createObject( "java", "java.util.Optional" ).of( "luis" )
                 ) ).toBeTrue();
            } );

            it( "can get a hash code", function(){
                var optional = new cbstreams.models.Optional(
                    createObject( "java", "java.util.Optional" ).of( "luis" )
                );
                expect( optional.hashcode() ).notToBeEmpty();
            } );

            it( "can invoke if present consumers", function(){
                var consumerValue = "";

                var optional = new cbstreams.models.Optional().of( "luis" );
                    optional
                    .ifPresent( function( e ){
                        consumerValue = e;
                    } );

                expect( consumerValue ).toBe( "luis" );
            } );

            it( "can return orElse() ", function(){
                var optional = new cbstreams.models.Optional();
                expect( optional.orElse( "luis" ) ).toBe( "luis" );

                var optional = new cbstreams.models.Optional().of( "alexia" );
                expect( optional.orElse( "luis" ) ).toBe( "alexia" );
            } );

            it( "can return orElseGet() ", function(){
                var optional = new cbstreams.models.Optional();
                expect( optional.orElseGet( function(){
                    return "luis";
                } ) ).toBe( "luis" );
            } );

            it( "can return toString() representations ", function(){
                var optional = new cbStreams.models.Optional().of( "luis" );
                expect( optional.toString() ).toInclude( "luis" );
            } );

		});

	}

}