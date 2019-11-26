/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* The TestBox main base runner which has all the common methods needed for runner implementations.
*/
component{

	/************************************** UTILITY METHODS *********************************************/

	/**
	* Checks if the incoming labels are good for running
	* @incomingLabels The incoming labels to test against this runner's labels.
	* @testResults The testing results object
	*/
	boolean function canRunLabel(
		required array incomingLabels,
		required testResults
	){

		var labels = arguments.testResults.getLabels();
        var excludes = arguments.testResults.getExcludes();

        // do we have labels applied?
        var canRun = true;
		if( arrayLen( labels ) ){
            canRun = false;
			for( var thisLabel in labels ){
				// verify that a label exists, if it does, break, it matches the criteria, if no matches, then skip it.
				if( arrayFindNoCase( incomingLabels, thisLabel ) ){
					// match, so we can run it.
                    canRun = true;
				}
			}
        }

        if ( ! arrayIsEmpty( excludes ) ) {
            for ( var thisExclude in excludes ) {
                if ( arrayFindNoCase( incomingLabels, thisExclude ) ) {
                    canRun = false;
                }
            }
        }

        return canRun;
	}

	/**
	 * Checks if we can run the spec due to using testSpec arguments or incoming URL filters.
	 *
	 * @name The spec name
	 * @testResults The testing results object
	 */
	boolean function canRunSpec(
		required name,
		required testResults
	){
		var testSpecs = arguments.testResults.getTestSpecs();

		// verify we have some?
		if( arrayLen( testSpecs ) ){
			return ( arrayFindNoCase( testSpecs, arguments.name ) ? true : false );
		}

		// we can run it.
		return true;
	}

	/**
	 * Verify if the incoming suite is focused
	 *
	 * @suite The suite rep
	 * @target The spec target
	 * @checkChildren Are we checking child suites?
	 * @checkParent Check the parents!
	 */
	boolean function isSuiteFocused(
		required suite,
		required target,
		boolean checkChildren=true,
		boolean checkParent=true
	){
		// Verify Focused Targets
		if( arrayLen( arguments.target.$focusedTargets.suites ) ){

			// Is this suite focused
			if( arrayFindNoCase( arguments.target.$focusedTargets.suites, arguments.suite.slug & "/" & arguments.suite.name ) ){
				return true;
			}

			// Go upstream little fish, check if you have a parent suite that can be executed.
			var parentSuite = arguments.suite.parentRef;
			while ( !isSimpleValue( parentSuite ) ) {
				// Is parent focused?
				if( isSuiteFocused( suite=parentSuite, target=arguments.target, checkChildren=false ) ){
					return true;
				}
				// Go on up
				parentSuite = parentSuite.parentRef;
			}

			// Go downstream little fish, check if you have children suites that are focused
			if( arguments.checkChildren ){
				for( var thisSuite in arguments.suite.suites ){
					// go down the rabitt hole
					if( isSuiteFocused( suite=thisSuite, target=arguments.target, checkParent=false ) ){
						return true;
					}
				}
			}

			// We are not focused :(
			return false;
		}

		return true;
	}

	/**
	 * Checks if we can run the suite due to using testSuite arguments or incoming URL filters.
	 *
	 * @suite The suite definition
	 * @testResults The testing results object
	 * @target The target object
	 */
	boolean function canRunSuite(
		required suite,
		required testResults,
		required target
	){

		var testSuites = arguments.testResults.getTestSuites();

		// Are we focused
		if( !isSuiteFocused( arguments.suite, arguments.target ) ){
			return false;
		}

		// verify we have some?
		if( arrayLen( testSuites ) ){
			var results = ( arrayFindNoCase( testSuites, arguments.suite.name ) ? true : false );

			// Verify nested if no match, maybe it is an embedded suite that is trying to execute.
			if( results == false && arrayLen( arguments.suite.suites ) ){
				for( var thisSuite in arguments.suite.suites ){
					// go down the rabitt hole
					if( canRunSuite( thisSuite, arguments.testResults, arguments.target ) ){
						return true;
					}
				}
				return false;
			}

			// Verify hierarchy slug
			if( results == false && len( arguments.suite.slug ) ){
				var slugArray = listToArray( arguments.suite.slug, "/" );
				for( var thisSlug in slugArray ){
					if( arrayFindNoCase( testSuites, thisSlug ) ){
						return true;
					}
				}
				return false;
			}

			return results;
		}

		// we can run it.
		return true;
	}

	/**
	* Checks if we can run the test bundle due to using testBundles arguments or incoming URL filters.
	* @suite The suite definition
	* @testResults The testing results object
	*/
	boolean function canRunBundle(
		required bundlePath,
        required testResults,
        required targetMD
	){
		var testBundles = arguments.testResults.getTestBundles();

		// verify we have some?
		if( arrayLen( testBundles ) ){
			return ( arrayFindNoCase( testBundles, arguments.bundlePath ) ? true : false );
		}

		// we can run it.
		return true;
	}

	/**
	* Validate the incoming method name is a valid TestBox test method name
	* @methodName The method name to validate
	* @target The target object
	*/
	boolean function isValidTestMethod( required methodName, required target ) {
		// True if annotation "test" exists
		if( structKeyExists( getMetadata( arguments.target[ arguments.methodName ] ), "test" ) ){
			return true;
		}
		// All xUnit test methods must start or end with the term, "test".
		return( !! reFindNoCase( "(^test|test$)", methodName ) );
	}

	/**
	* Get metadata from a method
	* @target The target method
	* @name The annotation to look for
	* @defaultValue The default value to return if not found
	*/
	function getMethodAnnotation( required target, required name, defaultValue="" ){
		var md = getMetadata( arguments.target );

		if( structKeyExists( md, arguments.name ) ){
			return ( len( md[ arguments.name ] ) ? md[ arguments.name ] : true );
		}
		else{
			return arguments.defaultValue;
		}
	}

}
