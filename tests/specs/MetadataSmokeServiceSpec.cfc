/**
 * Regression tests for Smoke Test helpers (manifest parsing, directory scan, envelope IO, synthetic invoke args).
 */
component extends="testbox.system.BaseSpec" {

	function beforeAll(){
		variables.metaSmokeSvc        = new testbox.system.smoke.MetadataSmokeService();
		variables.fixtureScanRoot     = _metaSmokeFixtureAbs( "resources/metadataSmokeFixtures/scanRoot" );
		variables.fixtureSmokeId      = "tests.resources.metadataSmokeFixtures.SmokeFixture";
		variables.fixtureScanPrefix   = "tests.resources.metadataSmokeFixtures.scanRoot";
		variables.fixtureExcludedById = "tests.resources.metadataSmokeFixtures.scanRoot.ExcludedById";
	}

	private string function _metaSmokeFixtureAbs( required string relativeFromTests ){
		var specDir = getDirectoryFromPath( getCurrentTemplatePath() );
		var f       = createObject( "java", "java.io.File" ).init( specDir & "../" & arguments.relativeFromTests );
		return replace( f.getCanonicalPath(), "\", "/", "all" );
	}

	private string function _tempManifestPath(){
		return getTempDirectory() & "tb-meta-smoke-" & createUUID() & ".json";
	}

	function run(){
		describe( "MetadataSmokeService", function(){
			it( "parseManifestItems accepts legacy array or envelope struct", function(){
				var svc = metaSmokeSvc;
				var a   = svc.parseManifestItems( [ "a.b" ] );
				expect( arrayLen( a ) ).toBe( 1 );
				expect( a[ 1 ] ).toBe( "a.b" );
				var b = svc.parseManifestItems( { "items" : [ "x.y" ] } );
				expect( arrayLen( b ) ).toBe( 1 );
				expect( b[ 1 ] ).toBe( "x.y" );
				expect( arrayLen( svc.parseManifestItems( {} ) ) ).toBe( 0 );
				expect( arrayLen( svc.parseManifestItems( { "items" : "notarray" } ) ) ).toBe( 0 );
			} );

			it( "shouldIgnoreFunction skips init, onMissingMethod, and non-public", function(){
				var svc = metaSmokeSvc;
				expect( svc.shouldIgnoreFunction( { "name" : "init", "access" : "public" } ) ).toBeTrue();
				expect( svc.shouldIgnoreFunction( { "name" : "onMissingMethod", "access" : "public" } ) ).toBeTrue();
				expect( svc.shouldIgnoreFunction( { "name" : "foo", "access" : "private" } ) ).toBeTrue();
				expect( svc.shouldIgnoreFunction( { "name" : "bar", "access" : "public" } ) ).toBeFalse();
			} );

			it( "buildArgsForFunction maps only required parameters to defaultValueForType", function(){
				var svc    = metaSmokeSvc;
				var fnMeta = {
					"parameters" : [
						{ "name" : "reqNum", "required" : true, "type" : "numeric" },
						{ "name" : "optStr", "required" : false, "type" : "string" }
					]
				};
				var args = svc.buildArgsForFunction( fnMeta );
				expect( structCount( args ) ).toBe( 1 );
				expect( args.reqNum ).toBe( 0 );
			} );

			it( "defaultValueForType returns sensible placeholders", function(){
				var svc = metaSmokeSvc;
				expect( svc.defaultValueForType( "numeric" ) ).toBe( 0 );
				expect( svc.defaultValueForType( "boolean" ) ).toBeFalse();
				expect( svc.defaultValueForType( "string" ) ).toBe( "" );
				expect( isArray( svc.defaultValueForType( "array" ) ) ).toBeTrue();
				expect( isStruct( svc.defaultValueForType( "struct" ) ) ).toBeTrue();
				expect( isQuery( svc.defaultValueForType( "query" ) ) ).toBeTrue();
			} );

			it( "runSmokeFromManifestFile fails when manifest path is missing", function(){
				var svc = metaSmokeSvc;
				var r   = svc.runSmokeFromManifestFile(
					getTempDirectory() & "missing-manifest-" & createUUID() & ".json",
					false
				);
				expect( r.success ).toBeFalse();
				expect( r.errorMessage ).toInclude( "Manifest not found" );
			} );

			it( "runSmokeFromManifestFile succeeds with empty manifest array", function(){
				var svc = metaSmokeSvc;
				var p   = _tempManifestPath();
				fileWrite( p, "[]" );
				try {
					var r = svc.runSmokeFromManifestFile( p, false );
					expect( r.success ).toBeTrue();
					expect( r.componentCount ).toBe( 0 );
					expect( r.discovered ).toBe( 0 );
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "runSmokeFromManifestItems matches runSmokeFromManifestFile for a manifest array", function(){
				var svc = metaSmokeSvc;
				var p   = _tempManifestPath();
				fileWrite( p, serializeJSON( [ fixtureSmokeId ] ) );
				try {
					var rFile = svc.runSmokeFromManifestFile( p, false );
					var rMem  = svc.runSmokeFromManifestItems( [ fixtureSmokeId ], false );
					expect( rMem.success ).toBe( rFile.success );
					expect( rMem.componentCount ).toBe( rFile.componentCount );
					expect( rMem.discovered ).toBe( rFile.discovered );
					expect( rMem.attempted ).toBe( rFile.attempted );
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "runSmokeFromManifestItems accepts envelope struct with items", function(){
				var r = metaSmokeSvc.runSmokeFromManifestItems( { "items" : [ fixtureSmokeId ] }, false );
				expect( r.success ).toBeTrue();
				expect( r.componentCount ).toBe( 1 );
				expect( r.discovered ).toBeGT( 0 );
			} );

			it( "runSmokeForSingleComponent processes one path", function(){
				var r = metaSmokeSvc.runSmokeForSingleComponent( fixtureSmokeId, false );
				expect( r.success ).toBeTrue();
				expect( r.componentCount ).toBe( 1 );
				expect( r.discovered ).toBeGT( 0 );
			} );

			it( "runSmokeFromDirectoryInline matches scan count and succeeds for fixture root", function(){
				var svc = metaSmokeSvc;
				var ids = svc.scanDirectoryToManifestItems( fixtureScanRoot, fixtureScanPrefix, {} );
				var r   = svc.runSmokeFromDirectoryInline( fixtureScanRoot, fixtureScanPrefix, {}, false );
				expect( r.success ).toBeTrue();
				expect( r.componentCount ).toBe( arrayLen( ids ) );
				expect( r.discovered ).toBeGT( 0 );
			} );

			it( "runSmokeFromDirectoryInline fails when root directory is missing", function(){
				var r = metaSmokeSvc.runSmokeFromDirectoryInline(
					getTempDirectory() & "tb-meta-missing-" & createUUID(),
					"x.y",
					{},
					false
				);
				expect( r.success ).toBeFalse();
				expect( r.errorMessage ).toInclude( "not found" );
			} );

			it( "runSmokeFromManifestFile discovers public methods for a valid bundle component", function(){
				var svc = metaSmokeSvc;
				var p   = _tempManifestPath();
				fileWrite( p, serializeJSON( [ fixtureSmokeId ] ) );
				try {
					var r = svc.runSmokeFromManifestFile( p, false );
					expect( r.success ).toBeTrue();
					expect( r.componentCount ).toBe( 1 );
					expect( r.discovered ).toBeGT( 0 );
					expect( r.attempted ).toBe( r.discovered );
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "runSmokeFromManifestFile can run dummy invocations when requested", function(){
				var svc = metaSmokeSvc;
				var p   = _tempManifestPath();
				fileWrite( p, serializeJSON( [ fixtureSmokeId ] ) );
				try {
					var r = svc.runSmokeFromManifestFile( p, true );
					expect( r.success ).toBeTrue();
					expect( r.discovered ).toBeGT( 0 );
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "runSmokeFromManifestFile throws when manifest is not valid JSON", function(){
				var svc = metaSmokeSvc;
				var p   = _tempManifestPath();
				fileWrite( p, "{ not json" );
				try {
					expect( function(){
						svc.runSmokeFromManifestFile( p, false );
					} ).toThrow();
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "writeManifestEnvelope writes a readable envelope with items", function(){
				var svc   = metaSmokeSvc;
				var p     = _tempManifestPath();
				var items = [ "a.b", "c.d" ];
				try {
					svc.writeManifestEnvelope(
						p,
						items,
						{ description : "test desc", limitations : [ "one" ] }
					);
					expect( fileExists( p ) ).toBeTrue();
					var raw = deserializeJSON( fileRead( p ) );
					expect( raw.description ).toBe( "test desc" );
					expect( isArray( raw.limitations ) ).toBeTrue();
					expect( raw.limitations[ 1 ] ).toBe( "one" );
					expect( isArray( raw.items ) ).toBeTrue();
					expect( arrayLen( raw.items ) ).toBe( 2 );
					expect( structKeyExists( raw, "generatedAt" ) ).toBeTrue();
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "writeManifestEnvelope uses default description when envelope omits it", function(){
				var svc = metaSmokeSvc;
				var p   = _tempManifestPath();
				try {
					svc.writeManifestEnvelope( p, [ "a.b" ], {} );
					var raw = deserializeJSON( fileRead( p ) );
					expect( raw.description ).toInclude( "Smoke Test" );
					expect( isArray( raw.limitations ) ).toBeTrue();
					expect( arrayLen( raw.limitations ) ).toBe( 0 );
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "resolveManifestAbsolutePath returns empty for blank input", function(){
				expect( metaSmokeSvc.resolveManifestAbsolutePath( "  " ) ).toBe( "" );
			} );

			it( "resolveManifestAbsolutePath returns existing path unchanged", function(){
				var p = _tempManifestPath();
				fileWrite( p, "[]" );
				try {
					expect( metaSmokeSvc.resolveManifestAbsolutePath( p ) ).toBe( p );
				} finally {
					if ( fileExists( p ) ) {
						fileDelete( p );
					}
				}
			} );

			it( "shouldIgnoreFunction skips when name is missing", function(){
				expect( metaSmokeSvc.shouldIgnoreFunction( { "access" : "public" } ) ).toBeTrue();
			} );

			it( "defaultValueForType handles binary and date", function(){
				var svc = metaSmokeSvc;
				expect( isBinary( svc.defaultValueForType( "binary" ) ) ).toBeTrue();
				expect( isDate( svc.defaultValueForType( "date" ) ) ).toBeTrue();
			} );

			it( "scanDirectoryToManifestItems lists all CFCs under root when no excludes", function(){
				var svc = metaSmokeSvc;
				var ids = svc.scanDirectoryToManifestItems( fixtureScanRoot, fixtureScanPrefix, {} );
				expect( arrayLen( ids ) ).toBe( 4 );
				expect( ids ).toInclude( fixtureScanPrefix & ".KeepMe" );
			} );

			it( "scanDirectoryToManifestItems respects excludeFileNames", function(){
				var svc = metaSmokeSvc;
				var ids = svc.scanDirectoryToManifestItems(
					fixtureScanRoot,
					fixtureScanPrefix,
					{ excludeFileNames : "application.cfc" }
				);
				expect( arrayLen( ids ) ).toBe( 3 );
				expect( ids ).toInclude( fixtureScanPrefix & ".KeepMe" );
			} );

			it( "scanDirectoryToManifestItems respects excludeRelativePathPrefixes", function(){
				var svc = metaSmokeSvc;
				var ids = svc.scanDirectoryToManifestItems(
					fixtureScanRoot,
					fixtureScanPrefix,
					{ excludeRelativePathPrefixes : "application" }
				);
				expect( arrayLen( ids ) ).toBe( 3 );
				expect( ids ).notToInclude( fixtureScanPrefix & ".application.IgnoredUnderApplication" );
			} );

			it( "scanDirectoryToManifestItems respects excludeComponentIds", function(){
				var svc = metaSmokeSvc;
				var ids = svc.scanDirectoryToManifestItems(
					fixtureScanRoot,
					fixtureScanPrefix,
					{ excludeComponentIds : fixtureExcludedById }
				);
				expect( ids ).notToInclude( fixtureExcludedById );
				expect( arrayLen( ids ) ).toBe( 3 );
			} );

			it( "TestBox wires getMetadataSmokeService", function(){
				var tb = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				expect( tb.getMetadataSmokeService() ).toBeInstanceOf( "testbox.system.smoke.MetadataSmokeService" );
			} );

			it( "renderRunnerEmbed returns HTML strip for Simple reporter", function(){
				var tb   = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var html = metaSmokeSvc.renderRunnerEmbed( tb, false );
				expect( len( html ) ).toBeGT( 80 );
				expect( html ).toInclude( "Smoke Test" );
				expect( html ).toInclude( "dummy invoke" );
				expect( html ).notToInclude( "<!DOCTYPE html>" );
			} );

			it( "renderRunnerEmbed fullPage true includes document wrapper", function(){
				var tb   = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var html = metaSmokeSvc.renderRunnerEmbed( tb, true );
				expect( html ).toInclude( "<!DOCTYPE html>" );
			} );

			it( "buildSmokeRunnerSummaryFromRequest returns tests and re-run URLs", function(){
				var tb = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var s  = metaSmokeSvc.buildSmokeRunnerSummaryFromRequest( tb, "/tests/specs/m.json", false );
				expect( structKeyExists( s, "testsUrl" ) ).toBeTrue();
				expect( structKeyExists( s, "smokeRunUrl" ) ).toBeTrue();
				expect( structKeyExists( s, "smokeRunUrlWithInvoke" ) ).toBeTrue();
				expect( s.smokeRunUrl ).toInclude( "metadataSmoke=true" );
				expect( s.smokeRunUrl ).toInclude( "metadataSmokeManifest" );
				expect( s.smokeRunUrlWithInvoke ).toInclude( "metadataSmokeInvoke=true" );
				expect( s.smokeRunUrl ).notToInclude( "metadataSmokeInvoke=" );
			} );

			it( "buildSmokeRunnerSummaryFromRequest smokeRunUrl matches smokeRunUrlWithInvoke when invoke already on", function(){
				var tb = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var s  = metaSmokeSvc.buildSmokeRunnerSummaryFromRequest( tb, "/tests/specs/m.json", true );
				expect( s.smokeRunUrl ).toBe( s.smokeRunUrlWithInvoke );
			} );

			it( "buildSmokeRunnerSummaryFromRequest includes metadataSmokeComponent when set", function(){
				var tb = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var s  = metaSmokeSvc.buildSmokeRunnerSummaryFromRequest( tb, "", false, "com.example.Foo" );
				expect( s.smokeRunUrl ).toInclude( "metadataSmokeComponent" );
				expect( s.smokeRunUrl ).toInclude( "com.example.Foo" );
			} );

			it( "buildSmokeRunnerSummaryFromRequest includes exclude URL params when set", function(){
				var tb = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var s  = metaSmokeSvc.buildSmokeRunnerSummaryFromRequest(
					tb,
					"",
					false,
					"",
					"application.cfc",
					"stubs",
					"com.myapp.Skip"
				);
				expect( s.smokeRunUrl ).toInclude( "metadataSmokeExcludeFileNames" );
				expect( s.smokeRunUrl ).toInclude( "metadataSmokeExcludePathPrefixes" );
				expect( s.smokeRunUrl ).toInclude( "metadataSmokeExcludeComponentIds" );
			} );

			it( "renderReport returns HTML with branding", function(){
				var tb   = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var html = metaSmokeSvc.renderReport(
					tb,
					{
						"success"           : true,
						"errorMessage"      : "",
						"componentCount"    : 1,
						"discovered"        : 1,
						"attempted"         : 1,
						"skippedComponents" : []
					},
					[],
					true,
					"/tests/specs/x.json",
					false,
					true
				);
				expect( len( html ) ).toBeGT( 100 );
				expect( html ).toInclude( "Smoke Test" );
			} );
		} );
	}

}
