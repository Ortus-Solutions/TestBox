/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * The CollectionExpectation holds a collection and behaves like an expectation
 * that automatically unrolls the collection to verify elements according to a mode.
 *
 * Modes:
 * - "all"  : every element must pass the chained matcher (default)
 * - "any"  : at least one element must pass
 * - "some" : a bounded number of elements must pass
 * - "none" : zero elements may pass
 */
component accessors="true" {

	// The (actual) collection
	property name="actual";
	// The reference to the spec that created this
	property name="spec";
	// The assertions reference
	property name="assert";
	// The collection evaluation mode: all, any, some, none
	property name="mode" default="all";
	// The minimum number of passing elements (only used for "some" mode)
	property name="min"  default="1";
	// The maximum number of passing elements, 0 means no upper bound (only used for "some" mode)
	property name="max"  default="0";

	/**
	 * Constructor
	 *
	 * @spec       The target spec
	 * @assertions The assertions library
	 * @collection The collection target
	 * @mode       The evaluation mode: all, any, some, none
	 * @min        The minimum pass count for "some" mode
	 * @max        The maximum pass count for "some" mode, 0 means unbounded
	 */
	function init(
		required spec,
		required any assertions,
		required collection,
		mode        = "all",
		numeric min = 1,
		numeric max = 0
	){
		variables.actual = arguments.collection;
		variables.spec   = arguments.spec;
		variables.assert = arguments.assertions;
		variables.mode   = arguments.mode;
		variables.min    = arguments.min;
		variables.max    = arguments.max;

		return this;
	}

	function onMissingMethod( string missingMethodName, any missingMethodArguments ){
		var isArr = isArray( variables.actual );
		var isStr = isStruct( variables.actual );

		if ( !isArr && !isStr ) {
			variables.assert.fail(
				"expect#variables.mode#() actual is neither an array nor a struct, received: [#variables.assert.getStringName( variables.actual )#]"
			);
		}

		var total     = isArr ? arrayLen( variables.actual ) : structCount( variables.actual );
		var passCount = 0;
		var failures  = [];

		if ( isArr ) {
			for ( var i = 1; i <= arrayLen( variables.actual ); i++ ) {
				if ( !arrayIsDefined( variables.actual, i ) ) {
					continue;
				}
				var result = tryElement(
					i,
					variables.actual[ i ],
					missingMethodName,
					missingMethodArguments
				);
				if ( result.pass ) {
					passCount++;
				} else {
					arrayAppend( failures, result );
				}
			}
		} else {
			for ( var k in variables.actual ) {
				var result = tryElement(
					k,
					variables.actual[ k ],
					missingMethodName,
					missingMethodArguments
				);
				if ( result.pass ) {
					passCount++;
				} else {
					arrayAppend( failures, result );
				}
			}
		}

		evaluateResults( total, passCount, failures, missingMethodName );

		return this;
	}

	/************************************** PRIVATE *********************************************/

	private struct function tryElement(
		required index,
		required element,
		required missingMethodName,
		required missingMethodArguments
	){
		try {
			invoke(
				variables.spec.expect( arguments.element ),
				arguments.missingMethodName,
				arguments.missingMethodArguments
			);
			return { "pass" : true };
		} catch ( "TestBox.AssertionFailed" e ) {
			return {
				"pass"    : false,
				"index"   : arguments.index,
				"value"   : arguments.element,
				"message" : e.message
			};
		}
	}

	private function evaluateResults(
		required numeric total,
		required numeric passCount,
		required array failDetails,
		required string methodName
	){
		switch ( variables.mode ) {
			case "all": {
				if ( arrayLen( arguments.failDetails ) == 0 ) {
					return;
				}
				var detail = buildFailureSummary(
					arguments.total,
					arguments.passCount,
					arguments.failDetails
				);
				variables.assert.fail(
					message = "expectAll() failed: #arguments.failDetails.len()# of #arguments.total# element(s) did not pass the [#arguments.methodName#] expectation",
					detail  = detail
				);
				break;
			}
			case "any": {
				if ( arguments.passCount >= 1 ) {
					return;
				}
				var detail = buildFailureSummary(
					arguments.total,
					arguments.passCount,
					arguments.failDetails
				);
				variables.assert.fail(
					message = "expectAny() failed: expected at least 1 of #arguments.total# element(s) to pass the [#arguments.methodName#] expectation, but 0 passed",
					detail  = detail
				);
				break;
			}
			case "some": {
				var below = arguments.passCount < variables.min;
				var above = variables.max > 0 && arguments.passCount > variables.max;
				if ( !below && !above ) {
					return;
				}
				var expectedRange = variables.max > 0 ? "between #variables.min# and #variables.max#" : "at least #variables.min#";
				var detail        = buildFailureSummary(
					arguments.total,
					arguments.passCount,
					arguments.failDetails
				);
				variables.assert.fail(
					message = "expectSome() failed: expected #expectedRange# of #arguments.total# element(s) to pass the [#arguments.methodName#] expectation, but #arguments.passCount# passed",
					detail  = detail
				);
				break;
			}
			case "none": {
				if ( arguments.passCount == 0 ) {
					return;
				}
				var detail = buildFailureSummary(
					arguments.total,
					arguments.passCount,
					arguments.failDetails
				);
				variables.assert.fail(
					message = "expectNone() failed: expected 0 of #arguments.total# element(s) to pass the [#arguments.methodName#] expectation, but #arguments.passCount# passed",
					detail  = detail
				);
				break;
			}
		}
	}

	private string function buildFailureSummary(
		required numeric total,
		required numeric passCount,
		required array failDetails
	){
		var lines = [];
		arrayAppend( lines, "Passed: #arguments.passCount# / #arguments.total#" );

		if ( arrayLen( arguments.failDetails ) == 0 ) {
			return arrayToList( lines, chr( 10 ) );
		}

		arrayAppend( lines, "" );
		var maxDisplay = min( 5, arrayLen( arguments.failDetails ) );
		for ( var i = 1; i <= maxDisplay; i++ ) {
			var fd = arguments.failDetails[ i ];
			if ( isNumeric( fd.index ) ) {
				arrayAppend( lines, "[#fd.index#]: #fd.message#" );
			} else {
				arrayAppend( lines, "[#fd.index#]: #fd.message#" );
			}
		}

		var remaining = arrayLen( arguments.failDetails ) - maxDisplay;
		if ( remaining > 0 ) {
			arrayAppend( lines, "... and #remaining# more failure(s)" );
		}

		return arrayToList( lines, chr( 10 ) );
	}

}
