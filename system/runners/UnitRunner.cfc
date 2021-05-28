/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This TestBox runner is used to run and report on xUnit style test suites.
 */
component
	extends   ="testbox.system.runners.BaseRunner"
	implements="testbox.system.runners.IRunner"
	accessors ="true"
{

	// runner options
	property name="options";
	// testbox reference
	property name="testbox";

	/**
	 * Constructor
	 * @options.hint The options for this runner
	 * @testbox.hint The TestBox class reference
	 */
	function init(
		required struct options,
		required testBox
	){
		variables.options = arguments.options;
		variables.testbox = arguments.testbox;

		return this;
	}

	/**
	 * Execute a BDD test on the incoming target and store the results in the incoming test results
	 * @target.hint The target bundle CFC to test
	 * @testResults.hint The test results object to keep track of results for this test case
	 * @callbacks A struct of listener callbacks or a CFC with callbacks for listening to progress of the testing: onBundleStart,onBundleEnd,onSuiteStart,onSuiteEnd,onSpecStart,onSpecEnd
	 */
	any function run(
		required any target,
		required testbox.system.TestResult testResults,
		required callbacks
	){
		// Get target information
		var targetMD   = getMetadata( arguments.target );
		var bundleName = ( structKeyExists( targetMD, "displayName" ) ? targetMD.displayname : targetMD.name );

		// Discover the test suite data to use for testing
		var testSuites = getTestSuites(
			arguments.target,
			targetMD,
			arguments.testResults,
			arguments.callbacks
		);
		var testSuitesCount = arrayLen( testSuites );

		// Start recording stats for this bundle
		var bundleStats = arguments.testResults.startBundleStats(
			bundlePath = targetMD.name,
			name       = bundleName
		);

		// Verify we can run this bundle
		if (
			canRunBundle(
				bundlePath  = targetMD.name,
				testResults = arguments.testResults,
				targetMD    = targetMD
			)
		) {
			try {
				// execute beforeAll(), beforeTests() for this bundle, no matter how many suites they have.
				if ( structKeyExists( arguments.target, "beforeAll" ) ) {
					arguments.target.beforeAll();
				}

				// find any methods annotated 'beforeAll' and execute them
				var beforeAllAnnotationMethods = variables.testbox
					.getUtility()
					.getAnnotatedMethods(
						annotation = "beforeAll",
						metadata   = getMetadata( arguments.target )
					);

				for ( var beforeAllMethod in beforeAllAnnotationMethods ) {
					invoke(
						arguments.target,
						"#beforeAllMethod.name#"
					);
				}

				if ( structKeyExists( arguments.target, "beforeTests" ) ) {
					arguments.target.beforeTests();
				}

				// Iterate over found test suites and test them, if nested suites, then this will recurse as well.
				for ( var thisSuite in testSuites ) {
					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSuiteStart" ) ) {
						arguments.callbacks.onSuiteStart(
							arguments.target,
							arguments.testResults,
							thisSuite
						);
					}

					// Execute Suite
					testSuite(
						target      = arguments.target,
						suite       = thisSuite,
						testResults = arguments.testResults,
						bundleStats = bundleStats,
						callbacks   = arguments.callbacks
					);

					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSuiteEnd" ) ) {
						arguments.callbacks.onSuiteEnd(
							arguments.target,
							arguments.testResults,
							thisSuite
						);
					}
				}

				// execute afterAll(), afterTests() for this bundle, no matter how many suites they have.
				if ( structKeyExists( arguments.target, "afterAll" ) ) {
					arguments.target.afterAll();
				}

				// find any methods annotated 'afterAll' and execute them
				var afterAllAnnotationMethods = variables.testbox
					.getUtility()
					.getAnnotatedMethods(
						annotation = "afterAll",
						metadata   = getMetadata( arguments.target )
					);

				for ( var afterAllMethod in afterAllAnnotationMethods ) {
					invoke(
						arguments.target,
						"#afterAllMethod.name#"
					);
				}

				if ( structKeyExists( arguments.target, "afterTests" ) ) {
					arguments.target.afterTests();
				}
			} catch ( Any e ) {
				bundleStats.globalException = e;
				// For a righteous man falls seven times, and rises (tests) again :)
				// The amount doesn't matter, nothing can run at this point, failure with before/after aspects that need fixing
				bundleStats.totalError      = 7;
				arguments.testResults.incrementStat(
					type  = "error",
					count = bundleStats.totalError
				);
			}
		}

		// finalize the bundle stats
		arguments.testResults.endStats( bundleStats );

		return this;
	}

	/************************************** TESTING METHODS *********************************************/

	/**
	 * Test the incoming suite definition
	 * @target.hint The target bundle CFC
	 * @method.hint The method definition to test
	 * @testResults.hint The testing results object
	 * @bundleStats.hint The bundle stats this suite belongs to
	 * @callbacks The CFC or struct of callback listener methods
	 */
	private function testSuite(
		required target,
		required suite,
		required testResults,
		required bundleStats,
		required callbacks = {}
	){
		// Start suite stats
		var suiteStats = arguments.testResults.startSuiteStats(
			arguments.suite.name,
			arguments.bundleStats
		);

		// Record bundle + suite + global initial stats
		suiteStats.totalSpecs = arrayLen( arguments.suite.specs );
		arguments.bundleStats.totalSpecs += suiteStats.totalSpecs;
		arguments.bundleStats.totalSuites++;
		// increment global suites + specs
		arguments.testResults
			.incrementSuites()
			.incrementSpecs( suiteStats.totalSpecs );

		var skip = arguments.suite.skip;
		if ( structKeyExists( arguments.callbacks, "skipHandler" ) ) {
			skip = arguments.callbacks.skipHandler( arguments.suite.skip );
		}

		// Verify we can execute the incoming suite via skipping or labels
		if (
			!skip &&
			canRunSuite(
				arguments.suite,
				arguments.testResults,
				arguments.target
			)
		) {
			// prepare threaded names
			var threadNames    = [];
			// threaded variables just in case some suite is async and another is not.
			thread.testResults = arguments.testResults;
			thread.suiteStats  = suiteStats;
			thread.target      = arguments.target;

			// iterate over suite specs and test them
			for ( var thisSpec in arguments.suite.specs ) {
				// is this async or not?
				if ( arguments.suite.asyncAll ) {
					// prepare thread name
					var thisThreadName = variables.testBox
						.getUtility()
						.slugify( "tb-" & thisSpec.name & "-#hash( getTickCount() + randRange( 1, 10000000 ) )#" );
					// append to used thread names
					arrayAppend( threadNames, thisThreadName );
					// thread it
					thread
						name      ="#thisThreadName#"
						thisSpec  ="#thisSpec#"
						suite     ="#arguments.suite#"
						threadName="#thisThreadName#"
						callbacks ="#arguments.callbacks#" {
						// verify call backs
						if ( structKeyExists( attributes.callbacks, "onSpecStart" ) ) {
							attributes.callbacks.onSpecStart(
								thread.target,
								thread.testResults,
								thread.suiteStats,
								attributes.thisSpec
							);
						}

						// execute the test within the context of the spec target due to lucee closure bug, move back once it is resolved.
						thread.target.runTestMethod(
							spec        = attributes.thisSpec,
							testResults = thread.testResults,
							suiteStats  = thread.suiteStats,
							runner      = this
						);

						// verify call backs
						if ( structKeyExists( attributes.callbacks, "onSpecEnd" ) ) {
							attributes.callbacks.onSpecEnd(
								thread.target,
								thread.testResults,
								thread.suiteStats,
								attributes.thisSpec
							);
						}
					}
				} else {
					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSpecStart" ) ) {
						arguments.callbacks.onSpecStart(
							arguments.target,
							arguments.testResults,
							thread.suiteStats,
							thisSpec
						);
					}

					// execute the test within the context of the spec target due to lucee closure bug, move back once it is resolved.
					thread.target.runTestMethod(
						spec        = thisSpec,
						testResults = thread.testResults,
						suiteStats  = thread.suiteStats,
						runner      = this
					);

					// verify call backs
					if ( structKeyExists( arguments.callbacks, "onSpecEnd" ) ) {
						arguments.callbacks.onSpecEnd(
							arguments.target,
							arguments.testResults,
							thread.suiteStats,
							thisSpec
						);
					}
				}
			}
			// end loop over specs

			// join threads if async
			if ( arguments.suite.asyncAll ) {
				thread action="join" name="#arrayToList( threadNames )#" {
				};
			}

			// All specs finalized, set suite status according to spec data
			if ( suiteStats.totalError GT 0 ) {
				suiteStats.status = "Error";
			} else if ( suiteStats.totalFail GT 0 ) {
				suiteStats.status = "Failed";
			} else {
				suiteStats.status = "Passed";
			}

			// Skip Checks
			if ( suiteStats.totalSpecs == suiteStats.totalSkipped ) {
				suiteStats.status = "Skipped";
			}
		} else {
			// Record skipped stats and status
			suiteStats.status = "Skipped";
			arguments.bundleStats.totalSkipped += suiteStats.totalSpecs;
			arguments.testResults.incrementStat( "skipped", suiteStats.totalSpecs );
		}

		// Finalize the suite stats
		arguments.testResults.endStats( suiteStats );
	}

	/**
	 * Get all the test suites in the passed in bundle
	 * @target.hint The target to get the suites from
	 * @targetMD.hint The metadata of the target
	 * @testResults.hint The test results object
	 */
	private array function getTestSuites(
		required target,
		required targetMD,
		required testResults,
		required callbacks
	){
		var suite = {
			// suite name
			name : (
				structKeyExists( arguments.targetMD, "displayName" ) ? arguments.targetMD.displayname : arguments.targetMD.name
			),
			// async flag
			asyncAll : ( structKeyExists( arguments.targetMD, "asyncAll" ) ? arguments.targetMD.asyncAll : false ),
			// skip suite testing flag
			skip     : (
				structKeyExists( arguments.targetMD, "skip" ) ? (
					len( arguments.targetMD.skip ) ? arguments.targetMD.skip : true
				) : false
			),
			// labels attached to the suite for execution
			labels : ( structKeyExists( arguments.targetMD, "labels" ) ? listToArray( arguments.targetMD.labels ) : [] ),
			// the specs attached to this suite.
			specs  : getTestMethods(
				arguments.target,
				arguments.testResults,
				arguments.callbacks
			),
			// the recursive suites
			suites : []
		};

		// skip constraint for suite?
		if ( structKeyExists( arguments.callbacks, "skipHandler" ) ) {
			suite.skip = arguments.callbacks.skipHandler( suite.skip );
		} else if ( !isBoolean( suite.skip ) && isCustomFunction( arguments.target[ suite.skip ] ) ) {
			suite.skip = invoke( arguments.target, "#suite.skip#" );
		}

		// check them.
		if ( arrayLen( arguments.testResults.getLabels() ) )
			suite.skip = ( !canRunLabel( suite.labels, arguments.testResults ) );

		return [ suite ];
	}

	/**
	 * Retrieve the testing methods/specs from a given target.
	 * @target.hint The target to get the methods from
	 */
	private array function getTestMethods(
		required any target,
		required any testResults,
		required any callbacks
	){
		var mResults    = [];
		var methodArray = structKeyArray( arguments.target );
		var index       = 1;

		for ( var thisMethod in methodArray ) {
			// only valid functions and test functions allowed
			if (
				isCustomFunction( arguments.target[ thisMethod ] ) &&
				isValidTestMethod( thisMethod, arguments.target )
			) {
				// Build the spec data packet
				var specMD = getMetadata( arguments.target[ thisMethod ] );
				var spec   = {
					name              : specMD.name,
					hint              : ( structKeyExists( specMD, "hint" ) ? specMD.hint : "" ),
					skip              : ( structKeyExists( specMD, "skip" ) ? ( len( specMD.skip ) ? specMD.skip : true ) : false ),
					labels            : ( structKeyExists( specMD, "labels" ) ? listToArray( specMD.labels ) : [] ),
					order             : ( structKeyExists( specMD, "order" ) ? listToArray( specMD.order ) : index++ ),
					expectedException : ( structKeyExists( specMD, "expectedException" ) ? specMD.expectedException : "" )
				};

				// skip constraint?
				if ( structKeyExists( arguments.callbacks, "skipHandler" ) ) {
					spec.skip = arguments.callbacks.skipHandler( spec.skip );
				} else if ( !isBoolean( spec.skip ) && isCustomFunction( arguments.target[ spec.skip ] ) ) {
					spec.skip = invoke( arguments.target, "#spec.skip#" );
				}

				// do we have labels applied?
				if ( arrayLen( arguments.testResults.getLabels() ) )
					spec.skip = ( !canRunLabel( spec.labels, arguments.testResults ) );

				// register spec
				arrayAppend( mResults, spec );
			}
		}
		return mResults;
	}

}
