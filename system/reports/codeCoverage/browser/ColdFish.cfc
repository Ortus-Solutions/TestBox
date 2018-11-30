<!---
	Copyright 2008 Jason Delmore
    All rights reserved.
    jason@delmore.info
	
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License (LGPL) as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License	
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	--->
<cfcomponent output="false" singleton>
	<cffunction name="init" access="public" hint="This function initializes all of the variables needed for the component." output="false">
		<cfargument name="file" default="#getDirectoryFromPath(getCurrentTemplatePath()) & "coldfishconfig.xml"#" required="false"/><!--- assumes config file is in same directory --->
		<cfset variables.cache = querynew("codesignature, code, created")/>
		<cfset setConfig(createObject("component", "coldfishconfig").init(arguments.file))/>
        <cfreturn this/>
    </cffunction>
	
	<cffunction name="formatString" access="public" hint="This function accepts a block of code and formats it into syntax highlighted HTML." output="false">
    	<cfargument name="code" type="string"/>
		<cfargument name="type" type="string" default=""/>
		<cfargument name="lineNumberDefaultBG" type="string">
		<cfargument name="lineNumbersStyles" type="struct"/>
		<cfscript>
			var codesig = hash(arguments.code & getConfig().getInstanceData().toString());
			var parser = "";
			var HTMLOutput = "";
			var cacheitem = getFromCache(codesig);
			if (cacheitem.recordcount) {
				return cacheitem.code;
			} else {
				formatter = createObject("component", "formatter").init();
				formatter.setConfig(variables.coldfishconfig);
				HTMLOutput = formatter.getHTMLOutput(arguments.code,arguments.type,codesig,lineNumberDefaultBG,lineNumbersStyles);
				return putInCache(codesig,HTMLOutput.toString());
			} 
        </cfscript>
	</cffunction>
	<cffunction name="formatFile" access="public" hint="This function accepts a file path, reads in the file and formats it into syntax highlighted HTML." output="false">
    	<cfargument name="filePath" type="string"/>
		<cfargument name="type" type="string" default="#getConfig().getInitialParser()#"/>
		<cfargument name="lineNumberDefaultBG" type="string">
		<cfargument name="lineNumbersStyles" type="struct"/>
        <cfset var fileRead = "">
        <cffile action="read" file="#arguments.filepath#" variable="fileRead">
        <cfreturn formatString(fileRead,type,lineNumberDefaultBG,lineNumbersStyles)/>
	</cffunction>
	<cffunction name="getCache" access="public" hint="This function returns everything stored in the cache." output="false">
		<cfreturn variables.cache/>
    </cffunction>
	<cffunction name="putInCache" access="private" hint="This function returns everything stored in the cache." output="false">
		<cfargument name="codesig" type="string"/>
		<cfargument name="code" type="string"/>
		<cfset var now = now()/>
		<cfset queryaddrow(variables.cache)/>
		<cfset querysetcell(variables.cache, "codesignature", arguments.codesig)/>
		<cfset querysetcell(variables.cache, "code", arguments.code)/>
		<cfset querysetcell(variables.cache, "created", now)/>
		<cfif variables.cache.recordcount gte getConfig().getCachesize()>
			<cfquery dbtype="query" name="variables.cache" maxrows="#getConfig().getCachesize()#">
				select		*
				from		[variables].cache
				order by	created asc
			</cfquery>
			<!--- implement cache set --->
		</cfif>
		<cfreturn code/>
    </cffunction>
	<cffunction name="getFromCache" access="private" hint="This function returns everything stored in the cache." output="false">
		<cfargument name="codesig" type="string"/>
		<cfset var check_cache = ""/>
		<cfquery dbtype="query" name="check_cache" maxrows="1">
			select	*
			from	[variables].cache
			where	codesignature = '#arguments.codesig#'
		</cfquery>
		
		<cfreturn check_cache/>
    </cffunction>
	<cffunction name="setConfig" access="public" hint="This sets the coldfish configuration object for the parser to use." output="false">
    	<cfargument name="config" type="any"/>
		<cfset variables.coldfishconfig = config/>
    </cffunction>
	<cffunction name="getConfig" access="public" hint="This sets the coldfish configuration object for the parser to use." output="false">
    	<cfargument name="config" type="any"/>
		<cfreturn variables.coldfishconfig/>
    </cffunction>
	<cffunction name="setStyle" access="public" hint="This function can be used to set the style used in conjunction with a type of language element.  The value submitted should be a valid CSS black; (i.e. 'color:black;background-color:yellow;')" output="false">
    	<cfargument name="element" type="string"/>
        <cfargument name="style" type="string"/>
        <cfset getConfig().setStyle(arguments.element,arguments.style)/>
    </cffunction>
	<cffunction name="getStyle" access="private" hint="This function can be used to get the style used in conjunction with a type of language element." output="false">
    	<cfargument name="element" type="string"/>
		<cfreturn getConfig().getStyle(element)/>
    </cffunction>
	<cffunction name="getStyles" access="public" hint="This function returns all of the styles used for each type of language element." output="false">
		<cfreturn getConfig().getStyles()/>
    </cffunction>
	<cffunction name="getInitialParser" access="private" hint="You can get the initial parser state with this.  This is helpful for scripts that make initial parsing impossible (ie. SQL, CFScript, Actionscript)" output="false">
		<cfreturn getConfig().getInitialParser()/>
    </cffunction>
	<cffunction name="setInitialParser" access="public" hint="You can set the initial parser state with this.  This is helpful for scripts that make initial parsing impossible (ie. SQL, CFScript, Actionscript)" output="false">
		<cfargument name="initialparser" type="string"/>
		<cfreturn getConfig().setInitialParser(initialparser)/>
    </cffunction>
	<cffunction name="getKeywordmap" access="public" hint="You can set the keywordmap with this." output="false">
		<cfreturn getConfig().getKeywordMap()/>
    </cffunction>
	<cffunction name="setUseLineNumbers" access="public" hint="Sets whether or not to use line numbers" output="false">
		<cfargument name="useLineNumbers" type="Boolean"/>
		<cfset getConfig().setUseLineNumbers(arguments.useLineNumbers)/>
    </cffunction>
</cfcomponent>