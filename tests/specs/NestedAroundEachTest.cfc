/**
* My BDD Test
*/
component extends="testbox.system.BaseSpec"{

    // Count the invocations of "around" methods
    variables.counter = 0;
/*********************************** LIFE CYCLE Methods ***********************************/

	// executes before all suites+specs in the run() method
	function beforeAll(){
	}

	// executes after all suites+specs in the run() method
	function afterAll(){
	}

/*********************************** BDD SUITES ***********************************/

	function run(){

		describe( "Outer describe", function(){

            it( "the counter should be initially at 0", function() {
                expect( variables.counter ).toBe( 0 );
            });

			describe( "Some describe block", function(){

                aroundEach(function(spec, suite) {
                    variables.counter++;
                    spec.body();
                });

                it( "should additionally execute the aroundEach as normal", function() {
                    expect( variables.counter ).toBe( 1 );
                });

                describe( "Inner describe block", function(){

                    it( "the aroundEach from the parent context should be ran", function(){
                        expect( variables.counter ).toBe( 2 );
                    });

                });

			});
		});
	}

}
