component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Dry Run", function(){
			beforeEach( function(){
				clearRequestFlags();
			} );

			afterEach( function(){
				clearRequestFlags();
			} );

			it( "discovers BDD specs and labels without executing lifecycle hooks", function(){
				var testbox = new testbox.system.TestBox(
					bundles = "tests.resources.dryrun.DryRunBDDFixture",
					options = { coverage : { enabled : false } }
				);
				var discovery = testbox.dryRun();
				var bundle    = discovery.bundles[ 1 ];
				var suite     = bundle.suites[ 1 ];
				var spec      = suite.specs[ 1 ];
				var skipped   = suite.specs[ 2 ];

				expect( structKeyExists( request, "dryRunBDDBeforeAll" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunBDDAfterAll" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunBDDBeforeEach" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunBDDAfterEach" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunBDDSpecRuns" ) ).toBeFalse();
				expect( discovery.summary.totalBundles ).toBe( 1 );
				expect( discovery.summary.totalSuites ).toBe( 1 );
				expect( discovery.summary.totalSpecs ).toBe( 2 );
				expect( bundle.type ).toBe( "bdd" );
				expect( suite.name ).toBe( "Runnable Suite" );
				expect( spec.displayName ).toBe( "Runnable Spec" );
				expect( spec.skip ).toBeFalse();
				expect( skipped.displayName ).toBe( "Skipped Spec" );
				expect( skipped.skip ).toBeTrue();
				expect( arrayToList( spec.labels ) ).toBe( "specLabel" );
				expect( arrayFindNoCase( spec.effectiveLabels, "componentLabel" ) ).toBeGT( 0 );
				expect( arrayFindNoCase( spec.effectiveLabels, "suiteLabel" ) ).toBeGT( 0 );
				expect( arrayFindNoCase( spec.effectiveLabels, "specLabel" ) ).toBeGT( 0 );
				expect( structKeyExists( request, "dryRunBDDSkippedSpecRuns" ) ).toBeFalse();
			} );

			it( "discovers xUnit specs and labels without executing lifecycle hooks", function(){
				var testbox = new testbox.system.TestBox(
					bundles = "tests.resources.dryrun.DryRunXUnitFixture",
					options = { coverage : { enabled : false } }
				);
				var discovery = testbox.dryRun();
				var bundle    = discovery.bundles[ 1 ];
				var suite     = bundle.suites[ 1 ];
				var spec      = suite.specs[ 1 ];

				expect( structKeyExists( request, "dryRunXBeforeTests" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunXSetup" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunXTeardown" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunXAfterTests" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunXSpecRuns" ) ).toBeFalse();
				expect( discovery.summary.totalBundles ).toBe( 1 );
				expect( discovery.summary.totalSuites ).toBe( 1 );
				expect( discovery.summary.totalSpecs ).toBe( 1 );
				expect( bundle.type ).toBe( "xunit" );
				expect( spec.name ).toBe( "testRunnable" );
				expect( arrayFindNoCase( spec.labels, "methodLabel" ) ).toBeGT( 0 );
				expect( arrayFindNoCase( spec.effectiveLabels, "componentLabel" ) ).toBeGT( 0 );
			} );

			it( "returns no runnable bundles when labels filter excludes all tests", function(){
				var testbox = new testbox.system.TestBox(
					bundles = "tests.resources.dryrun.DryRunBDDFixture",
					labels  = "missingLabel",
					options = { coverage : { enabled : false } }
				);
				var discovery = testbox.dryRun();
				var bundle    = discovery.bundles[ 1 ];
				var suite     = bundle.suites[ 1 ];
				var spec      = suite.specs[ 1 ];

				expect( discovery.summary.totalBundles ).toBe( 1 );
				expect( discovery.summary.totalSuites ).toBe( 1 );
				expect( discovery.summary.totalSpecs ).toBe( 1 );
				expect( arrayLen( discovery.bundles ) ).toBe( 1 );
				expect( spec.displayName ).toBe( "Skipped Spec" );
				expect( spec.skip ).toBeTrue();
			} );

			it( "omits BDD bundles whose component-level skip annotation resolves to true", function(){
				clearRequestFlags();

				var testbox = new testbox.system.TestBox(
					bundles = "tests.resources.dryrun.DryRunBDDSkippedBundleFixture",
					options = { coverage : { enabled : false } }
				);
				var discovery = testbox.dryRun();

				// Skipped bundles should not appear in the dry-run tree at all
				expect( structKeyExists( request, "dryRunBDDSkippedBeforeAll" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunBDDSkippedAfterAll" ) ).toBeFalse();
				expect( structKeyExists( request, "dryRunBDDSkippedSpecRuns" ) ).toBeFalse();
				expect( discovery.summary.totalBundles ).toBe( 0 );
				expect( arrayLen( discovery.bundles ) ).toBe( 0 );
			} );

			it( "resolves a string function-name skip annotation by invoking it on the target", function(){
				var target  = new tests.resources.dryrun.DryRunBDDFixture();
				var baseRunner = new testbox.system.runners.BaseRunner();

				// No annotation -> not skipped
				expect( baseRunner.getBundleSkip( target ) ).toBeFalse();

				// Function-name reference -> the method is invoked
				var dynamicTarget = createObject( "component", "testbox.tests.specs.DynamicSkipFixture" );
				expect( baseRunner.getBundleSkip( dynamicTarget ) ).toBeTrue();
			} );
		} );
	}

	private function clearRequestFlags(){
		var keys = [
			"dryRunBDDBeforeAll",
			"dryRunBDDAfterAll",
			"dryRunBDDBeforeEach",
			"dryRunBDDAfterEach",
			"dryRunBDDSpecRuns",
			"dryRunBDDSkippedSpecRuns",
			"dryRunBDDSkippedBeforeAll",
			"dryRunBDDSkippedAfterAll",
			"dryRunXBeforeTests",
			"dryRunXSetup",
			"dryRunXTeardown",
			"dryRunXAfterTests",
			"dryRunXSpecRuns",
			"dryRunXSkippedSpecRuns"
		];

		for ( var key in keys ) {
			structDelete( request, key, false );
		}
	}

}
