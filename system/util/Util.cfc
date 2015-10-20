<!-----------------------------------------------------------------------
********************************************************************************
Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************

Author     :	Luis Majano
Description :
	The main ColdBox utility library.
----------------------------------------------------------------------->
<cfcomponent output="false" hint="The main ColdBox utility library filled with lots of nice goodies.">

	<!--- getMixerUtil --->
    <cffunction name="getMixerUtil" output="false" access="public" returntype="any" hint="Get the mixer utility">
    	<cfscript>
    		if( structKeyExists(variables, "mixerUtil") ){ return variables.mixerUtil; }
			variables.mixerUtil = createObject("component","MixerUtil").init();
			return variables.mixerUtil;
		</cfscript>
    </cffunction>

	<!--- arrayToStruct --->
	<cffunction name="arrayToStruct" output="false" access="public" returntype="struct" hint="Convert an array to struct argument notation">
		<cfargument name="in" type="array" required="true" hint="The array to convert"/>
		<cfscript>
			var results = structnew();
			var x       = 1;
			var inLen   = Arraylen(arguments.in);

			for(x=1; x lte inLen; x=x+1){
				results[x] = arguments.in[x];
			}

			return results;
		</cfscript>
	</cffunction>

	<!--- fileLastModified --->
	<cffunction name="fileLastModified" access="public" returntype="string" output="false" hint="Get the last modified date of a file">
		<cfargument name="filename" required="true">
		<cfscript>
		var objFile =  createObject("java","java.io.File").init(javaCast("string", getAbsolutePath( arguments.filename ) ));
		// Calculate adjustments fot timezone and daylightsavindtime
		var offset = ((getTimeZoneInfo().utcHourOffset)+1)*-3600;
		// Date is returned as number of seconds since 1-1-1970
		return dateAdd('s', (round(objFile.lastModified()/1000))+offset, CreateDateTime(1970, 1, 1, 0, 0, 0));
		</cfscript>
	</cffunction>

	<!--- ripExtension --->
	<cffunction name="ripExtension" access="public" returntype="string" output="false" hint="Rip the extension of a filename.">
		<cfargument name="filename" required="true">
		<cfreturn reReplace(arguments.filename,"\.[^.]*$","")>
	</cffunction>

	<!--- getAbsolutePath --->
	<cffunction name="getAbsolutePath" access="public" output="false" returntype="string" hint="Turn any system path, either relative or absolute, into a fully qualified one">
		<cfargument name="path" required="true">
		<cfscript>
			var fileObj = createObject("java","java.io.File").init(javaCast("String",arguments.path));
			if(fileObj.isAbsolute()){
				return arguments.path;
			}
			return expandPath(arguments.path);
		</cfscript>
	</cffunction>

	<!--- inThread --->
	<cffunction name="inThread" output="false" access="public" returntype="boolean" hint="Check if you are in cfthread or not for any CFML Engine">
		<cfscript>
			var engine = "ADOBE";

			if ( server.coldfusion.productname eq "Lucee" ){ engine = "LUCEE"; }

			switch(engine){
				case "ADOBE"	: {
					if( findNoCase("cfthread",createObject("java","java.lang.Thread").currentThread().getThreadGroup().getName()) ){
						return true;
					}
					break;
				}

				case "LUCEE"	: {
					return getPageContext().hasFamily();
				}

			} //end switch statement.

			return false;
		</cfscript>
	</cffunction>

	<!--- slugify --->
	<cffunction name="slugify" output="false" access="public" returntype="string" hint="Create a URL safe slug from a string">
		<cfargument name="str" 			type="string" 	required="true" hint="The string to slugify"/>
		<cfargument name="maxLength" 	type="numeric" 	required="false" default="0" hint="The maximum number of characters for the slug"/>
		<cfargument name="allow" type="string" required="false" default="" hint="a regex safe list of additional characters to allow"/>
		<cfscript>
			// Cleanup and slugify the string
			var slug = lcase(trim(arguments.str));

			slug = reReplace(slug,"[^a-z0-9-\s#arguments.allow#]","","all");
			slug = trim ( reReplace(slug,"[\s-]+", " ", "all") );
			slug = reReplace(slug,"\s", "-", "all");

			// is there a max length restriction
			if ( arguments.maxlength ) {slug = left ( slug, arguments.maxlength );}

			return slug;
		</cfscript>
	</cffunction>

</cfcomponent>