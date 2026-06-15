/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * The Expectation class holds a current expectation with all the required matcher methods to provide you
 * with awesome BDD expressions and testing.
 */
component accessors="true" {

	// The reference to the spec this matcher belongs to.
	property name="spec";
	// The assertions reference
	property name="assert";

	// Public properties for this Expectation to use with the BDD DSL
	// The actual value
	this.actual  = "";
	// The negation bit
	this.isNot   = false;
	// Custom messages
	this.message = "";
	// Additional context added to failure messages, useful for distinguishing expectations
	this.context = "";

	/**
	 * Constructor
	 *
	 * @spec       The spec that this matcher belongs to.
	 * @assertions The TestBox assertions object: testbox.system.Assertion
	 */
	function init( required any spec, required any assertions ){
		variables.spec   = arguments.spec;
		variables.assert = arguments.assertions;

		return this;
	}

	/**
	 * Registers a custom matcher on this Expectation object
	 *
	 * @name The name of the custom matcher
	 * @body The body closure/udf representing this matcher.
	 */
	function registerMatcher( required name, required body ){
		// store new custom matcher function according to specs
		this[ arguments.name ] = variables[ arguments.name ] = function(){
			// execute custom matcher
			var results = body( this, arguments );
			// if not passed, then fail the custom matcher, else you can concatenate
			return ( !results ? fail( this.message ) : this );
		};
	}

	/**
	 * Fail an assertion
	 *
	 * @message The message to fail with.
	 * @detail  The detail to fail with.
	 */
	function fail( message = "", detail = "" ){
		arguments.message = resolveMessage( arguments.message );
		variables.assert.fail( argumentCollection = arguments );
	}

	/**
	 * Process dynamic expectations like any matcher starting with the word "not" is negated
	 */
	function onMissingMethod( required missingMethodName, required missingMethodArguments ){
		// detect negation
		if ( left( arguments.missingMethodName, 3 ) eq "not" ) {
			// remove NOT
			arguments.missingMethodName = right(
				arguments.missingMethodName,
				len( arguments.missingMethodName ) - 3
			);
			// Inject context into the missingMethodArguments so the routed matcher picks it up,
			// but only if the caller did not supply an explicit message
			if ( len( this.context ) && !structKeyExists( arguments.missingMethodArguments, "message" ) ) {
				arguments.missingMethodArguments.message = this.context;
			}
			// set isNot pivot on this matcher
			try {
				this.isNot = true;

				// execute the dynamic method
				var results = invoke(
					this,
					arguments.missingMethodName,
					arguments.missingMethodArguments
				);
				if ( !isNull( results ) ) {
					return results;
				} else {
					return;
				}
			} finally {
				this.isNot = false;
			}
		}

		// detect toBeTypeOf dynamic shortcuts
		if (
			reFindNoCase(
				"^toBe(array|binary|boolean|class|component|creditcard|date|email|eurodate|float|function|guid|hex|integer|numeric|query|social_security_number|ssn|string|struct|telephone|time|url|usdate|UUID|xml|zipcode)$",
				arguments.missingMethodName
			)
		) {
			// remove the toBe to get the type.
			var type    = right( arguments.missingMethodName, len( arguments.missingMethodName ) - 4 );
			// detect incoming message
			var message = (
				structKeyExists( arguments.missingMethodArguments, "message" ) ? arguments.missingMethodArguments.message : ""
			);
			message = (
				structKeyExists( arguments.missingMethodArguments, "1" ) ? arguments.missingMethodArguments[ 1 ] : message
			);
			// execute the method
			return toBeTypeOf( type = type, message = message );
		}

		// throw exception
		throw(
			type    = "InvalidMethod",
			message = "The dynamic/static method: #arguments.missingMethodName# does not exist in this class",
			detail  = "Available methods are #structKeyArray( this ).toString()#"
		);
	}

	/**
	 * Set the not bit to TRUE for this expectation.
	 */
	function _not(){
		this.isNot = true;
		return this;
	}

	/**
	 * Add semantic context to this expectation so that failure messages
	 * include additional identifying information.
	 *
	 * @message The context message to include when this expectation fails
	 */
	function withContext( required string message ){
		this.context = arguments.message;
		return this;
	}

	/************************************** PRIVATE *********************************************/

	/**
	 * Resolve a failure message by prepending the context if it has been set.
	 */
	private string function resolveMessage( required string message ){
		if ( len( arguments.message ) && len( this.context ) ) {
			return this.context & " — " & arguments.message;
		}
		return arguments.message;
	}

	/************************************** MATCHERS *********************************************/

	/**
	 * Assert something is true
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function toBeTrue( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.isFalse( argumentCollection = arguments );
		} else {
			variables.assert.isTrue( argumentCollection = arguments );
		}

		return this;
	}

	/**
	 * Assert something is false
	 *
	 * @actual  The actual data to test
	 * @message The message to send in the failure
	 */
	function toBeFalse( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.isTrue( argumentCollection = arguments );
		} else {
			variables.assert.isFalse( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert something is equal to each other, no case is required
	 *
	 * @expected The expected data
	 * @message  The message to send in the failure
	 */
	function toBe( any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		// Null checks
		if ( isNull( this.actual ) ) {
			arguments.actual = javacast( "null", "" );
		} else {
			arguments.actual = this.actual;
		}
		// Inverse Checks
		if ( this.isNot ) {
			variables.assert.isNotEqual( argumentCollection = arguments );
		} else {
			variables.assert.isEqual( argumentCollection = arguments );
		}
		return this;
	}


	/**
	 * Assert strings are equal to each other with case.
	 *
	 * @expected The expected data
	 * @message  The message to send in the failure
	 */
	function toBeWithCase( required string expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.isNotEqual( argumentCollection = arguments );
		} else {
			variables.assert.isEqualWithCase( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert something is null
	 *
	 * @message The message to send in the failure
	 */
	function toBeNull( message = "" ){
		if ( this.isNot ) {
			if ( !isNull( this.actual ) ) {
				return this;
			}
			fail(
				len( arguments.message ) ? arguments.message : "Expected the actual value to be NOT null but it was null"
			);
		} else {
			if ( isNull( this.actual ) ) {
				return this;
			}
			fail(
				len( arguments.message ) ? arguments.message : "Expected a null value but got [#variables.assert.getStringName( this.actual )#] instead"
			);
		}
	}


	/**
	 * Assert that the actual object is of the expected instance type
	 *
	 * @typeName The typename to check
	 * @message  The message to send in the failure
	 */
	function toBeInstanceOf( required string typeName, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.notInstanceOf( argumentCollection = arguments );
		} else {
			variables.assert.instanceOf( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the actual data matches the incoming regular expression with no case sensitivity
	 *
	 * @regex   The regex to check with
	 * @message The message to send in the failure
	 */
	function toMatch( required string regex, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.notMatch( argumentCollection = arguments );
		} else {
			variables.assert.match( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Asserts that the actual value starts with the expected value with no case sensitivity
	 * expect( "Hello World" ).toStartWith( "hello" );
	 *
	 * @needle  The needle to test
	 * @message The message to send in the failure
	 */
	function toStartWith( required needle, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notStartsWith( argumentCollection = arguments );
		} else {
			variables.assert.startsWith( argumentCollection = arguments );
		}

		return this;
	}

	/**
	 * Asserts that the actual value starts with the expected value with case sensitivity.
	 * expect( "Hello World" ).toStartWithCase( "hello" );
	 *
	 * @needle  The needle to test
	 * @message The message to send in the failure
	 */
	function toStartWithCase( required needle, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notStartsWithCase( argumentCollection = arguments );
		} else {
			variables.assert.startsWithCase( argumentCollection = arguments );
		}

		return this;
	}

	/**
	 * Asserts that the actual value ends with the expected value with no case sensitivity
	 * expect( "Hello World" ).toEndWith( "ld" );
	 *
	 * @needle  The needle to test
	 * @message The message to send in the failure
	 */
	function toEndWith( required needle, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notEndsWith( argumentCollection = arguments );
		} else {
			variables.assert.endsWith( argumentCollection = arguments );
		}

		return this;
	}

	/**
	 * Asserts that the actual value ends with the expected value with case sensitivity.
	 * expect( "Hello World" ).toEndWithCase( "World" );
	 *
	 * @needle  The needle to test
	 * @message The message to send in the failure
	 */
	function toEndWithCase( required needle, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notEndsWithCase( argumentCollection = arguments );
		} else {
			variables.assert.endsWithCase( argumentCollection = arguments );
		}

		return this;
	}

	/**
	 * Assert that the actual data matches the incoming regular expression with case sensitivity
	 *
	 * @actual  The actual data to check
	 * @regex   The regex to check with
	 * @message The message to send in the failure
	 */
	function toMatchWithCase( required string regex, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.notMatchWithCase( argumentCollection = arguments );
		} else {
			variables.assert.matchWithCase( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert the type of the incoming actual data, it uses the internal ColdFusion isValid() function behind the scenes
	 *
	 * @type    The type to check, valid types are: array, binary, boolean, component, date, time, float, numeric, integer, query, string, struct, url, uuid
	 * @message The message to send in the failure
	 */
	function toBeTypeOf( required string type, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.actual  = this.actual;
		if ( this.isNot ) {
			variables.assert.notTypeOf( argumentCollection = arguments );
		} else {
			variables.assert.typeOf( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that a a given string, array, structure or query is empty
	 *
	 * @message The message to send in the failure
	 */
	function toBeEmpty( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.isNotEmpty( argumentCollection = arguments );
		} else {
			variables.assert.isEmpty( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that a given key exists in the passed in struct/object
	 *
	 * @key     A key or a list of keys to check that the structure MUST contain
	 * @message The message to send in the failure
	 */
	function toHaveKey( required string key, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notKey( argumentCollection = arguments );
		} else {
			variables.assert.key( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that a given key exists in the passed in struct/object with case sensitivity
	 *
	 * @key     A key or a list of keys to check that the structure MUST contain
	 * @message The message to send in the failure
	 */
	function toHaveKeyWithCase( required string key, message = "" ){
		arguments.message       = resolveMessage( arguments.message );
		arguments.caseSensitive = true;
		arguments.target        = this.actual;
		if ( this.isNot ) {
			variables.assert.notKey( argumentCollection = arguments );
		} else {
			variables.assert.key( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that a given key exists in the passed in struct by searching the entire nested structure
	 *
	 * @key     The key to check for existence anywhere in the nested structure
	 * @message The message to send in the failure
	 */
	function toHaveDeepKey( required string key, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notDeepKey( argumentCollection = arguments );
		} else {
			variables.assert.deepKey( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert the size of a given string, array, structure or query
	 *
	 * @length  The length to check
	 * @message The message to send in the failure
	 */
	function toHaveLength( required numeric length, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notLengthOf( argumentCollection = arguments );
		} else {
			variables.assert.lengthOf( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the passed in function will throw an exception
	 *
	 * @type    Match this type with the exception thrown
	 * @regex   Match this regex against the message of the exception
	 * @message The message to send in the failure
	 */
	function toThrow( type = "", regex = ".*", message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		variables.assert.throws( argumentCollection = arguments );
		return this;
	}

	/**
	 * Assert that the passed in function will NOT throw an exception
	 *
	 * @type    Match this type with the exception thrown
	 * @regex   Match this regex against the message of the exception
	 * @message The message to send in the failure
	 */
	function notToThrow( type = "", regex = "", message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		variables.assert.notThrows( argumentCollection = arguments );
		return this;
	}


	/**
	 * Assert that the passed in actual number or date is expected to be close to it within +/- a passed delta and optional datepart
	 *
	 * @expected The expected number or date
	 * @delta    The +/- delta to range it
	 * @datepart If passed in values are dates, then you can use the datepart to evaluate it
	 * @message  The message to send in the failure
	 */
	function toBeCloseTo(
		required any expected,
		required any delta,
		datePart = "",
		message  = ""
	){
		arguments.actual  = this.actual;
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.closeTo( argumentCollection = arguments );
				fail(
					len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is actually in range of [#arguments.expected#] by +/- [#arguments.delta#]"
				);
			} catch ( Any e ) {
				return this;
			}
		} else {
			variables.assert.closeTo( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the passed in actual number or date is between the passed in min and max values
	 *
	 * @min     The expected min number or date
	 * @max     The expected max number or date
	 * @message The message to send in the failure
	 */
	function toBeBetween(
		required any min,
		required any max,
		message = ""
	){
		arguments.actual  = this.actual;
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			var pass = false;
			try {
				variables.assert.between( argumentCollection = arguments );
			} catch ( Any e ) {
				pass = true;
			}
			if ( !pass ) {
				fail(
					len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is actually between [#arguments.min#] and [#arguments.max#]"
				);
			}
			return this;
		} else {
			variables.assert.between( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with no case-sensitivity
	 *
	 * @target  The target object to check if the incoming needle exists in. This can be a string or array
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function toContain( required any needle, message = "" ){
		return toInclude( argumentCollection = arguments );
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with case-sensitivity
	 *
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function toContainWithCase( required any needle, message = "" ){
		return toIncludeWithCase( argumentCollection = arguments );
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with no case-sensitivity
	 *
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function toInclude( required any needle, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notIncludes( argumentCollection = arguments );
		} else {
			variables.assert.includes( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the actual value exists in the coming string or array list target with no case-sensitivity
	 *
	 * @target  The list or string or array to include the actual value
	 * @message The message to send in the failure
	 */
	function toBeIn( required any target, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.needle  = this.actual;
		if ( this.isNot ) {
			variables.assert.notIncludes( argumentCollection = arguments );
		} else {
			variables.assert.includes( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the actual value exists in the coming string or array list target with case-sensitivity
	 *
	 * @target  The list or string or array to include the actual value
	 * @message The message to send in the failure
	 */
	function toBeInWithCase( required any target, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.needle  = this.actual;
		if ( this.isNot ) {
			variables.assert.notIncludesWithCase( argumentCollection = arguments );
		} else {
			variables.assert.includesWithCase( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the given "needle" argument exists in the incoming string or array with case-sensitivity
	 *
	 * @needle  The substring to find in a string or the value to find in an array
	 * @message The message to send in the failure
	 */
	function toIncludeWithCase( required any needle, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		arguments.target  = this.actual;
		if ( this.isNot ) {
			variables.assert.notIncludesWithCase( argumentCollection = arguments );
		} else {
			variables.assert.includesWithCase( argumentCollection = arguments );
		}
		return this;
	}

	/**
	 * Assert that the actual value is greater than the target value
	 *
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function toBeGT( required any target, message = "" ){
		arguments.message = resolveMessage(
			len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not greater than [#arguments.target#]"
		);
		if ( this.isNot ) {
			variables.assert.isLTE(
				this.actual,
				arguments.target,
				arguments.message
			);
		} else {
			variables.assert.isGT(
				this.actual,
				arguments.target,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual value is greater than or equal the target value
	 *
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function toBeGTE( required any target, message = "" ){
		arguments.message = resolveMessage(
			len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not greater than or equal to [#arguments.target#]"
		);
		if ( this.isNot ) {
			variables.assert.isLT(
				this.actual,
				arguments.target,
				arguments.message
			);
		} else {
			variables.assert.isGTE(
				this.actual,
				arguments.target,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual value is less than the target value
	 *
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function toBeLT( required any target, message = "" ){
		arguments.message = resolveMessage(
			len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not less than [#arguments.target#]"
		);
		if ( this.isNot ) {
			variables.assert.isGTE(
				this.actual,
				arguments.target,
				arguments.message
			);
		} else {
			variables.assert.isLT(
				this.actual,
				arguments.target,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual value is less than or equal the target value
	 *
	 * @target  The target value
	 * @message The message to send in the failure
	 */
	function toBeLTE( required any target, message = "" ){
		arguments.message = resolveMessage(
			len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not less than or equal to [#arguments.target#]"
		);
		if ( this.isNot ) {
			variables.assert.isGT(
				this.actual,
				arguments.target,
				arguments.message
			);
		} else {
			variables.assert.isLTE(
				this.actual,
				arguments.target,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual value is JSON
	 *
	 * @message The message to send in the failure
	 */
	function toBeJSON( message = "" ){
		arguments.message = resolveMessage(
			len( arguments.message ) ? arguments.message : "The actual [#this.actual#] is not valid JSON"
		);
		if ( this.isNot ) {
			if ( isJSON( this.actual ) ) {
				fail( arguments.message );
			}
		} else {
			variables.assert.isJSON( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the actual value passes a given truth test (function/closure/lambda)
	 *
	 * @target  The target truth test function/closure
	 * @message The message to send in the failure
	 */
	function toSatisfy( required any target, message = "" ){
		var actualMessage = isSimpleValue( this.actual ) ? this.actual : "The actual (complex) value";

		arguments.message = (
			len( arguments.message ) ? arguments.message : "The actual [#actualMessage#] does not pass the truth test"
		);

		var isPassed = arguments.target( this.actual );
		if ( this.isNot ) {
			isPassed = !isPassed;
		}
		if ( !isPassed ) {
			fail( arguments.message );
		}

		return this;
	}

	/**
	 * Assert that the actual value is truthy (not false, 0, empty string, or null).
	 *
	 * @message The message to send in the failure
	 */
	function toBeTruthy( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.isFalsy( this.actual, arguments.message );
		} else {
			variables.assert.isTruthy( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the actual value is falsy (false, 0, empty string, or null).
	 *
	 * @message The message to send in the failure
	 */
	function toBeFalsy( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.isTruthy( this.actual, arguments.message );
		} else {
			variables.assert.isFalsy( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the actual object is the same instance as the expected object.
	 *
	 * @expected The expected object to compare identity with
	 * @message  The message to send in the failure
	 */
	function toBeSameInstanceAs( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.isNotSameInstance(
				arguments.expected,
				this.actual,
				arguments.message
			);
		} else {
			variables.assert.isSameInstance(
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert the size of a given string, array, structure or query. Alias for toHaveLength().
	 *
	 * @length  The length to check
	 * @message The message to send in the failure
	 */
	function toHaveSize( required numeric length, message = "" ){
		return toHaveLength( argumentCollection = arguments );
	}

	/**
	 * Assert that the actual function throws an exception matching the given predicate.
	 *
	 * @predicate A function/closure that receives the exception and returns true if it matches
	 * @message   The message to send in the failure
	 */
	function toThrowMatching( required any predicate, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		try {
			var fn = this.actual;
			fn();
			arguments.message = (
				len( arguments.message ) ? arguments.message : "The function did not throw an exception but one was expected"
			);
			fail( arguments.message );
		} catch ( any e ) {
			var matches = arguments.predicate( e );
			if ( this.isNot ) {
				matches = !matches;
			}
			if ( !matches ) {
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The thrown exception did not match the predicate"
				);
				fail( arguments.message );
			}
		}
		return this;
	}

	/**
	 * Assert that the actual value contains all of the given needles with no case-sensitivity.
	 *
	 * @needles An array of needles that MUST be found
	 * @message The message to send in the failure
	 */
	function toIncludeAll( required array needles, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.includesAll(
					this.actual,
					arguments.needles,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The target contained all needles but was expected not to"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.includesAll(
				this.actual,
				arguments.needles,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual value contains at least one of the given needles with no case-sensitivity.
	 *
	 * @needles An array of needles, at least one MUST be found
	 * @message The message to send in the failure
	 */
	function toIncludeAny( required array needles, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.includesAny(
					this.actual,
					arguments.needles,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The target contained at least one needle but was expected not to"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.includesAny(
				this.actual,
				arguments.needles,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual value contains none of the given needles with no case-sensitivity.
	 *
	 * @needles An array of needles that MUST NOT be found
	 * @message The message to send in the failure
	 */
	function toIncludeNone( required array needles, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.includesNone(
					this.actual,
					arguments.needles,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The target contained none of the needles but was expected to contain at least one"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.includesNone(
				this.actual,
				arguments.needles,
				arguments.message
			);
		}
		return this;
	}

	/*********************************** BoxLang Set Expectations ***********************************/

	/**
	 * Assert that the actual value is a BoxLang Set type.
	 *
	 * @message The message to send in the failure
	 */
	function toBeASet( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isASet( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected the actual value to NOT be a Set but it was"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isASet( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that two sets are equal (contain the same elements, order-independent).
	 *
	 * @expected The expected set
	 * @message  The message to send in the failure
	 */
	function toEqualSet( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isEqualSet(
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( arguments.expected )#] but received [#getStringName( this.actual )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isEqualSet(
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual set is a subset of the expected set.
	 *
	 * @expected The expected (parent) set
	 * @message  The message to send in the failure
	 */
	function toBeSubsetOf( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isSubsetOf(
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "[#getStringName( this.actual )#] is actually a subset of [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isSubsetOf(
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual set is a superset of the expected set.
	 *
	 * @expected The expected (subset) set
	 * @message  The message to send in the failure
	 */
	function toBeSupersetOf( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isSupersetOf(
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "[#getStringName( this.actual )#] is actually a superset of [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isSupersetOf(
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the actual set is disjoint from the expected set (no common elements).
	 *
	 * @expected The expected set to check disjointness against
	 * @message  The message to send in the failure
	 */
	function toBeDisjointFrom( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isDisjointFrom(
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "[#getStringName( this.actual )#] is actually not disjoint from [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isDisjointFrom(
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the union of two sets equals the expected set.
	 *
	 * @other    The other set to union with actual
	 * @expected The expected result of the union
	 * @message  The message to send in the failure
	 */
	function toHaveUnion(
		required any other,
		required any expected,
		message = ""
	){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.hasUnion(
					arguments.other,
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The union of [#getStringName( this.actual )#] and [#getStringName( arguments.other )#] is actually [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.hasUnion(
				arguments.other,
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the intersection of two sets equals the expected set.
	 *
	 * @other    The other set to intersect with actual
	 * @expected The expected result of the intersection
	 * @message  The message to send in the failure
	 */
	function toHaveIntersection(
		required any other,
		required any expected,
		message = ""
	){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.hasIntersection(
					arguments.other,
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The intersection of [#getStringName( this.actual )#] and [#getStringName( arguments.other )#] is actually [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.hasIntersection(
				arguments.other,
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the difference of two sets equals the expected set.
	 *
	 * @other    The other set to subtract from actual
	 * @expected The expected result of the difference
	 * @message  The message to send in the failure
	 */
	function toHaveDifference(
		required any other,
		required any expected,
		message = ""
	){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.hasDifference(
					arguments.other,
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The difference of [#getStringName( this.actual )#] and [#getStringName( arguments.other )#] is actually [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.hasDifference(
				arguments.other,
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the symmetric difference of two sets equals the expected set.
	 *
	 * @other    The other set to compute symmetric difference with actual
	 * @expected The expected result of the symmetric difference
	 * @message  The message to send in the failure
	 */
	function toHaveSymmetricDifference(
		required any other,
		required any expected,
		message = ""
	){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.hasSymmetricDifference(
					arguments.other,
					arguments.expected,
					this.actual,
					arguments.message
				);
				arguments.message = (
					len( arguments.message ) ? arguments.message : "The symmetric difference of [#getStringName( this.actual )#] and [#getStringName( arguments.other )#] is actually [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.hasSymmetricDifference(
				arguments.other,
				arguments.expected,
				this.actual,
				arguments.message
			);
		}
		return this;
	}

	/*********************************** BoxLang Range Expectations ***********************************/

	/**
	 * Assert that the actual value is a BoxLang Range type.
	 *
	 * @message The message to send in the failure
	 */
	function toBeRange( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRange( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected the actual value to NOT be a Range but it was"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRange( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range contains a specific value.
	 *
	 * @value   The expected value within the range
	 * @message The message to send in the failure
	 */
	function toContainValue( required any value, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.rangeContainsValue( this.actual, arguments.value, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT contain [#getStringName( arguments.value )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.rangeContainsValue( this.actual, arguments.value, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range contains another range.
	 *
	 * @expected The expected (child) range contained within actual
	 * @message  The message to send in the failure
	 */
	function toContainRange( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.rangeContainsRange( this.actual, arguments.expected, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT contain [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.rangeContainsRange( this.actual, arguments.expected, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that a value is within the range.
	 *
	 * @range   The range to check against
	 * @message The message to send in the failure
	 */
	function toBeInRange( required any range, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.valueInRange( this.actual, arguments.range, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be in range [#getStringName( arguments.range )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.valueInRange( this.actual, arguments.range, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is entirely before another range.
	 *
	 * @expected The expected (second) range that should come after actual
	 * @message  The message to send in the failure
	 */
	function toBeBeforeRange( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.rangeBeforeRange( this.actual, arguments.expected, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be before [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.rangeBeforeRange( this.actual, arguments.expected, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is entirely after another range.
	 *
	 * @expected The expected (first) range that should come before actual
	 * @message  The message to send in the failure
	 */
	function toBeAfterRange( required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.rangeAfterRange( this.actual, arguments.expected, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be after [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.rangeAfterRange( this.actual, arguments.expected, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is bounded (has both start and end).
	 *
	 * @message The message to send in the failure
	 */
	function toBeBounded( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeBounded( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be bounded"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeBounded( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is unbounded (has no endpoints).
	 *
	 * @message The message to send in the failure
	 */
	function toBeUnbounded( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeUnbounded( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be unbounded"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeUnbounded( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is half-bounded (has exactly one endpoint).
	 *
	 * @message The message to send in the failure
	 */
	function toBeHalfBounded( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeHalfBounded( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be half-bounded"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeHalfBounded( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is iterable (can be used in for/in loops).
	 *
	 * @message The message to send in the failure
	 */
	function toBeIterable( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeIterable( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be iterable"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeIterable( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is ascending (start < end).
	 *
	 * @message The message to send in the failure
	 */
	function toBeAscending( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeAscending( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#variables.assert.getStringName( this.actual )#] to NOT be ascending"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeAscending( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is descending (start > end).
	 *
	 * @message The message to send in the failure
	 */
	function toBeDescending( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeDescending( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be descending"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeDescending( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range is empty.
	 *
	 * @message The message to send in the failure
	 */
	function toBeEmpty( message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.isRangeEmpty( this.actual, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT be empty"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.isRangeEmpty( this.actual, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that the range has a specific step value.
	 *
	 * @step    The expected step value
	 * @message The message to send in the failure
	 */
	function toHaveStep( required any step, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.rangeHasStep( this.actual, arguments.step, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected [#getStringName( this.actual )#] to NOT have step [#getStringName( arguments.step )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.rangeHasStep( this.actual, arguments.step, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that clamping a value to the range produces the expected result.
	 *
	 * @value    The value to clamp
	 * @expected The expected result after clamping
	 * @message  The message to send in the failure
	 */
	function toClampTo( required any value, required any expected, message = "" ){
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			try {
				variables.assert.rangeClampTo( this.actual, arguments.value, arguments.expected, arguments.message );
				arguments.message = (
					len( arguments.message ) ? arguments.message : "Expected clamp([#getStringName( arguments.value )#], [#getStringName( this.actual )#]) to NOT be [#getStringName( arguments.expected )#]"
				);
				fail( arguments.message );
			} catch ( "TestBox.AssertionFailed" e ) {
				return this;
			}
		} else {
			variables.assert.rangeClampTo( this.actual, arguments.value, arguments.expected, arguments.message );
		}
		return this;
	}

	/**
	 * Assert that a path exists in the actual data structure.
	 * BoxLang Data Navigator feature - requires BoxLang runtime.
	 *
	 * @path    The path string (e.g., "a.b.c", "users[0].name")
	 * @message The message to send in the failure
	 */
	function toHavePath( required string path, message = "" ){
		this._checkBoxLangFeature();
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.notToPath(
				this.actual,
				arguments.path,
				arguments.message
			);
		} else {
			variables.assert.toPath(
				this.actual,
				arguments.path,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the value at a path equals the expected value.
	 * BoxLang Data Navigator feature - requires BoxLang runtime.
	 *
	 * @path     The path string (e.g., "a.b.c", "users[0].name")
	 * @expected The expected value at the path
	 * @message  The message to send in the failure
	 */
	function toHavePathValue( required string path, required any expected, message = "" ){
		this._checkBoxLangFeature();
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.notToPathValue(
				this.actual,
				arguments.path,
				arguments.expected,
				arguments.message
			);
		} else {
			variables.assert.toPathValue(
				this.actual,
				arguments.path,
				arguments.expected,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the value at a path is of the expected type.
	 * BoxLang Data Navigator feature - requires BoxLang runtime.
	 *
	 * @path   The path string (e.g., "a.b.c", "users[0].name")
	 * @type   The expected type string (e.g., "string", "numeric", "array")
	 * @message The message to send in the failure
	 */
	function toHavePathType( required string path, required string type, message = "" ){
		this._checkBoxLangFeature();
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.notToPathType(
				this.actual,
				arguments.path,
				arguments.type,
				arguments.message
			);
		} else {
			variables.assert.toPathType(
				this.actual,
				arguments.path,
				arguments.type,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Assert that the value at a path satisfies a predicate closure.
	 * BoxLang Data Navigator feature - requires BoxLang runtime.
	 *
	 * @path      The path string (e.g., "a.b.c", "users[0].name")
	 * @predicate A closure that takes the path value and returns true/false
	 * @message   The message to send in the failure
	 */
	function toHavePathSatisfying( required string path, required function predicate, message = "" ){
		this._checkBoxLangFeature();
		arguments.message = resolveMessage( arguments.message );
		if ( this.isNot ) {
			variables.assert.notToPathSatisfying(
				this.actual,
				arguments.path,
				arguments.predicate,
				arguments.message
			);
		} else {
			variables.assert.toPathSatisfying(
				this.actual,
				arguments.path,
				arguments.predicate,
				arguments.message
			);
		}
		return this;
	}

	/**
	 * Navigate to a path and return an Expectation on the value at that path.
	 * BoxLang Data Navigator feature - requires BoxLang runtime.
	 *
	 * @path    The path string (e.g., "a.b.c", "users[0].name")
	 * @return    A new Expectation object with the value at the path as actual
	 */
	function path( required string path ){
		this._checkBoxLangFeature();
		var value = variables.assert.resolvePath( this.actual, arguments.path );
		if ( arrayLen( value ) GT 0 ) {
			return variables.spec.expect( value[ 1 ] );
		}
		return variables.spec.expect( null );
	}

	/**
	 * Navigate to a path and return an Expectation over all matching values.
	 * BoxLang Data Navigator feature - requires BoxLang runtime.
	 *
	 * @path    The path string (e.g., "a[*].b", "?@age>18")
	 * @return    A new Expectation object with an array of values at the path as actual
	 */
	function queryPath( required string path ){
		this._checkBoxLangFeature();
		var values = variables.assert.resolvePath( this.actual, arguments.path );
		return variables.spec.expect( values );
	}

	/**
	 * Runtime guard for BoxLang-only data navigator features.
	 */
	function _checkBoxLangFeature(){
		if ( !server.keyExists( "boxlang" ) ) {
			throw(
				type    = "TestBox.BoxLangFeatureNotAvailable",
				message = "This feature requires BoxLang runtime. Data navigators are only available in BoxLang."
			);
		}
	}

}
