/**
 * Guards the vendored front-end assets the HTML reporters inline: they must match their manifest and the pinned versions.
 * To update them: cd build/vendor && npm run update (see build/vendor/README.md)
 */
component extends="testbox.system.BaseSpec" {

	variables.vendorDir = expandPath( "/testbox/system/reports/assets/vendor" );

	function run(){
		describe( "Vendored report assets", function(){
			var manifest = deserializeJSON( fileRead( variables.vendorDir & "/VERSIONS.json" ) );

			it( "ships every file the manifest lists", function(){
				for ( var thisFile in manifest.sha256 ) {
					expect( fileExists( variables.vendorDir & "/" & thisFile ) ).toBeTrue( "#thisFile# is missing" );
				}
			} );

			it( "has files that match their recorded checksums, so nobody edited them by hand", function(){
				for ( var thisFile in manifest.sha256 ) {
					var actual = lCase(
						hash(
							fileRead( variables.vendorDir & "/" & thisFile, "utf-8" ),
							"SHA-256",
							"utf-8"
						)
					);
					expect( actual ).toBe(
						manifest.sha256[ thisFile ],
						"#thisFile# changed. Run npm run build in build/vendor instead of editing it."
					);
				}
			} );

			it( "was built from the versions pinned in build/vendor/package.json", function(){
				var pkg = deserializeJSON( fileRead( expandPath( "/testbox/build/vendor/package.json" ) ) );
				for ( var thisDependency in pkg.dependencies ) {
					expect( manifest.versions ).toHaveKey( thisDependency );
					expect( manifest.versions[ thisDependency ] ).toBe(
						pkg.dependencies[ thisDependency ],
						"#thisDependency# is pinned to #pkg.dependencies[ thisDependency ]# but the vendored build is #manifest.versions[ thisDependency ]#. Run npm run build in build/vendor."
					);
				}
			} );

			it( "contains the libraries it claims to", function(){
				expect(
					reFindNoCase(
						"Bootstrap\s+v" & replace( manifest.versions.bootstrap, ".", "\.", "all" ),
						fileRead( variables.vendorDir & "/bootstrap.min.css", "utf-8" )
					)
				).toBeGT( 0 );
				expect( fileRead( variables.vendorDir & "/alpine.min.js", "utf-8" ) ).toInclude( "Alpine" );
				expect( fileRead( variables.vendorDir & "/prism.min.js", "utf-8" ) ).toInclude( "boxlang" );
				expect( fileRead( variables.vendorDir & "/icons.svg", "utf-8" ) ).toInclude( "id=""i-check-circle-fill""" );
			} );

			it( "defines every icon the templates use", function(){
				var sprite = fileRead( variables.vendorDir & "/icons.svg", "utf-8" );
				var used   = {};
				for (
					var thisFile in directoryList(
						expandPath( "/testbox/system/reports/assets" ),
						true,
						"path",
						"*.cfm"
					)
				) {
					var matches = reMatch( "##i-[a-z0-9-]+", fileRead( thisFile, "utf-8" ) );
					for ( var thisMatch in matches ) {
						used[ replace( thisMatch, "##i-", "" ) ] = true;
					}
				}
				for ( var thisIcon in used ) {
					expect( sprite ).toInclude(
						"id=""i-#thisIcon#""",
						"Icon #thisIcon# is used by a template but missing from build/vendor/icons.txt"
					);
				}
			} );

			it( "records the licenses of what it ships", function(){
				var licenses = fileRead( variables.vendorDir & "/LICENSES.txt", "utf-8" );
				for ( var thisDependency in manifest.versions ) {
					expect( licenses ).toInclude( thisDependency );
				}
			} );
		} );
	}

}
