/**
* ********************************************************************************
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ********************************************************************************
* I generate a code browser to see file-level coverage statistics
*/
component accessors=true {

	function init( required struct coverageTresholds ) {
		variables.coverageTresholds = arguments.coverageTresholds;
		return this;
	}

	/**
	* @qryCoverageData A query object containing coverage data
	* @stats A struct of overview stats
	* @browserOutputDir Generation folder for code browser
	*/
	function generateBrowser(
		required query qryCoverageData,
		required struct stats,
		required string browserOutputDir
	) {

		var assetDir = "/testbox/system/reports/assets";
		// wipe old files
		if( directoryExists( browserOutputDir ) ) {
			try {
				directoryDelete( browserOutputDir, true );
			} catch ( Any e ) {
				// Windows can get cranky if explorer or something has a lock on a folder while you try to delete
				rethrow;
			}
		}

		// Create it fresh
		if( !directoryExists( browserOutputDir ) ) {
			directoryCreate( browserOutputDir );
			fileCopy("#assetDir#/js/syntaxhighlighter.js", browserOutputDir);
			fileCopy("#assetDir#/js/bootstrap.min.js", browserOutputDir);
			fileCopy("#assetDir#/js/jquery-3.3.1.min.js", browserOutputDir);
			fileCopy("#assetDir#/js/popper.min.js", browserOutputDir);
			fileCopy("#assetDir#/css/syntaxhighlighter.css", browserOutputDir);
			fileCopy("#assetDir#/css/bootstrap.min.css", browserOutputDir);
			fileCopy("#assetDir#/css/fontawesome.css", browserOutputDir);
		}

		// Create index
		savecontent variable="local.index" {
			include "templates/index.cfm";
		}
		fileWrite( browserOutputDir & '/index.html', local.index );

		// Created individual files
		for( var fileData in qryCoverageData ) {
			// Coverage files are named after "real" files
			var theFile = "#browserOutputDir & fileData.relativeFilePath#.html";
			var fileDir = getDirectoryFromPath( theFile );
			if (!directoryExists(fileDir)){
				directoryCreate(fileDir);
				fileCopy("#assetDir#/js/syntaxhighlighter.js", fileDir);
				fileCopy("#assetDir#/js/bootstrap.min.js", fileDir);
				fileCopy("#assetDir#/js/jquery-3.3.1.min.js", fileDir);
				fileCopy("#assetDir#/js/popper.min.js", fileDir);
				fileCopy("#assetDir#/css/syntaxhighlighter.css", fileDir);
				fileCopy("#assetDir#/css/bootstrap.min.css", fileDir);
				fileCopy("#assetDir#/css/fontawesome.css", fileDir);
			}

			var lineNumbersBGColors = structMap( filedata.lineData, function( key, value,strct ){
				return ( value > 0 ) ? "success" : "danger";
			});
			var percentage = round( fileData.percCoverage*100 )

			var lineNumbersBGColorsJSON = SerializeJSON(lineNumbersBGColors);
			var fileContents = fileRead( fileData.filePath );
			fileContents = replaceNoCase(fileContents, "</script>", "&lt;/script&gt;", "ALL");

			savecontent variable="local.fileTemplate" {
				include "templates/file.cfm";
			}
			fileWrite( theFile, local.fileTemplate );

		}

	}

	/**
	* visually reward or shame the user
	* TODO: add more variations of color
	*/
	function percentToContextualClass( required percentage ) {
		percentage = percentage;
		if( percentage > coverageTresholds.bad && percentage < coverageTresholds.good ) {
			return 'warning';
		} else if( percentage >= coverageTresholds.good ) {
			return 'success';
		} else if( percentage <= coverageTresholds.bad ) {
			return 'danger';
		}
	}
}