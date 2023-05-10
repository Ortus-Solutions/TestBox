/**
 * Build process for TestBox
 */
component{

    /**
     * Constructor
     */
    function init(){
		// Setup Global Variables
		variables.projectName = "testbox";
		variables.cwd          = getCWD().reReplace( "\.$", "" );
		variables.artifactsDir = cwd & "/.artifacts";
		variables.buildDir     = cwd & "/.tmp";

        // Source Excludes Not Added to final binary
        variables.excludes      = [
            "build",
			"server-.*\.json",
            "tests\/results",
            "^\..*"
        ];

        // Cleanup + Init Build Directories
		[
			variables.buildDir,
			variables.artifactsDir
		].each( function( item ){
			if ( directoryExists( item ) ) {
                directoryDelete( item, true );
            }
            // Create directories
            directoryCreate( item, true, true );
		} );

		// Create Mappings
		fileSystemUtil.createMapping(
			"testbox",
			variables.cwd
		);

        return this;
    }

    /**
     * Run the build process: test, build source, docs, checksums
     *
     * @projectName The project name used for resources and slugs
     * @version The version you are building
     * @buldID The build identifier
     * @branch The branch you are building
     */
    function run(
        version = "1.0.0",
		buildID = createUUID(),
		branch  = "development"
    ){

        // Build the source
		buildSource( argumentCollection = arguments );

        // Build Docs
        arguments.outputDir = variables.buildDir & "/apidocs";
		docs( argumentCollection = arguments );

        // checksums
		buildChecksums();

        // Finalize Message
		print
			.line()
			.boldWhiteOnGreenLine( "Build Process is done! Enjoy your build!" )
            .toConsole();
    }

    /**
	 * Run all the tests
     */
    function runTests(){
		var resultsDir = "tests/results";

		print.blueLine( "Testing the package, please wait...#resultsDir#" ).toConsole();
		directoryCreate( variables.cwd & resultsDir, true, true );

		command( "testbox run" )
            .params(
				verbose    = true,
				outputFile = resultsDir & "/test-results",
				outputFormats="json,antjunit"
            )
            .run();
    }

    /**
     * Build the source
	 *
	 * @projectName The project name used for resources and slugs
     * @version The version you are building
     * @buldID The build identifier
     * @branch The branch you are building
     */
    function buildSource(
        version = "1.0.0",
		buildID = createUUID(),
		branch  = "development"
    ){
        // Build Notice ID
		print
			.line()
			.boldMagentaLine(
				"Building #variables.projectName# v#arguments.version#+#arguments.buildID# from #cwd# using the #arguments.branch# branch."
			)
            .toConsole();

		ensureExportDir( argumentCollection = arguments );

        // Project Build Dir
		variables.projectBuildDir = variables.buildDir & "/#variables.projectName#";
		directoryCreate(
			variables.projectBuildDir,
			true,
			true
		);

        // Copy source
        print.blueLine( "Copying source to build folder..." ).toConsole();
		copy(
			variables.cwd,
			variables.projectBuildDir
		);

        // Create build ID
		fileWrite(
			"#variables.projectBuildDir#/#variables.projectName#-#version#+#buildID#.md",
			"Built with ❤️ love ❤️ on #dateTimeFormat( now(), "full" )#"
		);

        // Updating Placeholders
        print.greenLine( "Updating version identifier to #arguments.version#" ).toConsole();
		command( "tokenReplace" )
            .params(
				path        = "/#variables.projectBuildDir#/**",
				token       = "@build.version@",
                replacement = arguments.version
            )
            .run();

        print.greenLine( "Updating build identifier to #arguments.buildID#" ).toConsole();
		command( "tokenReplace" )
            .params(
				path        = "/#variables.projectBuildDir#/**",
				token       = ( arguments.branch == "master" ? "@build.number@" : "+@build.number@" ),
                replacement = ( arguments.branch == "master" ? arguments.buildID : "-snapshot" )
            )
            .run();

        // zip up source
		var destination = "#variables.exportsDir#/#variables.projectName#-#version#.zip";
        print.greenLine( "Zipping code to #destination#" ).toConsole();
        cfzip(
			action    = "zip",
			file      = "#destination#",
			source    = "#variables.projectBuildDir#",
			overwrite = true,
			recurse   = true
        );

        // Copy box.json for convenience
		fileCopy(
			"#variables.projectBuildDir#/box.json",
			variables.exportsDir
		);

		// Copy BE to root
		fileCopy(
			"#variables.projectBuildDir#/box.json",
			variables.artifactsDir & "/#variables.projectName#"
		);
		fileCopy(
			destination,
			variables.artifactsDir & "/#variables.projectName#/testbox-be.zip"
		);
		command( "checksum" )
			.params(
				path      = variables.artifactsDir & "/#variables.projectName#/testbox-be.zip",
				algorithm = "md5",
				extension = "md5",
				write     = true
			)
			.run();
    }

    /**
     * Produce the API Docs
     */
	function docs(
		version   = "1.0.0",
		outputDir = "#variables.cwd#.tmp/apidocs"
	){
        // Generate Docs
        print.greenLine( "Generating API Docs, please wait..." ).toConsole();
        directoryCreate( arguments.outputDir, true, true );
		command( "docbox generate" )
            .params(
				"source"                = "/testbox/system",
				"mapping"               = "testbox.system",
				"excludes"  			= "(stubs)",
				"strategy-projectTitle" = "#variables.projectName# v#arguments.version#",
				"strategy-outputDir"    = arguments.outputDir
            )
            .run();

        print.greenLine( "API Docs produced at #arguments.outputDir#" ).toConsole();

		ensureExportDir( argumentCollection = arguments );
		var docsArchivePath = "#variables.exportsDir#/#variables.projectName#-docs-#arguments.version#.zip";
		print.greenLine( "Zipping apidocs to #docsArchivePath#" ).toConsole();
        cfzip(
			action    = "zip",
			file      = "#docsArchivePath#",
			source    = "#arguments.outputDir#",
			overwrite = true,
			recurse   = true
        );
	}

    /********************************************* PRIVATE HELPERS *********************************************/

    /**
     * Build Checksums
     */
    private function buildChecksums(){
        print.greenLine( "Building checksums" ).toConsole();
		command( "checksum" )
			.params(
				path      = "#variables.exportsDir#/*.zip",
				algorithm = "SHA-512",
				extension = "sha512",
				write     = true
			)
            .run();
		command( "checksum" )
			.params(
				path      = "#variables.exportsDir#/*.zip",
				algorithm = "md5",
				extension = "md5",
				write     = true
			)
            .run();
    }

    /**
     * DirectoryCopy is broken in lucee
     */
	private function copy( src, target, recurse = true ){
        // process paths with excludes
		directoryList(
			src,
			false,
			"path",
			function( path ){
            var isExcluded = false;
            variables.excludes.each( function( item ){
					if ( path.replaceNoCase( variables.cwd, "", "all" ).reFindNoCase( item ) ) {
                    isExcluded = true;
                }
            } );
            return !isExcluded;
			}
		).each( function( item ){
            // Copy to target
			if ( fileExists( item ) ) {
                print.blueLine( "Copying #item#" ).toConsole();
                fileCopy( item, target );
            } else {
                print.greenLine( "Copying directory #item#" ).toConsole();
				directoryCopy(
					item,
					target & "/" & item.replace( src, "" ),
					true
				);
            }
        } );
    }

	/**
	 * Ensure the export directory exists at artifacts/NAME/VERSION/
	 */
	private function ensureExportDir(
		version   = "1.0.0"
	){
		if ( structKeyExists( variables, "exportsDir" ) && directoryExists( variables.exportsDir ) ){
			return;
		}
		// Prepare exports directory
		variables.exportsDir = variables.artifactsDir & "/#projectName#/#arguments.version#";
		directoryCreate( variables.exportsDir, true, true );
	}
}
