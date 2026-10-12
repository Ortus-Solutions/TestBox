/**
 * Build process for bx-testbox: the BoxLang-only artifact of TestBox.
 *
 * It runs `boxlang cftranspile` over `system/`, repairs what the transpiler does not
 * (see fixup()), drops the Lucee and Adobe specific code (see patch()), stages the module
 * descriptor, and zips the result. The CFML source is never modified.
 *
 * Usage (needs BoxLang 1.19+ on the PATH, or BOXLANG_BIN pointing at it, and `box install` already run):
 *   box task run taskfile=build/BuildBx target=run :version=7.2.0 :buildID=1 :branch=development
 *   box task run taskfile=build/BuildBx target=run :verify=true      (also proves the output passes the suite)
 */
component {

	/**
	 * Constructor
	 */
	function init(){
		variables.projectName  = "bx-testbox";
		variables.moduleName   = "testbox";
		variables.minBoxLang   = "1.19.0";
		variables.cwd          = getCWD().reReplace( "[\\/\.]+$", "" );
		variables.artifactsDir = variables.cwd & "/.artifacts";
		variables.buildDir     = variables.cwd & "/.tmp-bx";
		variables.stageDir     = variables.buildDir & "/stage";
		variables.boxlangBin   = resolveBoxLangBin();

		// Classes that only exist for Lucee or Adobe. They are deleted from the transpiled output.
		variables.pruneFiles = [
			"util/LuceeMappingHelper.bx",
			"util/CFMappingHelper.bx",
			"coverage/data/TemplateCompiler_Lucee.bx",
			"coverage/data/TemplateCompiler_Adobe.bx"
		];

		// File types that are text and may carry build tokens
		variables.textExtensions = "bx,bxm,bxs,json,md,txt,xml,html,js,css,properties,yml,yaml";

		return this;
	}

	/**
	 * Run the build process: transpile, fix up, patch, stage, package, checksums
	 *
	 * @version The version you are building
	 * @buildID The build identifier
	 * @branch The branch you are building
	 * @verify Also run the test suite against the output and compare it with the CFML source
	 */
	function run(
		version = "1.0.0",
		buildID = createUUID(),
		branch  = "development",
		boolean verify = false
	){
		say( "Building #variables.projectName# v#arguments.version#+#arguments.buildID# from #variables.cwd# using the #arguments.branch# branch." );

		resetDirs();
		assertPrerequisites();

		transpile();
		fixup( variables.stageDir & "/system" );
		patch( variables.stageDir & "/system" );
		assertOutputIsClean( variables.stageDir & "/system" );
		stageModule( arguments.version, arguments.buildID, arguments.branch );

		if ( arguments.verify ) {
			verifyAgainstSource();
			smokeTestCommandLine();
		}

		var zipPath = packageModule( arguments.version );
		buildChecksums( zipPath );

		say( "Build Process is done! #zipPath#" );
	}

	/**
	 * Transpile system/ and assemble variables.stageDir/system from the transpiled code plus every non-code asset
	 */
	function transpile(){
		var transpiledDir = variables.buildDir & "/transpiled";
		var stageSystem   = variables.stageDir & "/system";

		say( "Transpiling system/ with #variables.boxlangBin# cftranspile ..." );
		directoryCreate( transpiledDir, true, true );
		var result = exec( [
			variables.boxlangBin,
			"cftranspile",
			"--source",
			variables.cwd & "/system",
			"--target",
			transpiledDir,
			"--stopOnError"
		] );
		if ( result.exitCode != 0 || !directoryExists( transpiledDir ) ) {
			throw( type = "BuildBx.TranspileFailed", message = "cftranspile failed", detail = result.output );
		}

		// Assets, BoxLang native files and the installed dependencies come across as they are
		directoryCreate( stageSystem, true, true );
		directoryCopy( variables.cwd & "/system", stageSystem, true );

		// The CFML code is replaced by its transpiled version
		files( stageSystem, "*.cfc|*.cfm" ).each( function( path ){
			fileDelete( path );
		} );
		directoryCopy( transpiledDir, stageSystem, true );
	}

	/**
	 * Repair what `cftranspile` does not do. Each rule is a known gap, so the list should shrink as the transpiler improves.
	 *
	 * - include "x.cfm" string literals are not rewritten to the transpiled .bxm template
	 * - a comment between `else` and `if` leaves a dangling `else` that BoxLang parses as a variable
	 *   (only found in the vendored CFML modules; our own source has none)
	 *
	 * @dir The directory with the transpiled code
	 */
	function fixup( required string dir ){
		say( "Fixing up transpiled output ..." );
		files( arguments.dir, "*.bx" ).each( function( path ){
			var original = fileRead( path, "utf-8" );
			var text     = regexReplace( original, '(?m)^(\s*include\s+"[^"\n]*)\.cfm"', '$1.bxm"' );
			text         = regexReplace( text, '\belse[ \t]*//[^\n]*\n\s*if\b', 'else if' );
			if ( text != original ) {
				fileWrite( path, text, "utf-8" );
			}
		} );
	}

	/**
	 * Remove the Lucee and Adobe specific code from the transpiled output. Every patch asserts that its target
	 * exists exactly once, so the build fails loudly when the CFML source changes under it.
	 *
	 * @dir The directory with the transpiled code
	 */
	function patch( required string dir ){
		say( "Removing Lucee and Adobe specific code ..." );

		// Engine detection in the mapping helper: BoxLang only
		patchFile(
			arguments.dir & "/util/Util.bx",
			'(?s)if \( server\.keyExists\( "boxlang" \) \) \{\s*variables\.ENGINEMAPPINGHELPER = new BoxLangMappingHelper\(\);\s*\} else if \([^\n]*\) \{\s*variables\.ENGINEMAPPINGHELPER = new LuceeMappingHelper\(\);\s*\} else \{\s*variables\.ENGINEMAPPINGHELPER = new CFMappingHelper\(\);\s*\}',
			'variables.ENGINEMAPPINGHELPER = new BoxLangMappingHelper();'
		);

		// Coverage through the Lucee and Adobe template compilers does not exist here, so coverage stays off
		patchFile(
			arguments.dir & "/coverage/data/CoverageGenerator.bx",
			'(?s)// Detect server\s*if \( listFindNoCase\( "Railo,Lucee", server\.COLDFUSION\.PRODUCTNAME \) \) \{\s*variables\.TEMPLATECOMPILER = new TemplateCompiler_Lucee\(\);\s*\} else \{\s*variables\.TEMPLATECOMPILER = new TemplateCompiler_Adobe\(\);\s*\}',
			'// bx-testbox ships no Lucee or Adobe template compilers, so instrumentation based coverage is off' & chr( 10 ) & chr( 9 ) & chr( 9 ) & 'return false;'
		);

		var base = arguments.dir;
		variables.pruneFiles.each( function( relativePath ){
			var target = base & "/" & relativePath;
			if ( !fileExists( target ) ) {
				throw( type = "BuildBx.PruneTargetMissing", message = "Cannot prune #relativePath#: it is not in the transpiled output" );
			}
			fileDelete( target );
		} );
	}

	/**
	 * Fail the build when a known transpiler gap is still in the output. This is the guard that keeps a
	 * regression in `cftranspile` from silently producing a broken module.
	 *
	 * @dir The directory with the transpiled code
	 */
	function assertOutputIsClean( required string dir ){
		var problems = [];
		var base     = arguments.dir;

		// CFML code that did not get transpiled
		files( arguments.dir, "*.cfc|*.cfm" ).each( function( path ){
			problems.append( "untranspiled CFML file: " & relative( base, path ) );
		} );

		var checks = [
			{ name : "@return annotation (BL-2735)", pattern : '(?m)^\s*@return\s*\(' },
			{ name : "script component without bx: prefix (BL-2735)", pattern : '(?m)^\s*(savecontent|application)\s+[a-zA-Z]+\s*=' },
			{ name : "dangling else before a comment", pattern : '\belse[ \t]*//[^\n]*\n\s*if\b' },
			{ name : "include of a .cfm template", pattern : '(?m)^\s*include\s+"[^"\n]*\.cfm"' },
			{ name : "reference to a pruned Lucee or Adobe class", pattern : 'LuceeMappingHelper|CFMappingHelper|TemplateCompiler_(Lucee|Adobe)' }
		];
		files( arguments.dir, "*.bx|*.bxm" ).each( function( path ){
			var text = fileRead( path, "utf-8" );
			checks.each( function( check ){
				if ( regexFind( text, check.pattern ) ) {
					problems.append( check.name & ": " & relative( base, path ) );
				}
			} );
		} );

		if ( problems.len() ) {
			throw(
				type    = "BuildBx.DirtyOutput",
				message = "The transpiled output still has #problems.len()# known problem(s)",
				detail  = problems.toList( chr( 10 ) )
			);
		}
	}

	/**
	 * Add the module descriptor and the package files around the staged system/ folder
	 */
	function stageModule( required version, required buildID, required branch ){
		say( "Staging the module descriptor ..." );

		fileCopy( variables.cwd & "/build/bx-module/ModuleConfig.bx", variables.stageDir & "/ModuleConfig.bx" );
		fileWrite( variables.stageDir & "/box.json", serializeJSON( moduleBoxJson() ), "utf-8" );

		var source = variables.cwd;
		var target = variables.stageDir;
		[ "readme.md", "license.txt", "changelog.md" ].each( function( name ){
			if ( fileExists( source & "/" & name ) ) {
				fileCopy( source & "/" & name, target & "/" & name );
			}
		} );

		// Same token handling as Build.cfc: the build number is only stamped on master
		var numberToken       = ( arguments.branch == "master" ? "@build.number@" : "+@build.number@" );
		var numberReplacement = ( arguments.branch == "master" ? arguments.buildID : "" );
		var versionValue      = arguments.version;
		var textTypes         = variables.textExtensions;
		files( variables.stageDir, "*" ).each( function( path ){
			if ( !fileExists( path ) || !listFindNoCase( textTypes, listLast( path, "." ) ) ) {
				return;
			}
			var original = fileRead( path, "utf-8" );
			if ( !original.find( "@build." ) ) {
				return;
			}
			var text = original.replace( "@build.version@", versionValue, "all" ).replace( numberToken, numberReplacement, "all" );
			fileWrite( path, text, "utf-8" );
		} );
	}

	/**
	 * Run the suite against the CFML source and against the staged output, on this same BoxLang, and require
	 * the same failing and erroring specs. Known failures that exist in both do not break the build; a
	 * transpile that changes behavior does.
	 */
	function verifyAgainstSource(){
		say( "Verifying: running the suite on the CFML source and on the transpiled output ..." );

		// The folder must be called testbox: the reporters tell their own frames apart by a /testbox/system/ path
		var harness = variables.buildDir & "/harness/testbox";
		directoryCreate( harness, true, true );
		directoryCopy( variables.cwd & "/tests", harness & "/tests", true );
		directoryCopy( variables.cwd & "/build/vendor", harness & "/build/vendor", true );
		directoryCopy( variables.stageDir & "/system", harness & "/system", true );

		var onSource = runSuite( variables.cwd );
		var onOutput = runSuite( harness );

		say( "CFML source : #onSource.totals#" );
		say( "Transpiled  : #onOutput.totals#" );

		var onlyInOutput = onOutput.failing.filter( function( s ){
			return !arrayFind( onSource.failing, s );
		} );
		var onlyInSource = onSource.failing.filter( function( s ){
			return !arrayFind( onOutput.failing, s );
		} );
		if ( onlyInOutput.len() || onlyInSource.len() ) {
			throw(
				type    = "BuildBx.VerificationFailed",
				message = "The transpiled output does not behave like the CFML source",
				detail  = "Failing only after the transpile:" & chr( 10 ) & onlyInOutput.toList( chr( 10 ) ) & chr( 10 ) & "Failing only in the source:" & chr( 10 ) & onlyInSource.toList( chr( 10 ) )
			);
		}
		say( "Verified: both runs have the same #onSource.failing.len()# failing or erroring spec(s)." );
	}

	/**
	 * Install the staged module in a scratch project the way install-bx-module does (a folder named after the
	 * slug) and drive the `testbox` command: the commands, the exit codes, and the order of flags over the
	 * .boxlang.json of the project over the module defaults.
	 */
	function smokeTestCommandLine(){
		say( "Smoke test: running the testbox command from the installed module ..." );

		var project = variables.buildDir & "/smoke";
		directoryCreate( project & "/tests/specs", true, true );
		directoryCreate( project & "/specs/alt", true, true );
		directoryCopy( variables.stageDir, project & "/boxlang_modules/bx-testbox", true );

		var spec = function( required string name, required string value ){
			return 'class extends="testbox.system.BaseSpec" { function run(){ describe( "smoke", () => { it( "works", () => { expect( 1 ).toBe( #arguments.value# ) } ) } ) } }';
		};
		fileWrite( project & "/tests/specs/PassTest.bx", spec( "PassTest", "1" ), "utf-8" );
		fileWrite( project & "/tests/specs/FailTest.bx", spec( "FailTest", "2" ), "utf-8" );
		fileWrite( project & "/specs/alt/AltTest.bx", spec( "AltTest", "1" ), "utf-8" );
		var config = project & "/.boxlang.json";

		var cases = [
			{ name : "version", args : [ "version" ], exit : 0, has : "TestBox " },
			{ name : "help", args : [ "help" ], exit : 0, has : "Usage: testbox" },
			{ name : "no command shows the help", args : [], exit : 0, has : "Usage: testbox" },
			{ name : "unknown command", args : [ "bogus" ], exit : 1, has : "Unknown command" },
			{ name : "a passing bundle", args : [ "run", "tests.specs.PassTest" ], exit : 0, has : "Passed: 1" },
			{ name : "a failing bundle exits 1", args : [ "run", "tests.specs.FailTest" ], exit : 1, has : "Failed: 1" },
			{ name : "--no-fail-on-error", args : [ "run", "--bundles=tests.specs.FailTest", "--no-fail-on-error" ], exit : 0, has : "Failed: 1" },
			// .boxlang.json changes the defaults of the project
			{
				name   : ".boxlang.json sets directory, reporter and failOnError",
				config : { directory : "specs.alt", reporter : "json", failOnError : false },
				args   : [ "run" ],
				exit   : 0,
				has    : [ '"bundleStats"', "specs.alt.AltTest" ]
			},
			{
				name   : "a flag beats .boxlang.json (reporter)",
				config : { directory : "specs.alt", reporter : "json" },
				args   : [ "run", "--reporter=console" ],
				exit   : 0,
				has    : [ "Passed: 1" ],
				hasNot : [ '"bundleStats"' ]
			},
			{
				name   : "a flag beats .boxlang.json (failOnError)",
				config : { failOnError : false },
				args   : [ "run", "--bundles=tests.specs.FailTest", "--fail-on-error" ],
				exit   : 1,
				has    : [ "Failed: 1" ]
			}
		];

		var failures = [];
		for ( var thisCase in cases ) {
			if ( fileExists( config ) ) {
				fileDelete( config );
			}
			if ( structKeyExists( thisCase, "config" ) ) {
				fileWrite( config, serializeJSON( { "modules" : { "testbox" : { "settings" : thisCase.config } } } ), "utf-8" );
			}
			var result = exec( [ variables.boxlangBin, "module:testbox" ].append( thisCase.args, true ), project );
			// plain text to search: no colors, and the columns of the console reporter squeezed to single spaces
			var output = regexReplace( regexReplace( result.output, '\x1b\[[0-9;]*m', '' ), '[ \t]+', ' ' );
			var wanted = isArray( thisCase.has ) ? thisCase.has : [ thisCase.has ];
			var problems = [];
			if ( result.exitCode != thisCase.exit ) {
				problems.append( "exit code #result.exitCode#, expected #thisCase.exit#" );
			}
			for ( var text in wanted ) {
				if ( !findNoCase( text, output ) ) {
					problems.append( "the output has no [#text#]" );
				}
			}
			for ( var text in ( thisCase.hasNot ?: [] ) ) {
				if ( findNoCase( text, output ) ) {
					problems.append( "the output has [#text#]" );
				}
			}
			if ( problems.len() ) {
				failures.append( "#thisCase.name#: " & problems.toList( "; " ) );
			}
			say( "  #problems.len() ? 'FAIL' : 'ok  '# #thisCase.name#" );
		}

		if ( failures.len() ) {
			throw(
				type    = "BuildBx.SmokeTestFailed",
				message = "#failures.len()# command line check(s) failed on the installed module",
				detail  = failures.toList( chr( 10 ) )
			);
		}
	}

	/************************************* PRIVATE HELPERS *************************************/

	/**
	 * Run the BoxLang runner for a root folder and return its totals plus the sorted failing and erroring specs
	 */
	private struct function runSuite( required string root ){
		var result = exec(
			[
				variables.boxlangBin,
				arguments.root & "/system/runners/BoxLangRunner.bx",
				"--directory=tests.specs",
				"--reporter=json",
				"--write-report=false"
			],
			arguments.root
		);

		// Specs print to the console before the report, so find where the JSON starts
		var start = result.output.find( '{"bundleStats"' );
		if ( !start ) {
			start = result.output.find( '{"' );
		}
		if ( !start ) {
			throw( type = "BuildBx.NoReport", message = "The runner in #arguments.root# produced no JSON report", detail = result.output.left( 2000 ) );
		}
		var report  = deserializeJSON( result.output.mid( start, result.output.len() ) );
		var failing = [];
		report.bundleStats.each( function( bundle ){
			collectFailures( bundle.suiteStats, listLast( bundle.path, "." ), failing );
		} );
		failing.sort( "text" );

		return {
			failing : failing,
			totals  : "#report.totalPass# passed, #report.totalFail# failed, #report.totalError# errors, #report.totalSkipped# skipped"
		};
	}

	private function collectFailures( required array suites, required string bundle, required array failing ){
		arguments.suites.each( function( suite ){
			suite.specStats.each( function( spec ){
				if ( listFindNoCase( "failed,error", spec.status ) ) {
					failing.append( "#bundle# | #suite.name# | #spec.name# | #lCase( spec.status )#" );
				}
			} );
			collectFailures( suite.suiteStats, bundle, failing );
		} );
	}

	/**
	 * The module package descriptor, derived from the root box.json so the shared metadata has one source
	 */
	private struct function moduleBoxJson(){
		var source = deserializeJSON( fileRead( variables.cwd & "/box.json", "utf-8" ) );
		var result = {
			"name"             : "TestBox for BoxLang",
			"version"          : "@build.version@+@build.number@",
			"author"           : source.author,
			"slug"             : variables.projectName,
			"type"             : "boxlang-modules",
			"keywords"         : "testing,xunit,bdd,testbox,tdd,boxlang",
			"homepage"         : source.homepage,
			"documentation"    : source.documentation,
			"repository"       : source.repository,
			"bugs"             : source.bugs,
			"shortDescription" : "TestBox for BoxLang: a BDD and xUnit testing framework with mocking goodness",
			"license"          : source.license,
			"contributors"     : source.contributors,
			"location"         : "forgeboxStorage",
			"boxlang"          : {
				"minimumVersion" : variables.minBoxLang,
				"moduleName"     : variables.moduleName,
				// install-bx-module creates a `testbox` command that runs `boxlang module:testbox`
				"executable"     : "testbox"
			},
			"ignore" : [ "**/.*" ]
		};
		return result;
	}

	private function resetDirs(){
		[ variables.buildDir, variables.artifactsDir & "/" & variables.projectName ].each( function( item ){
			if ( directoryExists( item ) ) {
				directoryDelete( item, true );
			}
			directoryCreate( item, true, true );
		} );
		directoryCreate( variables.stageDir, true, true );
	}

	/**
	 * Fail early, with a clear message, when the build cannot work
	 */
	private function assertPrerequisites(){
		var result = exec( [ variables.boxlangBin, "--version" ] );
		var found  = reFind( "v(\d+)\.(\d+)\.(\d+)", result.output, 1, true );
		if ( result.exitCode != 0 || found.pos.len() < 4 ) {
			throw( type = "BuildBx.NoBoxLang", message = "Cannot run '#variables.boxlangBin# --version'. Put BoxLang #variables.minBoxLang#+ on the PATH or set BOXLANG_BIN.", detail = result.output );
		}
		var current = [ 2, 3, 4 ].map( function( i ){
			return val( result.output.mid( found.pos[ i ], found.len[ i ] ) );
		} );
		var wanted = variables.minBoxLang.listToArray( "." ).map( function( n ){
			return val( n );
		} );
		for ( var i = 1; i <= 3; i++ ) {
			if ( current[ i ] > wanted[ i ] ) {
				break;
			}
			if ( current[ i ] < wanted[ i ] ) {
				throw(
					type    = "BuildBx.BoxLangTooOld",
					message = "BoxLang #variables.minBoxLang#+ is required: it is the first with the cftranspile fixes BL-2735 and BL-2736.",
					detail  = result.output
				);
			}
		}

		if ( !fileExists( variables.cwd & "/system/modules/globber/models/PathPatternMatcher.cfc" ) ) {
			throw( type = "BuildBx.DependenciesMissing", message = "system/modules is empty. Run `box install` before building." );
		}
	}

	private string function packageModule( required version ){
		var destination = variables.artifactsDir & "/#variables.projectName#/#arguments.version#";
		directoryCreate( destination, true, true );
		var zipPath = destination & "/#variables.projectName#-#arguments.version#.zip";
		say( "Zipping module to #zipPath#" );
		cfzip(
			action    = "zip",
			file      = zipPath,
			source    = variables.stageDir,
			overwrite = true,
			recurse   = true
		);
		fileCopy( variables.stageDir & "/box.json", destination );
		return zipPath;
	}

	private function buildChecksums( required zipPath ){
		var bytes = fileReadBinary( arguments.zipPath );
		fileWrite( arguments.zipPath & ".sha512", hash( bytes, "SHA-512" ).lCase(), "utf-8" );
		fileWrite( arguments.zipPath & ".md5", hash( bytes, "MD5" ).lCase(), "utf-8" );
	}

	/**
	 * Run a process and return its exit code and merged output
	 */
	private struct function exec( required array command, string workingDir = variables.cwd ){
		var builder = createObject( "java", "java.lang.ProcessBuilder" ).init( arguments.command );
		builder.directory( createObject( "java", "java.io.File" ).init( arguments.workingDir ) );
		builder.redirectErrorStream( true );
		var process = builder.start();
		var reader  = createObject( "java", "java.io.BufferedReader" ).init(
			createObject( "java", "java.io.InputStreamReader" ).init( process.getInputStream(), "UTF-8" )
		);
		var out  = createObject( "java", "java.lang.StringBuilder" ).init();
		var line = reader.readLine();
		while ( !isNull( line ) ) {
			out.append( line ).append( chr( 10 ) );
			line = reader.readLine();
		}
		process.waitFor();
		return { exitCode : process.exitValue(), output : out.toString() };
	}

	private function resolveBoxLangBin(){
		var fromEnv = createObject( "java", "java.lang.System" ).getenv( "BOXLANG_BIN" );
		return ( isNull( fromEnv ) || !len( fromEnv ) ) ? "boxlang" : fromEnv;
	}

	/**
	 * Regex helpers on java.util.regex so every engine behaves the same ($1 style replacements)
	 */
	private string function regexReplace( required string text, required string pattern, required string replacement ){
		return createObject( "java", "java.util.regex.Pattern" )
			.compile( arguments.pattern )
			.matcher( arguments.text )
			.replaceAll( arguments.replacement );
	}

	private boolean function regexFind( required string text, required string pattern ){
		return createObject( "java", "java.util.regex.Pattern" ).compile( arguments.pattern ).matcher( arguments.text ).find();
	}

	/**
	 * Replace exactly one match in a file, or fail the build
	 */
	private function patchFile( required string path, required string pattern, required string replacement ){
		if ( !fileExists( arguments.path ) ) {
			throw( type = "BuildBx.PatchTargetMissing", message = "Cannot patch #arguments.path#: the file is not in the transpiled output" );
		}
		var text    = fileRead( arguments.path, "utf-8" );
		var matcher = createObject( "java", "java.util.regex.Pattern" ).compile( arguments.pattern ).matcher( text );
		var matches = 0;
		while ( matcher.find() ) {
			matches++;
		}
		if ( matches != 1 ) {
			throw(
				type    = "BuildBx.PatchFailed",
				message = "Expected exactly 1 match in #arguments.path# but found #matches#. The CFML source or the transpiler changed; update patch() in build/BuildBx.cfc.",
				detail  = arguments.pattern
			);
		}
		fileWrite(
			arguments.path,
			regexReplace( text, arguments.pattern, createObject( "java", "java.util.regex.Matcher" ).quoteReplacement( arguments.replacement ) ),
			"utf-8"
		);
	}

	/**
	 * Recursive file list with a `|` separated filter such as *.cfc|*.cfm
	 */
	private array function files( required string dir, string filter = "*" ){
		return directoryList( arguments.dir, true, "path", arguments.filter );
	}

	private string function relative( required string base, required string path ){
		return replace( arguments.path, arguments.base, "" );
	}

	private function say( required string message ){
		if ( structKeyExists( variables, "print" ) ) {
			print.line( arguments.message ).toConsole();
		} else {
			writeOutput( arguments.message & chr( 10 ) );
		}
	}

}
