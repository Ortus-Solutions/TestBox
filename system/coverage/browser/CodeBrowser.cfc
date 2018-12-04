/**
* ********************************************************************************
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ********************************************************************************
* I generate a code browser to see file-level coverage statistics
*/
component accessors=true {
	
	function init() {

		// Classes needed to work.
		variables.coldFish = new ColdFish();
		
		variables.CR = chr( 13 );
		variables.LF = chr( 10 );
		variables.CRLF = CR & LF;
							
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
			if (!directoryExists(getDirectoryFromPath( theFile ))){
				directoryCreate( getDirectoryFromPath( theFile ));
			}
			
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
	function percentToColor( required percentage ) {
		percentage = round( percentage*100 );
		if( percentage >=85 ) {
			return 'green';
		} else if( percentage >=50 ) {
			return 'orange';
		} else {
			return 'red';
		}
	}	
}