/**
 * Tests for the presentation logic shared by the HTML reporters
 */
component extends="testbox.system.BaseSpec" {

	variables.mixed = "tests.resources.reporters.MixedBundle";

	/**
	 * Build a helper, optionally with the url scope and options a run would have
	 */
	private function newHelper( struct urlScope = {}, struct options = {} ){
		return new testbox.system.reports.ReportHelper(
			reporter = new testbox.system.reports.SimpleReporter(),
			options  = arguments.options,
			urlScope = arguments.urlScope
		);
	}

	/**
	 * Run a fixture bundle and return the TestBox and its results
	 */
	private struct function runFixture( required string bundle ){
		var tb      = new testbox.system.TestBox( bundles = arguments.bundle );
		var results = tb.runRaw();
		return { testbox : tb, results : results };
	}

	function run(){
		describe( "ReportHelper", function(){
			describe( "status presentation", function(){
				it( "knows the four statuses regardless of case", function(){
					var helper = newHelper();
					expect( helper.status( "Passed" ).key ).toBe( "passed" );
					expect( helper.status( "FAILED" ).label ).toBe( "Failed" );
					expect( helper.status( "error" ).icon ).toBe( "exclamation-octagon-fill" );
					expect( helper.status( "Skipped" ).short ).toBe( "skipped" );
				} );

				it( "treats an unknown status as skipped", function(){
					expect( newHelper().status( "na" ).key ).toBe( "skipped" );
				} );

				it( "lists the statuses in display order", function(){
					var keys = newHelper()
						.statusList()
						.map( function( s ){
							return s.key;
						} );
					expect( keys ).toBe( [ "passed", "failed", "error", "skipped" ] );
				} );
			} );

			describe( "wording", function(){
				it( "pluralizes by count", function(){
					var helper = newHelper();
					expect( helper.plural( 1, "failure" ) ).toBe( "1 failure" );
					expect( helper.plural( 3, "failure" ) ).toBe( "3 failures" );
					expect( helper.plural( 0, "spec" ) ).toBe( "0 specs" );
					expect( helper.plural( 2, "bundle exception" ) ).toBe( "2 bundle exceptions" );
					expect( helper.plural( 2, "match", "matches" ) ).toBe( "2 matches" );
				} );

				it( "formats durations", function(){
					var helper = newHelper();
					expect( helper.duration( 42 ) ).toBe( "42 ms" );
					expect( helper.duration( 1500 ) ).toBe( "1.50 s" );
				} );

				it( "computes percentages without dividing by zero", function(){
					var helper = newHelper();
					expect( helper.percentOf( 1, 4 ) ).toBe( 25 );
					expect( helper.percentOf( 0, 0 ) ).toBe( 0 );
				} );
			} );

			describe( "verdict", function(){
				it( "is bad and counts failures and errors", function(){
					var run     = runFixture( variables.mixed );
					var verdict = newHelper().verdict( run.results );
					expect( verdict.bad ).toBeTrue();
					expect( verdict.title ).toBe( "2 failures, 1 error" );
					expect( verdict.counts ).toBe( { passed : 2, failed : 2, error : 1, skipped : 1 } );
					expect( verdict.tabTitle ).toBe( "FAILED 3" );
				} );

				it( "is good when everything passed", function(){
					var run     = runFixture( "tests.resources.reporters.PassingBundle" );
					var verdict = newHelper().verdict( run.results );
					expect( verdict.bad ).toBeFalse();
					expect( verdict.title ).toBe( "All 1 spec passed" );
					expect( verdict.tabTitle ).toBe( "PASSED 1" );
				} );

				it( "is bad for a bundle exception even when no spec failed", function(){
					var run     = runFixture( "tests.specsWithFailures.BeforeAllFailures" );
					var helper  = newHelper();
					var verdict = helper.verdict( run.results );
					expect( verdict.bad ).toBeTrue();
					expect( verdict.title ).toInclude( "bundle exception" );
					expect( helper.exceptions( run.results.getBundleStats() ) ).toHaveLength( 1 );
				} );

				it( "never counts a negative number of errors for a bundle", function(){
					var bundle = {
						totalPass    : 0,
						totalFail    : 0,
						totalError   : -1,
						totalSkipped : 0
					};
					expect( newHelper().countOf( bundle, "error" ) ).toBe( 0 );
					expect( newHelper().countOf( bundle, "passed" ) ).toBe( 0 );
				} );
			} );

			describe( "run links", function(){
				it( "re-runs everything without carrying current runner arguments", function(){
					var helper = newHelper( {
						method         : "runRemote",
						directory      : "tests.specs",
						recurse        : "true",
						reporter       : "simple",
						bundlesPattern : "*Spec*.cfc|*Test*.cfc"
					} );
					expect( helper.runURL() ).toBe( "?" );
				} );

				it( "scopes to only the selected bundle", function(){
					var link = newHelper().runURL( bundle = "tests.specs.FooTest" );
					expect( link ).toBe( "?testBundles=tests.specs.FooTest" );
				} );

				it( "scopes to a suite and a spec", function(){
					var link = newHelper().runURL(
						bundle = "tests.specs.FooTest",
						suite  = "my suite",
						spec   = "abc123"
					);
					expect( link ).toInclude( "testBundles=tests.specs.FooTest" );
					expect( link ).toInclude( "testSuites=my%20suite" );
					expect( link ).toInclude( "testSpecs=abc123" );
				} );

				it( "does not carry runner options into a targeted run", function(){
					var link = newHelper( {
						method          : "runRemote",
						output          : "raw",
						directory       : "tests.specs",
						labels          : "smoke,api",
						excludes        : "slow",
						reporter        : "simple",
						recurse         : "true",
						bundlesPattern  : "*Spec*.cfc|*Test*.cfc",
						coverageEnabled : "true"
					} ).runURL( bundle = "a.b" );
					expect( link ).toBe( "?testBundles=a.b" );
				} );

				it( "leaves out empty params and the default editor", function(){
					var link = newHelper( { directory : "", labels : "", editor : "vscode" } ).runURL();
					expect( link ).toBe( "?" );
				} );

				it( "encodes values so they can not break out of the query", function(){
					var link = newHelper().runURL( bundle = "a&b=c" );
					expect( link ).toBe( "?testBundles=a%26b%3Dc" );
				} );

				it( "re-runs only the failed bundles and specs", function(){
					var link = newHelper().failedRunURL( {
						bundles      : [ "a.b", "c.d" ],
						specs        : [ "id1", "id2" ],
						bundleErrors : [ "e.f" ]
					} );
					expect( link ).toBe( "?testBundles=a.b%2Cc.d&testSpecs=id1%2Cid2" );
				} );

				it( "re-runs the failed bundles whole when the spec ids make the url too long", function(){
					var link = newHelper().failedRunURL(
						{
							bundles      : [ "a.b" ],
							specs        : [ "id1", "id2" ],
							bundleErrors : []
						},
						20
					);
					expect( link ).toBe( "?testBundles=a.b" );
				} );

				it( "has no failed run url when nothing failed", function(){
					expect( newHelper().failedRunURL( { bundles : [], specs : [], bundleErrors : [ "e.f" ] } ) ).toBe( "" );
				} );

				it( "prepares a url for an html attribute", function(){
					expect( newHelper().href( "?a=1&b=2" ) ).toBe( "?a=1&amp;b=2" );
				} );
			} );

			describe( "bundle run scope", function(){
				it( "identifies bundles selected for the current run", function(){
					var helper = newHelper( { testBundles : "tests.specs.FooTest,tests.specs.BarTest" } );
					expect( helper.isBundleScoped( { path : "tests.specs.FooTest" } ) ).toBeTrue();
					expect( helper.isBundleScoped( { path : "tests.specs.OtherTest" } ) ).toBeFalse();
				} );

				it( "does not treat an unscoped report as a targeted bundle run", function(){
					expect( newHelper().isBundleScoped( { path : "tests.specs.FooTest" } ) ).toBeFalse();
				} );
			} );

			describe( "failures", function(){
				it( "flattens failed and errored specs with their suite path", function(){
					var run      = runFixture( variables.mixed );
					var failures = newHelper().failures( run.results.getBundleStats() );
					expect( failures ).toHaveLength( 3 );
					var crumbs = failures.map( function( f ){
						return f.crumb;
					} );
					expect( crumbs ).toInclude( "Math" );
					expect( crumbs ).toInclude( "Math > nested" );
				} );

				it( "composes the message per status", function(){
					var helper = newHelper();
					expect( helper.specMessage( { status : "Failed", failMessage : "nope" } ) ).toBe( "nope" );
					expect(
						helper.specMessage( {
							status : "Error",
							error  : { message : "boom", detail : " (detail)" }
						} )
					).toBe( "boom (detail)" );
					expect( helper.specMessage( { status : "Passed" } ) ).toBe( "" );
				} );

				it( "knows which specs are problems", function(){
					var helper = newHelper();
					expect( helper.isProblem( { status : "Failed" } ) ).toBeTrue();
					expect( helper.isProblem( { status : "Error" } ) ).toBeTrue();
					expect( helper.isProblem( { status : "Passed" } ) ).toBeFalse();
					expect( helper.isProblem( { status : "Skipped" } ) ).toBeFalse();
				} );

				it( "flattens every spec of a bundle in run order", function(){
					var run   = runFixture( variables.mixed );
					var specs = newHelper().specs( run.results.getBundleStats()[ 1 ] );
					expect( specs ).toHaveLength( 6 );
					expect( specs[ 1 ].spec.displayName ).toBe( "passes" );
					expect( specs[ 6 ].crumb ).toBe( "Math > nested" );
				} );
			} );

			describe( "origin of a failure", function(){
				var frame = function( template, line ){
					return { template : template, line : line, id : "x" };
				};

				it( "prefers the first frame in your code over TestBox internals", function(){
					var spec = {
						status     : "Failed",
						failOrigin : [
							frame( "/app/testbox/system/Expectation.cfc", 10 ),
							frame( "/app/tests/specs/FooTest.cfc", 42 ),
							frame( "/app/tests/specs/Other.cfc", 7 )
						],
						error : {}
					};
					var origin = newHelper().origin( spec );
					expect( origin.line ).toBe( 42 );
					expect( origin.template ).toInclude( "FooTest.cfc" );
					expect( origin.user ).toBeTrue();
				} );

				it( "falls back to the first frame when only TestBox frames exist", function(){
					var spec = {
						status     : "Failed",
						failOrigin : [ frame( "/app/testbox/system/Expectation.cfc", 10 ) ],
						error      : {}
					};
					expect( newHelper().origin( spec ).line ).toBe( 10 );
				} );

				it( "reads the tag context of an error", function(){
					var spec = {
						status     : "Error",
						failOrigin : {},
						error      : { tagContext : [ frame( "/app/tests/specs/FooTest.cfc", 5 ) ] }
					};
					expect( newHelper().origin( spec ).line ).toBe( 5 );
				} );

				it( "returns an empty struct when there is nothing to point at", function(){
					expect( newHelper().origin( { status : "Failed", failOrigin : {}, error : {} } ) ).toBeEmpty();
				} );

				it( "shortens paths by removing the web root", function(){
					var helper = newHelper();
					var root   = replace( expandPath( "/" ), "\", "/", "all" );
					if ( right( root, 1 ) != "/" ) {
						root &= "/";
					}
					expect( helper.relativePath( root & "tests/specs/FooTest.cfc" ) ).toBe( "tests/specs/FooTest.cfc" );
					expect( helper.relativePath( "/elsewhere/Foo.cfc" ) ).toBe( "/elsewhere/Foo.cfc" );
				} );
			} );

			describe( "code snippets", function(){
				var file = expandPath( "/tests/resources/reporters/MixedBundle.cfc" );

				it( "reads the lines around a line and marks the hit", function(){
					var lines = newHelper().snippet( file, 14, 2 );
					expect( lines ).toHaveLength( 5 );
					expect( lines[ 1 ].n ).toBe( 12 );
					var hits = lines.filter( function( l ){
						return l.hit;
					} );
					expect( hits ).toHaveLength( 1 );
					expect( hits[ 1 ].n ).toBe( 14 );
				} );

				it( "removes the indentation the shown lines share", function(){
					var lines = newHelper().snippet( file, 14, 1 );
					var first = lines.filter( function( l ){
						return len( trim( l.text ) );
					} )[ 1 ];
					expect( left( first.text, 1 ) ).notToBe( chr( 9 ) );
				} );

				it( "stops at the edges of the file", function(){
					var lines = newHelper().snippet( file, 1, 3 );
					expect( lines[ 1 ].n ).toBe( 1 );
				} );

				it( "returns nothing for a missing file or a bad line", function(){
					var helper = newHelper();
					expect( helper.snippet( "/no/such/file.cfc", 3, 2 ) ).toBeEmpty();
					expect( helper.snippet( file, 0, 2 ) ).toBeEmpty();
				} );

				it( "picks the Prism language from the extension", function(){
					var helper = newHelper();
					expect( helper.languageOf( "A.bx" ) ).toBe( "boxlang" );
					expect( helper.languageOf( "A.bxs" ) ).toBe( "boxlang" );
					expect( helper.languageOf( "A.cfc" ) ).toBe( "cfscript" );
					expect( helper.languageOf( "A.txt" ) ).toBe( "clike" );
				} );
			} );

			describe( "Ask AI", function(){
				var failureOf = function(){
					var run = runFixture( variables.mixed );
					return {
						results : run.results,
						testbox : run.testbox,
						failure : newHelper().failures( run.results.getBundleStats() )[ 1 ]
					};
				};

				it( "builds a prompt with the spec, message, code and a re-run command", function(){
					var ctx    = failureOf();
					var prompt = newHelper().prompt( ctx.failure, ctx.results, ctx.testbox );
					expect( prompt ).toInclude( "One spec failed" );
					expect( prompt ).toInclude( "Spec: " & ctx.failure.bundle.path );
					expect( prompt ).toInclude( "Message: " & ctx.failure.message );
					expect( prompt ).toInclude( "MixedBundle.cfc" );
					expect( prompt ).toInclude( "Re-run only this spec" );
					expect( prompt ).toInclude( "--filter-specs=" );
				} );

				it( "says errored for an error", function(){
					var run      = runFixture( variables.mixed );
					var helper   = newHelper();
					var failures = helper.failures( run.results.getBundleStats() );
					var errored  = failures.filter( function( f ){
						return f.spec.status == "Error";
					} )[ 1 ];
					expect( helper.prompt( errored, run.results, run.testbox ) ).toInclude( "One spec errored" );
				} );

				it( "limits the stack frames", function(){
					var ctx = failureOf();
					var one = newHelper( {}, { aiStackFrames : 1 } ).prompt(
						ctx.failure,
						ctx.results,
						ctx.testbox
					);
					var all = newHelper( {}, { aiStackFrames : 20 } ).prompt(
						ctx.failure,
						ctx.results,
						ctx.testbox
					);
					expect( len( one ) ).toBeLTE( len( all ) );
				} );

				it( "fills a custom prompt template", function(){
					var ctx    = failureOf();
					var prompt = newHelper( {}, { aiPrompt : "Please fix: {message} | {rerun} | {status}" } ).prompt(
						ctx.failure,
						ctx.results,
						ctx.testbox
					);
					expect( prompt ).toStartWith( "Please fix: " & ctx.failure.message );
					expect( prompt ).toInclude( "./testbox/run --bundles=" );
					expect( prompt ).toInclude( "| Failed" );
				} );

				it( "builds valid JSON for a coding agent", function(){
					var ctx  = failureOf();
					var json = newHelper().agentJSON( ctx.failure );
					expect( isJSON( json ) ).toBeTrue( json );
					var data = deserializeJSON( json );
					expect( data.status ).toBe( "failed" );
					expect( data.bundle ).toBe( ctx.failure.bundle.path );
					expect( data ).toHaveKey( "rerun" );
					expect( data ).toHaveKey( "at" );
				} );
			} );

			describe( "options", function(){
				it( "defaults to Ask AI on with ChatGPT and Claude", function(){
					var options = newHelper().getOptions();
					expect( options.aiAssist ).toBeTrue();
					expect( options.aiProviders ).toHaveLength( 2 );
					expect( options.aiProviders[ 1 ].url ).toInclude( "{prompt}" );
				} );

				it( "can be switched off with an option or the url", function(){
					expect( newHelper( {}, { aiAssist : false } ).getOptions().aiAssist ).toBeFalse();
					expect( newHelper( { aiAssist : "false" } ).getOptions().aiAssist ).toBeFalse();
				} );

				it( "accepts your own providers", function(){
					var providers = [
						{
							id   : "acme",
							name : "Acme",
							url  : "https://ai.acme.test/?p={prompt}"
						}
					];
					var options = newHelper( {}, { aiProviders : providers } ).getOptions();
					expect( options.aiProviders ).toHaveLength( 1 );
					expect( options.aiProviders[ 1 ].name ).toBe( "Acme" );
				} );
			} );

			describe( "safe output helpers", function(){
				it( "reduces ids to safe characters", function(){
					expect( newHelper().safeId( "ab-12_Z'""<>;()" ) ).toBe( "ab-12_Z" );
				} );

				it( "can not be closed by the data inside a script tag", function(){
					var json = newHelper().jsonForHtml( { a : "</script><b>" } );
					expect( json ).notToInclude( "</script>" );
					expect( json ).notToInclude( "<" );
					expect( deserializeJSON( json ).a ).toBe( "</script><b>" );
				} );

				it( "builds a status favicon", function(){
					var helper = newHelper();
					expect( helper.faviconURI( true ) ).toStartWith( "data:image/svg+xml," );
					expect( helper.faviconURI( true ) ).notToBe( helper.faviconURI( false ) );
					expect( helper.faviconURI( true ) ).notToInclude( "<" );
				} );
			} );

			describe( "assets", function(){
				it( "reads an inlined asset", function(){
					expect( newHelper().asset( "css/testbox.css" ) ).toInclude( "--tb-cyan" );
				} );

				it( "throws a named exception for a missing asset", function(){
					expect( function(){
						newHelper().asset( "css/nope.css" );
					} ).toThrow( "TestBox.ReportAssetNotFound" );
				} );

				it( "turns an image into a data uri", function(){
					expect( newHelper().dataURI( "images/testbox-icon.svg" ) ).toStartWith( "data:image/svg+xml;base64," );
				} );
			} );
		} );
	}

}
