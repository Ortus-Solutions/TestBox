component extends="testbox.system.BaseSpec"{

	/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeAll(){
	}

	function afterAll(){
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "CB Streams", function(){

			beforeEach(function( currentSpec ){
				out = createObject( "java", "java.lang.System" ).out;
			});


			xit( "testing parallel threads", function(){
				var results = new cbstreams.models.Stream( "one,two,three,four,six,seven,eight,nine" )
					.parallel()
					.filter( function( item ){
						//out.println( "**** Filter (#arguments.item#) Thread Name: #createObject( "java", "java.lang.Thread" ).currentThread().getName()#" );
						return arguments.item.len() > 3;
					} )
					.map( function( item ){
						//out.println( "**** Map (#arguments.item#) Thread Name: #createObject( "java", "java.lang.Thread" ).currentThread().getName()#" );
						return ucase( arguments.item );
					} )
					.collect();

				expect( results ).toHaveLength( 5 );
			});

			story( "I can initialize a stream with many data types", function(){
				given( "nothing to the constructor", function(){
					then( "it should build an empty stream", function(){
						var stream = new cbstreams.models.Stream();
						expect( stream.count() ).toBe( 0 );
					});
				});

				given( "a list", function(){
					then( "it should build a list stream", function(){
						var stream = new cbstreams.models.Stream( "1,2,3" );
						expect( stream.count() ).toBe( 3 );
					});
				});

				given( "an array", function(){
					then( "it should build an array stream", function(){
						var stream = new cbstreams.models.Stream( [1,2,3] );
						expect( stream.count() ).toBe( 3 );
					});
				});

				given( "a struct", function(){
					then( "it should build a collection stream", function(){
						var stream = new cbstreams.models.Stream( {
							name = "luis majano",
							age = 40
						} );
						expect( stream.count() ).toBe( 2 );
					});
				});
			});


			story( "I can generate streams from a query", function(){
				given( "a query", function(){
					then( "it will generate the correct stream", function(){
						var q = querySim( "id,name
						1 | luis
						2 | Joe
						3 | Bill
						4 | Juan" );

						var data = new cbstreams.models.Stream( q )
							.filter( function( item ){
								return item.name.findNoCase( "ui" );
							} )
							.toArray();
						expect( arrayLen( data ) ).toBe( 1 );
					});
				});
			});

			story( "I can generate streams from different providers", function(){
				given( "a sequential stream using the `of` method", function(){
					then( "an ordered stream will be created", function(){
						var stream = new cbstreams.models.Stream().of( "1", "2", "3" );
						expect( stream.count() ).toBe( 3 );
					} );
				} );

				given( "a string", function(){
					then( "it can create a character stream", function(){
						var stream = new cbstreams.models.Stream().ofChars( "luis" );
						expect( stream.count() ).toBe( 4 );
					} );
				} );

				given( "a file path", function(){
					then( "a stream of the file lines will be created", function(){
						var stream = new cbstreams.models.Stream().ofFile( expandPath( "/cbstreams/box.json" ) );
						try{
							expect( stream.findFirst().get() ).toBe( "{" );
						} finally{
							stream.close();
						}
					} );
				} );
			});

			story(
				story="I can use generation of streams",
				skip=( !server.keyExists( "lucee" ) ),
				body=function(){
				given( "a limited infinite stream", function() {
					then( "a stream of data will be generated", function() {
						var data = new cbstreams.models.Stream().generate( function(){
							return createUUID();
						} )
						.limit( 5 )
						.collect();

						expect( data.len() ).toBe( 5 );
					} );
				} );
			} );

			story( "I can generate streams from ranges", function(){
				given( "An open range of 1-4", function(){
					then( "a stream of 3 will be created", function(){
						var data = new cbstreams.models.Stream()
							.range( 1, 4 )
							.map( function( item ){
								return createUUID();
							} )
							.toArray();

						expect( arrayLen( data ) ).toBe( 3 );
					});
				});
				given( "A closed range of 1-4", function(){
					then( "a stream of 4 will be created", function(){
						var data = new cbstreams.models.Stream()
							.rangeClosed( 1, 4 )
							.map( function( item ){
								return createUUID();
							} )
							.toArray();

						expect( arrayLen( data ) ).toBe( 4 );
					});
				});
			});

			story( "I can limit streams", function(){
				given( "a discrete stream", function(){
					then( "it can be limited", function(){
						var stream = new cbstreams.models.Stream( "1,2,3,4" ).limit( 1 );
						expect( stream.count() ).toBe( 1 );
					} );
				} );
			} );

			story( "I can distinct streams", function(){
				given( "a repetitive stream", function(){
					then( "it can be returned in a distinct manner", function(){
						var stream = new cbstreams.models.Stream( "1,1,1" ).distinct();
						expect( stream.count() ).toBe( 1 );
					} );
				} );
			} );

			story( "I want to build native cf structs from collection entry sets", function(){
				given( "a struct as input to a stream", function(){
					then( "I can get a key/value representation", function(){
						var stream = new cbstreams.models.Stream( {
							name = "luis majano",
							age = 40
						} );
						var r = stream.findFirst().get();
						expect( r ).toBeStruct();
					} );
				} );
			} );

			story( "I can skip stream elements", function(){
				given( "a stream with a skip() call", function(){
					then( "it will return only the non-skipped elements", function(){
						var stream = new cbstreams.models.Stream( "1,2,3" ).skip( 1 );
						expect( stream.count() ).toBe( 2 );
					} );
				} );
			} );

			story( "I can leverage map functions", function(){
				given( "a stream with a map() call", function(){
					then( "it will transform the elements", function(){
						var aStream = new cbstreams.models.Stream( "abc1,abc2,abc3" )
							.map( function( element ){
								return element.substring( 0, 3 );
							})
							.limit( 1 )
							.toArray();
						expect( aStream[ 1 ] ).toBe( "abc" );
					} );
				} );
			} );

			story( "I can leverage filter functions", function(){
				given( "a stream with a filter() call", function(){
					then( "it will filter the elements", function(){
						var aStream = new cbstreams.models.Stream( "abc1,abc2,abc3" )
							.filter( function( element ){
								return findNoCase( "abc1", element );
							})
							.toArray();
						expect( aStream[ 1 ] ).toBe( "abc1" );
					} );
				} );
			} );

			story( "I can leverage reduce functions", function(){
				given( "a stream with a reduce() call with an accumulator only", function(){
					then( "it will reduce the elements", function(){
						var reduced = new cbstreams.models.Stream( "1,2,3" )
							.reduce( function( a, b ){
								return a + b;
							})
							.get();
						//debug( reduced );
						// 1+2+3 = 6
						expect( reduced ).toBe( 6 );
					} );
				} );

				given( "a stream with a reduce() call with an accumulator and a seed", function(){
					then( "it will reduce the elements with the seed", function(){
						var reduced = new cbstreams.models.Stream( "1,2,3" )
							.reduce( function( a, b ){
								return a + b;
							}, 10 );
						//debug( reduced );
						// 10+1+2+3 = 16
						expect( reduced ).toBe( 16 );
					} );
				} );
			} );

			story( "I can create an empty stream", function(){
				given( "A call to empty()", function(){
					then( "it will create an empty sequential stream", function(){
						var stream = new cbstreams.models.Stream().empty();
						expect( stream.count() ).toBe( 0 );
					} );
				} );
			} );

			story( "I can create a stream a leverage the forEach functions", function(){
				given( "A basic stream with a forEach", function(){
					then( "I can output it to the debug console", function(){
						var stream = new cbStreams.models.Stream( "luis,alexia,lucas" );
						var output = [];
						stream.forEach( function( element ){
							output.append( element );
						});
						expect( output.len() ).toBe( 3 );
					} );
				} );
				given( "An ordered stream with a forEachOrdered", function(){
					then( "I can output it to the debug console", function(){
						var stream = new cbStreams.models.Stream( "luis,alexia,lucas" );
						var output = [];
						stream.forEachOrdered( function( element ){
							output.append( element );
						});
						expect( output.len() ).toBe( 3 );
					} );
				} );
			} );

			story( "I can find a match in a stream with short-cicuiting activities", function(){
				given( "A call to anyMatch() with a match", function(){
					then( "will produce true", function(){
						var results = new cbstreams.models.Stream( "1,2,3" )
							.anyMatch( function( count ){
								return count gt 1;
							} );
						expect( results ).toBeTrue();
					} );
				} );
				given( "A call to anyMatch() without a match", function(){
					then( "will not produce", function(){
						var results = new cbstreams.models.Stream( "1,2,3" )
							.anyMatch( function( count ){
								return count gt 10;
							} );
						expect( results ).toBeFalse();
					} );
				} );
			} );

			story( "I can find all matches in a stream with short-cicuiting activities", function(){
				given( "A call to allMatch() with a match", function(){
					then( "will produce true", function(){
						var results = new cbstreams.models.Stream( "1,2,3" )
							.allMatch( function( count ){
								return count lt 4;
							} );
						expect( results ).toBeTrue();
					} );
				} );
				given( "A call to allMatch() without a match", function(){
					then( "will not produce", function(){
						var results = new cbstreams.models.Stream( "1,2,3" )
							.allMatch( function( count ){
								return count gt 10;
							} );
						expect( results ).toBeFalse();
					} );
				} );
			} );

			story( "I can peek into the stream as it progresses", function(){
				given( "A stream with peek() operations", function(){
					then( "then I can peek into it.", function(){
						var results = new cbstreams.models.Stream( "one,two,three,four" )
							.filter( function( e ){
								return e.len() > 3;
							} )
							.peek( function( e ){
								debug( "Filtered Value " & e );
							} )
							.map( function( e ){
								return ucase( e );
							} )
							.peek( function( e ){
								debug( "Mapped Value " & e );
							} )
							.collect();
						expect( results ).toHaveLength( 2 );
					} );
				} );
			} );

			story( "I can do numerical operations on streams", function(){
				beforeEach( function(){
					numberStream = new cbstreams.models.Stream(
						collection="1,2,3,4,5,6",
						isNumeric=true
					);
				} );
				given( "A call to max()", function(){
					then( "it will produce the maximum number in the stream", function(){
						var max = numberStream.max().get();
						expect( max ).toBe( 6 );
					} );
				} );
				given( "A call to min()", function(){
					then( "it will produce the minimum number in the stream", function(){
						var min = numberStream.min().get();
						expect( min ).toBe( 1 );
					} );
				} );
				given( "A call to average()", function(){
					then( "it will produce the average number in the stream", function(){
						var average = numberStream.average().get();
						expect( average ).toBe( 3.5 );
					} );
				} );

				given( "A call to summaryStatistics()", function(){
					then( "it will produce stats about the stream", function(){
						var stats = numberStream.summaryStatistics();
						expect( stats ).toBeStruct();
					} );
				} );
			} );

			story( "I can collect streams into different types", function(){

				beforeEach( function(){
					people = [
						{ name = "luis", id = 1, when = now(), price="30" },
						{ name = "alexia", id = 2, when = now(), price="25" },
						{ name = "lucas", id = 2, when = now(), price="30" }
					];
				} );

				given( "The groupingBy collection", function(){
					then( "it will produce a grouped result", function(){
						var aPeople = new cbStreams.models.Stream( people )
							.collectGroupingBy( function( item ){
								return item.price;
							} );

						expect( aPeople[ 25 ] ).toHaveLength( 1 );
						expect( aPeople[ 30 ] ).toHaveLength( 2 );
					} );
				} );

				given( "The summing collection", function(){
					then( "it will produce a summed result", function(){
						var aSum = new cbStreams.models.Stream( people )
							.collectSum( function( item ){
								return item.price;
							} );
						expect( aSum ).toBe( 85 );
					} );
				} );

				given( "The average collection", function(){
					then( "it will produce an average result", function(){
						var aAverage = new cbStreams.models.Stream( people )
							.collectAverage( function( item ){
								return item.price;
							} );

						expect(	aAverage ).toBeGT( 28 );
					} );
				} );

				given( "The summary collection", function(){
					then( "it will produce a summary report result", function(){
						var aSummary = new cbStreams.models.Stream( people )
							.collectSummary( function( item ){
								return item.price;
							} );
						expect(	aSummary ).toBeStruct()
							.toHaveKey( "average" )
							.toHaveKey( "count" )
							.toHaveKey( "max" )
							.toHaveKey( "min" )
							.toHaveKey( "sum" );
					} );
				} );

				given( "The default array collector", function(){
					then( "it will produce an array collection", function(){
						var aNames = new cbStreams.models.Stream( people )
							.map( function( element ){
								return element.name;
							} )
							.sorted()
							.collect();

						expect( aNames ).toHaveLength( 3 ).toBeArray();
					} );
				} );

				given( "The list collector", function(){
					then( "it will produce a string list of the collection", function(){
						var aNames = new cbStreams.models.Stream( people )
							.map( function( element ){
								return element.name;
							} )
							.sorted()
							.collectAsList( "|" );

						expect( aNames ).toBeString();
						expect( listLen( aNames, "|" ) ).toBe( 3 );
					} );
				} );

				given( "The struct collector and a key and id mapper", function(){
					then( "it will produce a struct of the collection of those mappers", function(){

						var results = new cbStreams.models.Stream( people )
							.collectAsStruct( "id", "name" );
						expect( results )
							.toBeStruct();
					} );
				} );
			} );

		});

	}

}