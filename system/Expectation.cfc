/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* The Expectation CFC holds a current expectation with all the required matcher methods to provide you
* with awesome BDD expressions and testing.
*/
component accessors="true"{

	// The reference to the spec this matcher belongs to.
	property name="spec";
	// The assertions reference
	property name="assert";
	// The MockBox reference
	property name="mockbox";

	// Public properties for this Expectation to use with the BDD DSL
	// The actual value
	this.actual 	= "";
	// The negation bit
	this.isNot 		= false;
	// Custom messages
	this.message 	= "";

	/**
	* Constructor
	* @spec The spec that this matcher belongs to.
	* @assertions The TestBox assertions object: testbox.system.Assertion
	* @mockbox A reference to MockBox
	*/
	function init(
		required any spec,
		required any assertions,
		required any mockBox

	){

		variables.spec 		= arguments.spec;
		variables.mockBox 	= arguments.mockbox;
		variables.assert 	= arguments.assertions;

		return this;
	}

	/**
	* Registers a custom matcher on this Expectation object
	* @name The name of the custom matcher
	* @body The body closure/udf representing this matcher.
	*/
	function registerMatcher( required name, required body ){
		// store new custom matcher function according to specs
		this[ arguments.name ] = variables[ arguments.name ] = function(){
			// execute custom matcher
			var results = body( this, arguments );
			// if not passed, then fail the custom matcher, else you can concatenate
			return( !results ? variables.assert.fail( this.message ) : this );
		};
	}

	/**
	* Fail an assertion
	* @message The message to fail with.
	*/
	function fail( message="" ){
		variables.assert.fail( argumentCollection=arguments );
	}

	/**
	* Process dynamic expectations like any matcher starting with the word "not" is negated
	*/
	function onMissingMethod( required missingMethodName, required missingMethodArguments ){

		// detect negation
		if( left( arguments.missingMethodName, 3 ) eq "not" ){
			// remove NOT
			arguments.missingMethodName = right( arguments.missingMethodName, len( arguments.missingMethodName ) - 3 );
			// set isNot pivot on this matcher
			this.isNot = true;
		}

		// detect toBeTypeOf dynamic shortcuts
		if( reFindNoCase( "^toBe(array|binary|boolean|component|creditcard|date|time|email|eurodate|float|numeric|guid|integer|query|ssn|social_security_number|string|struct|telephone|url|UUID|usdate|zipcode)$", arguments.missingMethodName ) ){
			// remove the toBe to get the type.
			var type 	= right( arguments.missingMethodName, len( arguments.missingMethodName ) - 4 );
			// detect incoming message
			var message = ( structKeyExists( arguments.missingMethodArguments, "message" ) ? arguments.missingMethodArguments.message : "" );
			message = ( structKeyExists( arguments.missingMethodArguments, "1" ) ? arguments.missingMethodArguments[ 1 ] : message );
			// execute the method
			return toBeTypeOf( type=type, message=message );
		}

		// execute the dynamic method
		var results = invoke( this, arguments.missingMethodName, arguments.missingMethodArguments );
		if( !isNull( results ) ){
			return results;
		}

		// throw exception
		//throw(type="InvalidMethod", message="The dynamic/static method: #arguments.missingMethodName# does not exist in this CFC", detail="Available methods are #structKeyArray( this ).toString()#");
	}

	/**
	* Set the not bit to TRUE for this expectation.
	*/
	function _not(){
		this.isNot = true;
		return this;
	}

	/**
	* Assert something is true
	* @actual The actual data to test
	* @message The message to send in the failure
	*/
	function toBeTrue( message="" ){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.isFalse( argumentCollection=arguments );
		} else {
			variables.assert.isTrue( argumentCollection=arguments );
		}

		return this;
	}

	/**
	* Assert something is false
	* @actual The actual data to test
	* @message The message to send in the failure
	*/
	function toBeFalse( message="" ){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.isTrue( argumentCollection=arguments );
		} else {
			variables.assert.isFalse( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert something is equal to each other, no case is required
	* @expected The expected data
	* @message The message to send in the failure
	*/
	function toBe( any expected, message="" ){
		// Null checks
		if( isNull( this.actual ) ){
			arguments.actual = javaCast( "null", "" );
		} else {
			arguments.actual = this.actual;
		}
		// Inverse Checks
		if( this.isNot ){
			variables.assert.isNotEqual( argumentCollection=arguments );
		} else {
			variables.assert.isEqual( argumentCollection=arguments );
		}
		return this;
	}


	/**
	* Assert strings are equal to each other with case.
	* @expected The expected data
	* @message The message to send in the failure
	*/
	function toBeWithCase( required string expected, message="" ){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.isNotEqual( argumentCollection=arguments );
		} else {
			variables.assert.isEqualWithCase( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert something is null
	* @message The message to send in the failure
	*/
	function toBeNull( message="" ){
		if( this.isNot ){
			if( !isNull( this.actual ) ){ return this; }
			arguments.message = ( len( arguments.message ) ?
				arguments.message : "Expected the actual value to be NOT null but it was null" );
		} else {
			if( isNull( this.actual ) ){ return this; }
			arguments.message = ( len( arguments.message ) ?
				arguments.message : "Expected a null value but got [#variables.assert.getStringName( this.actual )#] instead" );

		}
		variables.assert.fail( arguments.message );
	}


	/**
	* Assert that the actual object is of the expected instance type
	* @typeName The typename to check
	* @message The message to send in the failure
	*/
	function toBeInstanceOf( required string typeName, message=""){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.notInstanceOf( argumentCollection=arguments );
		} else {
			variables.assert.instanceOf( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the actual data matches the incoming regular expression with no case sensitivity
	* @regex The regex to check with
	* @message The message to send in the failure
	*/
	function toMatch( required string regex, message=""){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.notMatch( argumentCollection=arguments );
		} else {
			variables.assert.match( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the actual data matches the incoming regular expression with case sensitivity
	* @actual The actual data to check
	* @regex The regex to check with
	* @message The message to send in the failure
	*/
	function toMatchWithCase( required string regex, message=""){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.notMatchWithCase( argumentCollection=arguments );
		} else {
			variables.assert.matchWithCase( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert the type of the incoming actual data, it uses the internal ColdFusion isValid() function behind the scenes
	* @type The type to check, valid types are: array, binary, boolean, component, date, time, float, numeric, integer, query, string, struct, url, uuid
	* @message The message to send in the failure
	*/
	function toBeTypeOf( required string type, message=""){
		arguments.actual = this.actual;
		if( this.isNot ){
			variables.assert.notTypeOf( argumentCollection=arguments );
		} else {
			variables.assert.typeOf( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that a a given string, array, structure or query is empty
	* @message The message to send in the failure
	*/
	function toBeEmpty( message=""){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.isNotEmpty( argumentCollection=arguments );
		} else {
			variables.assert.isEmpty( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that a given key exists in the passed in struct/object
	* @key The key to check for existence
	* @message The message to send in the failure
	*/
	function toHaveKey( required string key, message=""){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.notKey( argumentCollection=arguments );
		} else {
			variables.assert.key( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that a given key exists in the passed in struct by searching the entire nested structure
	* @key The key to check for existence anywhere in the nested structure
	* @message The message to send in the failure
	*/
	function toHaveDeepKey( required string key, message=""){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.notDeepKey( argumentCollection=arguments );
		} else {
			variables.assert.deepKey( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert the size of a given string, array, structure or query
	* @length The length to check
	* @message The message to send in the failure
	*/
	function toHaveLength( required string length, message=""){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.notLengthOf( argumentCollection=arguments );
		} else {
			variables.assert.lengthOf( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the passed in function will throw an exception
	* @type Match this type with the exception thrown
	* @regex Match this regex against the message of the exception
	* @message The message to send in the failure
	*/
	function toThrow( type="", regex=".*", message="" ){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.notThrows( argumentCollection=arguments );
		} else {
			variables.assert.throws( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the passed in actual number or date is expected to be close to it within +/- a passed delta and optional datepart
	* @expected The expected number or date
	* @delta The +/- delta to range it
	* @datepart If passed in values are dates, then you can use the datepart to evaluate it
	* @message The message to send in the failure
	*/
	function toBeCloseTo( required any expected, required any delta, datePart="", message=""){
		arguments.actual = this.actual;
		if( this.isNot ){
			try{
				variables.assert.closeTo( argumentCollection=arguments );
				arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is actually in range of [#arguments.expected#] by +/- [#arguments.delta#]" );
				variables.assert.fail( arguments.message );
			} catch( Any e ) {
				return this;
			}
		} else {
			variables.assert.closeTo( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the passed in actual number or date is between the passed in min and max values
	* @min The expected min number or date
	* @max The expected max number or date
	* @message The message to send in the failure
	*/
	function toBeBetween( required any min, required any max, message=""){
		arguments.actual = this.actual;
		if( this.isNot ){
			try{
				variables.assert.between( argumentCollection=arguments );
				arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is actually between [#arguments.min#] and [#arguments.max#]" );
				variables.assert.fail( arguments.message );
			} catch( Any e ) {
				return this;
			}
		} else {
			variables.assert.between( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the given "needle" argument exists in the incoming string or array with no case-sensitivity
	* @target The target object to check if the incoming needle exists in. This can be a string or array
	* @needle The substring to find in a string or the value to find in an array
	* @message The message to send in the failure
	*/
	function toInclude( required any needle, message="" ){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.notIncludes( argumentCollection=arguments );
		} else {
			variables.assert.includes( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the given "needle" argument exists in the incoming string or array with case-sensitivity
	* @needle The substring to find in a string or the value to find in an array
	* @message The message to send in the failure
	*/
	function toIncludeWithCase( required any needle, message="" ){
		arguments.target = this.actual;
		if( this.isNot ){
			variables.assert.notIncludesWithCase( argumentCollection=arguments );
		} else {
			variables.assert.includesWithCase( argumentCollection=arguments );
		}
		return this;
	}

	/**
	* Assert that the actual value is greater than the target value
	* @target The target value
	* @message The message to send in the failure
	*/
	function toBeGT( required any target, message="" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not greater than [#arguments.target#]" );
		if( this.isNot ){
			variables.assert.isLTE( this.actual, arguments.target, arguments.message );
		} else {
			variables.assert.isGT( this.actual, arguments.target, arguments.message );
		}
		return this;
	}

	/**
	* Assert that the actual value is greater than or equal the target value
	* @target The target value
	* @message The message to send in the failure
	*/
	function toBeGTE( required any target, message="" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not greater than or equal to [#arguments.target#]" );
		if( this.isNot ){
			variables.assert.isLT( this.actual, arguments.target, arguments.message );
		} else {
			variables.assert.isGTE( this.actual, arguments.target, arguments.message );
		}
		return this;
	}

	/**
	* Assert that the actual value is less than the target value
	* @target The target value
	* @message The message to send in the failure
	*/
	function toBeLT( required any target, message="" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not less than [#arguments.target#]" );
		if( this.isNot ){
			variables.assert.isGTE( this.actual, arguments.target, arguments.message );
		} else {
			variables.assert.isLT( this.actual, arguments.target, arguments.message );
		}
		return this;
	}

	/**
	* Assert that the actual value is less than or equal the target value
	* @target The target value
	* @message The message to send in the failure
	*/
	function toBeLTE( required any target, message="" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not less than or equal to [#arguments.target#]" );
		if( this.isNot ){
			variables.assert.isGT( this.actual, arguments.target, arguments.message );
		} else {
			variables.assert.isLTE( this.actual, arguments.target, arguments.message );
		}
		return this;
	}

	/**
	* Assert that the actual value is JSON
	* @message The message to send in the failure
	*/
	function toBeJSON( message="" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not valid JSON" );
		if( this.isNot ){
			if( isJSON( this.actual ) ){
				fail( arguments.message );
			}
		} else {
			variables.assert.isJSON( this.actual, arguments.message );
		}
		return this;
	}

	/**
	* Assert that the actual value passes a given truth test (function/closure)
	* @target The target truth test function/closure
	* @message The message to send in the failure
	*/
	function toSatisfy( required any target, message="" ){
		arguments.message = ( len( arguments.message ) ? arguments.message : "The actual [#this.actual#] does not pass the truth test" );

		var isPassed = arguments.target( this.actual );
		if( this.isNot ){
			isPassed = !isPassed;
		}
		if( !isPassed ){
			fail( arguments.message );
		}

		return this;
	}

}
