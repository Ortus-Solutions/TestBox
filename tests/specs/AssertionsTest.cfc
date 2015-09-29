component displayName="TestBox xUnit suite for cf10 and above" labels="lucee,cf" extends="Assertionscf9Test"{

	function beforeTests(){
		super.beforeTests();
		addAssertions({
			isAwesome = function( required expected ){
				return ( arguments.expected == "Luis Majano" ? true : fail( 'not luis majano' ) );
			},
			isNotAwesome = function( required expected ){
				return ( arguments.expected == "Luis Majano" ? fail( 'luis majano is always awesome' ) : true );
			}
		});
	}

	function testFloatingPointNumberAddition(){
		var sum = 196.4 + 196.4 + 180.8 + 196.4 + 196.4 + 180.8 + 609.6;
		// sum.toString() outputs: 1756.8000000000002
		debug( toString( sum ) == 1756.8 );
		$assert.isEqual( sum, 1756.8 );
	}

	function testThrows(){
		$assert.throws(function(){
			var hello = invalidFunction();
		});
	}

	function testNotThrows(){
		$assert.notThrows(function(){
			var hello = 1;
		});
	}

	function testAwesomeCustomAssertion(){
		$assert.isAwesome( "Luis Majano" );
	}

	function testNegatedAwesomeCustomAssertion(){
		$assert.isNotAwesome( "Lui Majan" );
	}

	function testIsEmptyFunctions(){
		$assert.throws( function(){
			$assert.isEmpty( variables.beforeTests );
			$assert.isEmpty( function(){} );
		} );
	}

}