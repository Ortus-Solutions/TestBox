/**
 * Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
 * www.ortussolutions.com
 * ---
 * This object manages the results of testing with TestBox
 */
component accessors="true" {

	// Global Durations
	property name="startTime" type="numeric";
	property name="endTime" type="numeric";
	property name="totalDuration" type="numeric";

	// Global Stats
	property name="totalBundles" type="numeric";
	property name="totalSuites" type="numeric";
	property name="totalSpecs" type="numeric";
	property name="totalPass" type="numeric";
	property name="totalFail" type="numeric";
	property name="totalError" type="numeric";
	property name="totalSkipped" type="numeric";
	property name="labels" type="array";
	property name="excludes" type="array";

	// bundle stats
	property name="bundleStats" type="struct";

	// bundles, suites and specs only values that can execute
	property name="testBundles" type="array";
	property name="testSuites" type="array";
	property name="testSpecs" type="array";

	// Code Coverage
	property name="coverageEnabled" type="boolean";
	property name="coverageData" type="struct";


	/**
	 * Constructor
	 * @bundleCount.hint the count to init the results for
	 * @labels.hint The lables to use
	 * @testBundles.hint The test bundles that should execute ONLY
	 * @testSuites.hint The test suites that should execute ONLY
	 * @testSpecs.hint The test specs that should execut ONLY
	 */
	TestResult function init(
		numeric bundleCount = 0,
		array labels        = [],
		array excludes      = [],
		array testBundles   = [],
		array testSuites    = [],
		array testSpecs     = []
	){
		// internal id
		variables.resultsID     = createUUID();
		// TestBox version
		variables.version       = "3.1.0-snapshot";
		// Global test durations
		variables.startTime     = getTickCount();
		variables.endTime       = 0;
		variables.totalDuration = 0;

		// Global Stats
		variables.totalBundles = arguments.bundleCount;
		variables.totalSuites  = 0;
		variables.totalSpecs   = 0;
		variables.totalPass    = 0;
		variables.totalFail    = 0;
		variables.totalError   = 0;
		variables.totalSkipped = 0;
		variables.labels       = arguments.labels;
		variables.excludes     = arguments.excludes;

		// Run only
		variables.testBundles = arguments.testBundles;
		variables.testSuites  = arguments.testSuites;
		variables.testSpecs   = arguments.testSpecs;

		// Bundle Stats
		variables.bundleStats = [];

		// Reverse Lookups
		variables.bundleReverseLookup = {};
		variables.suiteReverseLookup  = {};

		// Coverage Data
		variables.coverageEnabled = false;
		variables.coverageData    = {};

		return this;
	}

	/**
	 * Finish recording stats
	 */
	TestResult function end(){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			if ( isComplete() ) {
				throw( type = "InvalidState", message = "Testing is already complete." );
			}
			variables.endTime       = getTickCount();
			variables.totalDuration = variables.endTime - variables.startTime;
		}
		return this;
	}

	/**
	 * Verify testing is complete in results
	 */
	boolean function isComplete(){
		lock name="tb-results-#variables.resultsID#" type="readonly" timeout="10" {
			return ( variables.endTime != 0 );
		}
	}

	/**
	 * Increment the global specs found
	 */
	TestResult function incrementSpecs( required count = 1 ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			variables.totalSpecs += arguments.count;
		}
		return this;
	}

	/**
	 * Increment the global suites found
	 */
	TestResult function incrementSuites( required count = 1 ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			variables.totalSuites += arguments.count;
		}
		return this;
	}

	/**
	 * Increment a global stat
	 * @type.hint The type of stat to increment: fail,pass,error or skipped
	 */
	TestResult function incrementStat( required type = "pass", numeric count = 1 ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			switch ( arguments.type ) {
				case "fail": {
					variables.totalFail += arguments.count;
					return this;
				}
				case "pass": {
					variables.totalPass += arguments.count;
					return this;
				}
				case "error": {
					variables.totalError += arguments.count;
					return this;
				}
				case "skipped": {
					variables.totalSkipped += arguments.count;
					return this;
				}
			}
		}
		return this;
	}

	/**
	 * Start a new bundle stats and return its reference
	 */
	struct function startBundleStats( required string bundlePath, required string name ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			// setup stats data for incoming bundle
			var stats = {
				// bundle id
				"id"              : hash( getTickCount() + randRange( 1, 10000000 ) ),
				// The bundle name
				"name"            : arguments.name,
				// Path of the bundle
				"path"            : arguments.bundlePath,
				// Total Suites in Bundle
				"totalSuites"     : 0,
				// Total specs found to test
				"totalSpecs"      : 0,
				// Total passed specs
				"totalPass"       : 0,
				// Total failed specs
				"totalFail"       : 0,
				// Total error in specs
				"totalError"      : 0,
				// Total skipped specs/suites
				"totalSkipped"    : 0,
				// Durations
				"startTime"       : getTickCount(),
				"endTime"         : 0,
				"totalDuration"   : 0,
				// Suite stats holder
				"suiteStats"      : [],
				// Debug output buffer
				"debugBuffer"     : [],
				// Global Exception
				"globalException" : ""
			};

			// store it in the bundle stats array
			arrayAppend( variables.bundleStats, stats );
			// store in the reverse lookup for faster access
			variables.bundleReverseLookup[ stats.id ] = stats;
		}
		// end lock

		return stats;
	}

	/**
	 * End processing of a bundle stats reference
	 * @stats.hint The bundle stats structure reference to complete
	 */
	TestResult function endStats( required struct stats ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			arguments.stats.endTime       = getTickCount();
			arguments.stats.totalDuration = arguments.stats.endTime - arguments.stats.startTime;
		}
		return this;
	}

	/**
	 * Get a bundle stats by path as a struct or the entire stats array if no path passed.
	 * @id.hint If passed, then retrieve by id
	 */
	any function getBundleStats( string id ){
		lock name="tb-results-#variables.resultsID#" type="readonly" timeout="10" {
			// search in reverse lookup
			if ( structKeyExists( arguments, "id" ) ) {
				return variables.bundleReverseLookup[ arguments.id ];
			}
			// else return the bundle stats array
			return variables.bundleStats;
		}
	}

	/**
	 * Store latest bundle debug output buffer by adding it to the top bundle
	 */
	any function storeDebugBuffer( array buffer ){
		lock name="tb-results-#variables.resultsID#" type="readonly" timeout="10" {
			variables.bundleStats[ arrayLen( variables.bundleStats ) ].debugBuffer = arguments.buffer;
		}
	}


	/**
	 * Start a new suite stats and return its reference
	 * @name.hint The name of the suite
	 * @bundleStats.hint The bundle stats reference this belongs to.
	 * @parentStats.hint If passed, the parent stats this suite belongs to
	 */
	struct function startSuiteStats( required string name, required struct bundleStats, struct parentStats = {} ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			// setup stats data for incoming suite
			var stats = {
				// suite id
				"id"            : hash( getTickCount() + randRange( 1, 10000000 ) ),
				// parent suite id
				"parentID"      : "",
				// bundle id
				"bundleID"      : arguments.bundleStats.id,
				// The suite name
				"name"          : arguments.name,
				// test status
				"status"        : "not executed",
				// Total specs found to test
				"totalSpecs"    : 0,
				// Total passed specs
				"totalPass"     : 0,
				// Total failed specs
				"totalFail"     : 0,
				// Total error in specs
				"totalError"    : 0,
				// Total skipped specs/suites
				"totalSkipped"  : 0,
				// Durations
				"startTime"     : getTickCount(),
				"endTime"       : 0,
				"totalDuration" : 0,
				// Recursive Suite stats holder
				"suiteStats"    : [],
				// Spec stats holder
				"specStats"     : []
			};

			// Parent stats
			if ( !structIsEmpty( arguments.parentStats ) ) {
				// link parent
				stats.parentID = arguments.parentStats.id;
				// store it in the nested suite
				arrayAppend( arguments.parentStats.suiteStats, stats );
			} else {
				// store it in the bundle stats
				arrayAppend( arguments.bundleStats.suiteStats, stats );
			}

			// store in the reverse lookup for faster access
			variables.suiteReverseLookup[ stats.id ] = stats;
		}
		// end lock

		return stats;
	}

	/**
	 * Get a suite stats by id from the reverse lookup
	 * @id.hint Retrieve by id
	 */
	any function getSuiteStats( required string id ){
		lock name="tb-results-#variables.resultsID#" type="readonly" timeout="10" {
			return variables.suiteReverseLookup[ arguments.id ];
		}
	}

	/**
	 * Start a new spec stats and return its reference
	 * @name.hint The name of the suite
	 * @suiteStats.hint The suite stats reference this belongs to.
	 */
	struct function startSpecStats( required string name, required struct suiteStats ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			// spec stats
			var stats = {
				// suite id
				"id"               : hash( getTickCount() + randRange( 1, 10000000 ) ),
				// suite id
				"suiteID"          : arguments.suiteStats.id,
				// name of the spec
				"name"             : arguments.name,
				// spec status
				"status"           : "na",
				// durations
				"startTime"        : getTickCount(),
				"endTime"          : 0,
				"totalDuration"    : 0,
				// exception structure
				"error"            : {},
				// the failure message
				"failMessage"      : "",
				// the failure detail
				"failDetail"       : "",
				// the failure extended info
				"failExtendedInfo" : "",
				// the failure stack trace
				"failStacktrace"   : "",
				// the failure origin
				"failOrigin"       : {}
			};

			// append to the parent stats
			arrayAppend( arguments.suiteStats.specStats, stats );
		}
		// end lock

		return stats;
	}

	/**
	 * Record a spec stat with its recursive chain
	 * @type.hint The type of stat to store: skipped,fail,error,pass
	 * @specStats.hint The spec stats to increment
	 */
	function incrementSpecStat( required string type, required struct stats ){
		lock name="tb-results-#variables.resultsID#" type="exclusive" timeout="10" {
			// increment suite stat
			variables.suiteReverseLookup[ arguments.stats.suiteID ][ "total#arguments.type#" ]++;
			// increment bundle stat
			variables.bundleReverseLookup[ variables.suiteReverseLookup[ arguments.stats.suiteID ].bundleID ][
				"total#arguments.type#"
			]++;
			// increment global stat
			variables[ "total#arguments.type#" ]++;
		}
	}

	/**
	 * Get a flat representation of this result.
	 *
	 * @includeDebugBuffer Include the debug buffer or not, by default we strip it out
	 */
	struct function getMemento( boolean includeDebugBuffer = false ){
		var pList = [
			"resultID",
			"version",
			"labels",
			"excludes",
			"startTime",
			"endTime",
			"totalDuration",
			"totalBundles",
			"totalSuites",
			"totalSpecs",
			"totalPass",
			"totalFail",
			"totalError",
			"totalSkipped",
			"bundleStats"
		];
		var result = {
			"CFMLEngine"        : server.coldfusion.productName,
			"CFMLEngineVersion" : (
				structKeyExists( server, "lucee" ) ? server.lucee.version : server.coldfusion.productVersion
			),
			"coverage" : {}
		};

		// Do simple properties only
		for ( var thisProp in pList ) {
			if ( structKeyExists( variables, thisProp ) ) {
				// Do we need to strip out the buffer?
				if ( thisProp == "bundleStats" && !arguments.includeDebugBuffer ) {
					for ( var thisKey in variables[ thisProp ] ) {
						structDelete( thisKey, "debugBuffer" );
					}
				}

				result[ thisProp ] = variables[ thisProp ];
			} else {
				result[ thisProp ] = "";
			}
		}

		result.coverage = { "enabled" : coverageEnabled, "data" : {} };

		if ( coverageEnabled ) {
			result.coverage.data = {
				"stats"            : {},
				"sonarQubeResults" : coverageData.sonarQubeResults,
				"browserResults"   : coverageData.browserResults
			};
			result.coverage.data.stats = {
				"numFiles"             : coverageData.stats.numFiles,
				"percTotalCoverage"    : coverageData.stats.percTotalCoverage,
				"totalExecutableLines" : coverageData.stats.totalExecutableLines,
				"totalCoveredLines"    : coverageData.stats.totalCoveredLines
			};
		}

		return result;
	}

}
