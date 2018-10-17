/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* Mail Utility library for TestBox
*/
component{

	/**
	* Get the mixer utility object instance. It lazy loads into variables scope for faster execution next time.
	* @return MixerUtil
	*/
	function getMixerUtil(){
		if( structKeyExists( variables, "mixerUtil" ) ){ return variables.mixerUtil; }
		variables.mixerUtil = new MixerUtil();
		return variables.mixerUtil;
	}

	/**
	* Convert an array to struct argument notation
	* @input The array to convert
	*/
	struct function arrayToStruct( required array input ){
		var results = structnew();
		var x       = 1;
		var inLen   = Arraylen( arguments.input );

		for( x=1; x lte inLen; x=x+1 ){
			results[ x ] = arguments.input[ x ];
		}

		return results;
	}

	/**
	* Get the last modified date of a file
	* @filename The target
	*
	* @return date
	*/
	function fileLastModified( required filename ){
		var objFile = createObject( "java", "java.io.File" ).init( javaCast( "string", getAbsolutePath( arguments.filename ) ) );
		// Calculate adjustments fot timezone and daylightsavindtime
		var offset = ( ( getTimeZoneInfo().utcHourOffset ) +1 )*-3600;
		// Date is returned as number of seconds since 1-1-1970
		return dateAdd( 's', ( round( objFile.lastModified() / 1000 ) ) + offset, CreateDateTime( 1970, 1, 1, 0, 0, 0 ) );
	}

	/**
	* Rip an extension of a filename
	* @filename The target
	*/
	string function ripExtension( required filename ){
		return reReplace( arguments.filename, "\.[^.]*$", "" );
	}

	/**
	* Turn any system path, either relative or absolute, into a fully qualified one
	* @path The target
	*/
	string function getAbsolutePath( required path ){
		var fileObj = createObject( "java", "java.io.File" ).init( javaCast( "String", arguments.path ) );
		if( fileObj.isAbsolute() ){
			return arguments.path;
		}
		return expandPath( arguments.path );
	}

	/**
	* Check if you are in cfthread or not for any CFML Engine
	*/
	boolean function inThread(){
		var engine = "ADOBE";

		if ( server.coldfusion.productname eq "Lucee" ){ engine = "LUCEE"; }

		switch( engine ){
			case "ADOBE"	: {
				if( findNoCase( "cfthread", createObject( "java", "java.lang.Thread" ).currentThread().getThreadGroup().getName()) ){
					return true;
				}
				break;
			}

			case "LUCEE"	: {
				return getPageContext().hasFamily();
			}

		} //end switch statement.

		return false;
	}

	/**
	* Create a URL safe slug from a string
	* @str The target
	* @maxLength The maximum number of characters for the slug
	* @allow A regex safe list of additional characters to allow
	*/
	string function slugify( required string str, numeric maxLength=0, string allow="" ){
		// Cleanup and slugify the string
		var slug = lcase( trim( arguments.str ) );

		slug = reReplace( slug, "[^a-z0-9-\s#arguments.allow#]", "", "all" );
		slug = trim ( reReplace( slug, "[\s-]+", " ", "all" ) );
		slug = reReplace( slug, "\s", "-", "all" );

		// is there a max length restriction
		if ( arguments.maxlength ){ slug = left ( slug, arguments.maxlength ); }

		return slug;
	}


	/**
	* Find all methods on a given metadata and it's parents with a given annotation
	* @annotation The annotation name to look for on methods
	* @metadata The metadata to search (recursively) for the provided annotation
	*/
	public array function getAnnotatedMethods(
		required string annotation,
		required struct metadata
	) {
		var lifecycleMethods = [];

		if( structKeyExists( arguments.metadata, "functions" ) ){

			for( var thisFunction in arguments.metadata.functions ){
				if( structKeyExists( thisFunction, annotation ) ){
					arrayAppend( lifecycleMethods, thisFunction );
				}
			}

		}

		if( structKeyExists( arguments.metadata, "extends" ) ){
            arrayEach(
                getAnnotatedMethods(
                    arguments.annotation,
                    arguments.metadata.extends
                ),
                function( item ){
				    arrayAppend( lifecycleMethods, arguments.item );
			    }
            );
		}

		return lifecycleMethods;
	}

}
