/**
 * Renders the HTML reporters (Simple, Min, Dot, Doc) from real runs and checks what every one of them promises:
 * a complete page, no external resources, escaped output, the verdict, themes and the Ask AI options.
 */
component extends="testbox.system.BaseSpec" {

	variables.mixed   = "tests.resources.reporters.MixedBundle";
	variables.passing = "tests.resources.reporters.PassingBundle";

	variables.reporters = [
		{
			name : "Simple",
			cfc  : "testbox.system.reports.SimpleReporter"
		},
		{ name : "Min", cfc : "testbox.system.reports.MinReporter" },
		{ name : "Dot", cfc : "testbox.system.reports.DotReporter" },
		{ name : "Doc", cfc : "testbox.system.reports.DocReporter" }
	];

	/**
	 * Run a fixture bundle and render it with a reporter
	 *
	 * @bundle  One or more fixture bundle paths
	 * @cfc     The reporter class
	 * @options The reporter options
	 */
	private string function runReporter(
		required string bundle,
		required string cfc,
		struct options = {}
	){
		return new testbox.system.TestBox(
			bundles  = arguments.bundle,
			reporter = { type : arguments.cfc, options : arguments.options }
		).run();
	}

	/**
	 * Render with the request params a web run would have had (there is no url scope in a headless run)
	 */
	private string function renderWithUrl(
		required string bundle,
		required string cfc,
		required struct params,
		struct options = {}
	){
		var merged       = duplicate( arguments.options );
		merged.urlParams = arguments.params;
		return runReporter( arguments.bundle, arguments.cfc, merged );
	}

	/**
	 * Count the occurrences of a string
	 */
	private numeric function occurrences( required string haystack, required string needle ){
		return arrayLen(
			arguments.haystack.split(
				reReplace(
					arguments.needle,
					"([\\.\[\]\(\)\*\+\?\^\$\|\{\}])",
					"\\\1",
					"all"
				),
				-1
			)
		) - 1;
	}

	function run(){
		describe( "HTML reporters", function(){
			for ( var thisReporter in variables.reporters ) {
				// the loop variable is shared by the closures below
				(
					function( reporter ){
						describe( "#reporter.name# reporter", function(){
							it( "returns one complete html page", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								expect( trim( html ) ).toStartWith( "<!DOCTYPE html>" );
								expect( html ).toInclude( "<html lang=""en""" );
								expect( html ).toInclude( "name=""viewport""" );
								expect( html ).toInclude( "</html>" );
								expect( occurrences( html, "<!DOCTYPE" ) ).toBe( 1 );
							} );

							it( "ignores the old fullPage switch, a report is always a full page", function(){
								var html = renderWithUrl(
									variables.mixed,
									reporter.cfc,
									{ fullPage : "false" }
								);
								expect( trim( html ) ).toStartWith( "<!DOCTYPE html>" );
							} );

							it( "is airgapped: nothing is loaded from the network", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								expect( reFindNoCase( "<link[^>]+href=""(?!data:)", html ) ).toBe(
									0,
									"no stylesheet or icon links to the network"
								);
								expect( reFindNoCase( "<script[^>]+src=", html ) ).toBe( 0, "no script files" );
								expect(
									reFindNoCase( "<(img|iframe|source|video|audio)[^>]+src=""https?:", html )
								).toBe( 0, "no remote media" );
								expect( reFindNoCase( "@import", html ) ).toBe( 0 );
								expect( reFindNoCase( "url\(\s*['""]?https?:", html ) ).toBe( 0 );
							} );

							it( "inlines Bootstrap, Alpine and the TestBox styles", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								expect( reFindNoCase( "Bootstrap\s+v5", html ) ).toBeGT( 0 );
								expect( html ).toInclude( "tbReport" );
								expect( html ).toInclude( "--tb-cyan" );
								expect( html ).toInclude( "x-data=""tbReport""" );
							} );

							it( "supports light and dark themes", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								expect( html ).toInclude( "data-bs-theme=""light""" );
								expect( html ).toInclude( "data-bs-theme=""dark""" );
								expect( html ).toInclude( "testbox-theme" );
								expect( html ).toInclude( "setTheme( 'dark' )" );
								expect( html ).toInclude( "tb-logo--light" );
								expect( html ).toInclude( "tb-logo--dark" );
							} );

							it( "shows a red verdict with the counts when something failed", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								expect( html ).toInclude( "class=""tb-verdict tb-verdict--bad""" );
								expect( html ).toInclude( "2 failures, 1 error" );
								expect( html ).toInclude( "FAILED 3" );
							} );

							it( "shows a green verdict when everything passed", function(){
								var html = runReporter( variables.passing, reporter.cfc );
								expect( html ).toInclude( "class=""tb-verdict tb-verdict--good""" );
								expect( html ).toInclude( "All 1 spec passed" );
								expect( html ).toInclude( "PASSED 1" );
								expect( html ).notToInclude( "class=""tb-verdict" & " tb-verdict--bad""" );
							} );

							it( "offers filters by status in the verdict", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								for ( var thisStatus in [ "passed", "failed", "error", "skipped" ] ) {
									expect( html ).toInclude( "toggleStatus( '#thisStatus#' )" );
								}
							} );

							it( "escapes everything that comes from a spec", function(){
								var html = runReporter( "tests.resources.reporters.EscapingBundle", reporter.cfc );
								expect( html ).notToInclude( "<img src=x one" & "rror=alert(1)>" );
								expect( html ).notToInclude( "<script>alert(" & "'xss')</script>" );
								expect( html ).notToInclude( "<b>Sui" & "te</b>" );
								expect( html ).toInclude( "&lt;img" );
							} );

							it( "says a bundle exception happened and turns the verdict red", function(){
								var html = runReporter( "tests.specsWithFailures.BeforeAllFailures", reporter.cfc );
								expect( html ).toInclude( "class=""alert tb-exception" );
								expect( html ).toInclude( "could not run" );
								expect( html ).toInclude( "class=""tb-verdict tb-verdict--bad""" );
							} );

							it( "links back to the runner for a bundle, carrying labels and excludes", function(){
								var html = renderWithUrl(
									variables.mixed,
									reporter.cfc,
									{
										labels    : "smoke",
										excludes  : "slow",
										directory : "tests.specs"
									}
								);
								expect( html ).toInclude( "testBundles=tests.resources.reporters.MixedBundle" );
								expect( html ).toInclude( "labels=smoke" );
								expect( html ).toInclude( "excludes=slow" );
								expect( html ).toInclude( "directory=tests.specs" );
								expect( html ).notToInclude( "opt_run=true" );
							} );

							it( "puts the Ask AI payloads and providers on the page by default", function(){
								var html = runReporter( variables.mixed, reporter.cfc );
								expect( html ).toInclude( "Copy all failures for AI" );
								expect( occurrences( html, "<template data-prompt=" ) ).toBe( 3 );
								expect( occurrences( html, "<template data-agent=" ) ).toBe( 3 );
								expect( html ).toInclude( "https://chatgpt.com/?q={prompt}" );
								expect( html ).toInclude( "https://claude.ai/new?q={prompt}" );
							} );

							it( "removes Ask AI with aiAssist=false", function(){
								var html = runReporter(
									variables.mixed,
									reporter.cfc,
									{ aiAssist : false }
								);
								expect( html ).notToInclude( "aria-haspop" & "up=""menu""" );
								expect( html ).notToInclude( "<template d" & "ata-prompt=" );
								expect( html ).notToInclude( "Copy all fai" & "lures for AI" );
								// built from parts: on Lucee the page quotes source lines of the stack frames, which include this file
								expect( html ).notToInclude( "chat" & "gpt.com" );
							} );

							it( "uses your own AI providers", function(){
								var html = runReporter(
									variables.mixed,
									reporter.cfc,
									{
										aiProviders : [
											{
												id   : "acme",
												name : "Acme AI",
												url  : "https://ai.acme.test/?p={prompt}"
											}
										]
									}
								);
								expect( html ).toInclude( "ai.acme.test" );
								// built from parts: on Lucee the page quotes source lines of the stack frames, which include this file
								expect( html ).notToInclude( "chat" & "gpt.com" );
							} );
						} );
					}
				)( thisReporter );
			}

			describe( "Simple reporter", function(){
				it( "lists failures first, then every bundle with its suites and specs", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.SimpleReporter" );
					expect( html ).toInclude( "Needs attention" );
					expect( occurrences( html, "class=""card tb-failure""" ) ).toBe( 3 );
					expect( occurrences( html, "data-spec data-status=" ) ).toBe( 0 );
					expect( occurrences( html, "tb-spec""" ) ).toBeGTE( 0 );
					expect( html ).toInclude( "class=""tb-spec""" );
					expect( html ).toInclude( "tb-suite-list" );
				} );

				it( "starts bundles with trouble open and the others collapsed", function(){
					var html = runReporter(
						"tests.resources.reporters.MixedBundle,tests.resources.reporters.PassingBundle",
						"testbox.system.reports.SimpleReporter"
					);
					var config = deserializeJSON(
						reReplace(
							html,
							"(?s).*<script type=""application/json"" id=""tb-config"">(.*?)</script>.*",
							"\1"
						)
					);
					var states = structKeyList( config.bundles )
						.listToArray()
						.map( function( id ){
							return config.bundles[ id ];
						} );
					var opened = states.filter( function( state ){
						return state;
					} );
					// at least one bundle starts open and at least one starts collapsed
					expect( arrayLen( opened ) ).toBeGT( 0 );
					expect( arrayLen( opened ) ).toBeLT( arrayLen( states ) );
				} );

				it( "uses semantic landmarks and aria", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.SimpleReporter" );
					expect( html ).toInclude( "<main>" );
					expect( html ).toInclude( "<header" );
					expect( html ).toInclude( "role=""status""" );
					expect( html ).toInclude( "aria-expanded" );
					expect( html ).toInclude( "aria-labelledby" );
					expect( html ).toInclude( "<h1" );
				} );

				it( "shows the debug stream of a bundle", function(){
					var html = runReporter(
						"tests.resources.reporters.DebugBundle",
						"testbox.system.reports.SimpleReporter"
					);
					expect( html ).toInclude( "Debug stream (1)" );
					expect( html ).toInclude( "The answer" );
				} );

				it( "opens the failing file in the editor chosen with url.editor", function(){
					var html = renderWithUrl(
						variables.mixed,
						"testbox.system.reports.SimpleReporter",
						{ editor : "idea" }
					);
					// some engines entity-encode the url characters inside the attribute, the browser decodes them
					expect( reFindNoCase( "idea(://|&##x3a;&##x2f;&##x2f;)open", html ) ).toBeGT( 0 );
				} );
			} );

			describe( "Min reporter", function(){
				it( "lists one line per failure and leaves out the specs that passed", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.MinReporter" );
					expect( html ).toInclude( "class=""list-group tb-min-failures""" );
					expect( html ).notToInclude( "class=""" & "tb-spec""" );
				} );
			} );

			describe( "Dot reporter", function(){
				it( "draws a dot per spec and a drawer for the details", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.DotReporter" );
					expect( occurrences( html, "class=""tb-dot""" ) ).toBe( 6 );
					expect( html ).toInclude( "class=""offcanvas offcanvas-end tb-drawer""" );
					expect( html ).toInclude( "role=""dialog""" );
					expect( occurrences( html, "<template data-panel=" ) ).toBe( 3 );
				} );

				it( "marks each dot with its status and a run link", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.DotReporter" );
					expect( html ).toInclude( "data-status=""failed""" );
					expect( html ).toInclude( "data-status=""error""" );
					expect( html ).toInclude( "data-status=""skipped""" );
					expect( html ).toInclude( "data-run-url=" );
				} );
			} );

			describe( "Doc reporter", function(){
				it( "reads as a document: sections, headings and description lists", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.DocReporter" );
					expect( html ).toInclude( "<article>" );
					expect( html ).toInclude( "<dl>" );
					expect( html ).toInclude( "<dt>" );
					expect( html ).toInclude( "aria-label=""Bundles""" );
					expect( html ).toInclude( "<h2 id=""bundle-title-" );
					expect( html ).toInclude( "<h3 id=""suite-" );
				} );

				it( "nests headings with the nesting of the suites", function(){
					var html = runReporter( variables.mixed, "testbox.system.reports.DocReporter" );
					expect( html ).toInclude( "<h4 id=""suite-" );
				} );
			} );
		} );
	}

}
