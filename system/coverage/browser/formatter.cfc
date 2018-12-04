<!---
	Copyright 2009 Jason Delmore
    All rights reserved.
    jason@cfinsider.com
	
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
<cfcomponent output="false">
	<cffunction name="init" access="public" hint="This function initializes all of the variables needed for the component." output="false">
		<cfscript>
			//initialize a buffer
				
			// If you're using JDK 1.5 or later and want some extra performance this can be a StringBuilder
			//variables.buffer=createObject("java","java.lang.StringBuilder").init();
			variables.buffer=createObject("java","java.lang.StringBuffer").init();
			
			// initialize private variables
			// TODO : Change the parser state to be a struct rather than individual variables.
			variables.isCommented=false;
			variables.isTag=false;
			variables.isValue=false;
			variables.isCFSETTag=false;
			variables.isCFScript=false;
			variables.isCFQueryTag=false;
			variables.isOneLineComment=false;
			variables.isMXML=false;
			variables.isActionscript=false;
			variables.isSQL=false;
			variables.isSQLValue=false;
			variables.initialparser="";
			variables.spansOpened = 0;
			variables.spansClosed = 0;
		</cfscript>
        <cfreturn this/>
    </cffunction>
    
	<cffunction name="getHTMLOutput" access="public" hint="This function accepts a block of code and formats it into syntax highlighted HTML." output="false">
    <cfargument name="code" type="string"/>
		<cfargument name="parser" type="string"/>
		<cfargument name="codesig" type="string"/>
		<cfargument name="lineNumberDefaultBG" type="string" default = "LINENUMBERBGSECONDARY">
		<cfargument name="lineNumbersStyles" type="struct" default={}/>
		<cfscript>
            var BIstream = createObject("java","java.io.StringBufferInputStream").init(arguments.code);
            var IStream = createObject("java","java.io.InputStreamReader").init(BIstream);
            var reader = createObject("java","java.io.BufferedReader").init(IStream);
            var line = reader.readLine();
			var linenumber = 0;
			
			if (arguments.parser neq "") {
				"variables.is#arguments.parser#" = true;
			}
			
			if (getConfig().getShowToolbar()) {
				getToolbarHTML(arguments.code,arguments.codesig);			
			}
			
			variables.buffer.append("<span id='formatted_code_" & arguments.codesig & "' style='" & getStyle("TEXT") & "'>");
			while (isdefined("line")) {
				if (getConfig().getShowLineNumbers()) {
					linenumber = linenumber + 1;
					var lineNumberBG = arguments.lineNumberDefaultBG;
					if (structKeyExists(lineNumbersStyles, linenumber)) {
						lineNumberBG = lineNumbersStyles[linenumber];
					}
          variables.buffer.append("<span style='" & getStyle("LINENUMBER") & getStyle(lineNumberBG) & "'>" & linenumber & "</span>");
				}
				formatLine(line);
                line = reader.readLine();
            }
			// there appears to be more spans created than cleaned up... closing up any extras... will need to review to see what is keeping extra spans
			while (variables.spansOpened gt variables.spansClosed) {
				variables.spansClosed = variables.spansClosed + 1;
				variables.buffer.append("</span>");
			}
			variables.buffer.append("</span>");
			reader.close();

            return variables.buffer;
        </cfscript>
	</cffunction>
	
	<cffunction name="getToolbarHTML" access="private" output="false">
		<cfargument name="code" type="string"/>
		<cfargument name="codesig" type="string"/>
		<cfset variables.buffer.append("
			<iframe id='print_frame_#arguments.codesig#' style='display:inline;height:0px;width:0px;' frameborder='0'></iframe>
			<script type='text/javascript'>
				function toggle_view_#arguments.codesig#() {
					var temp = document.getElementById('htmlencoded_plain_#arguments.codesig#').style.display;
					document.getElementById('htmlencoded_plain_#arguments.codesig#').style.display=document.getElementById('formatted_code_#arguments.codesig#').style.display;
					document.getElementById('formatted_code_#arguments.codesig#').style.display=temp;
					if (temp=='none') {
						document.getElementById('view_#arguments.codesig#').innerHTML='formatted';
					} else {
						document.getElementById('view_#arguments.codesig#').innerHTML='view plain';
					}
				}
				function copy_to_clipboard_#arguments.codesig#() {
					var code=unescape(document.getElementById('htmlencoded_plain_#arguments.codesig#').innerHTML).replace(/&lt;/g, '\x3C').replace(/&gt;/g, '\x3E').replace(/&amp;/g, '\x26').replace(/\x3Cbr\x3E/gi, '\r\n').replace(new RegExp('&nbsp;&nbsp;&nbsp;&nbsp;', 'gi'), '\t');
					window.clipboardData.setData('text',code);
				}
				function print_#arguments.codesig#() {
					document.getElementById('print_frame_#arguments.codesig#').contentWindow.document.body.innerHTML = document.getElementById('formatted_code_#arguments.codesig#').innerHTML;
					document.getElementById('print_frame_#arguments.codesig#').contentWindow.focus();
					document.getElementById('print_frame_#arguments.codesig#').contentWindow.print();
				}
				function show_about_#arguments.codesig#() {
					document.getElementById('about_#arguments.codesig#').style.display='block';
					window.setTimeout('hide_about_#arguments.codesig#();', 4000);
				}
				function hide_about_#arguments.codesig#() {
					document.getElementById('about_#arguments.codesig#').style.display='none';
				}
			</script>
			<div style='#getStyle("TOOLBAR")#'>
				<!--- Toggle code view --->
				<a href='javascript:toggle_view_#arguments.codesig#()' style='#getStyle("TOOLBARLINK")#;' id='view_#arguments.codesig#'>view plain</a>
				
				<!--- Copy to clipboard --->
				<a href='javascript:copy_to_clipboard_#arguments.codesig#()' style='display:none;#getStyle("TOOLBARLINK")#' id='view_copy_to_clipboard_link_#arguments.codesig#'>copy to clipboard</a>
				<!--- The cross-browser copy to clipboard methods out there are hacky and only work on certain browsers... if the browser handles it, then the link show up... --->
				<script type='text/javascript'>if(window.clipboardData) { document.getElementById('view_copy_to_clipboard_link_#arguments.codesig#').style.display='inline';}</script>
				
				<!--- Print --->
				<a href='javascript:print_#arguments.codesig#()' style='#getStyle("TOOLBARLINK")#'>print</a>
				
				<!--- About --->
				<a href='javascript:show_about_#arguments.codesig#()' style='#getStyle("TOOLBARLINK")#'>about</a>
				<span id='about_#arguments.codesig#' style=';display:none;font-style:italic;'><a href='http://coldfish.riaforge.org/' style='#getStyle("TOOLBARLINK")#;margin:0 0 0 0;' target='_blank'>ColdFISH</a> is developed by <a href='http://www.cfinsider.com/' style='#getStyle("TOOLBARLINK")#;margin:0 0 0 0;' target='_blank'>Jason Delmore</a>.  Source code and license information available at <a href='http://coldfish.riaforge.org/' style='#getStyle("TOOLBARLINK")#;margin:0 0 0 0;' target='_blank'>coldfish.riaforge.org</a>.  Version 3.1.1</span>
			</div>	
			<pre id='htmlencoded_plain_#arguments.codesig#' style='display:none;#getStyle("TEXT")#;margin:0 0 0 0;'>#htmleditformat(arguments.code)#</pre>
		")/>
	</cffunction>
	
	<cffunction name="formatLine" access="private" hint="This function takes a single line of code and formats it into syntax highlighted HTML." output="false">
    	<cfargument name="line" type="any"/>
        <cfscript>
			var character = "";
			var thisLine=arguments.line;
			var i = 0;
			var endtagPos = 0;
			var startAttributePos = 0;
			var keywordskip = 0;

			
			if (variables.isOneLineComment) endOneLineComment();
			
			for (i=0; i LT thisLine.length(); i=i+1)
			{
				character=thisLine.charAt(javacast('int',i));
				if (character EQ '<')
				{
					if (variables.isCFScript AND NOT variables.isValue)
						endCFScript();
					if (regionMatches(thisLine, 1, i+1, "!--", 0, 3))
					{
						if (regionMatches(thisLine, 1, i+4, "-", 0, 1))
						{
							startComment("CF");
						} else {
							startComment("HTML");
						}
					} else {
						if (regionMatches(thisLine, 1, i+1, "CF", 0, 2) OR regionMatches(thisLine, 1, i+1, "/CF", 0, 3))
						{
							startTag("CF");
							if (regionMatches(thisLine, 1, i+3, "SET", 0, 3) AND NOT regionMatches(thisLine, 1, i+6, "T", 0, 1)) // CFSET Tag
							{
								variables.buffer.append(thisLine.substring(javacast('int',i+1), javacast('int',i+6)));
								i=i+5;
								startCFSET();
							}
							else if (regionMatches(thisLine, 1, i+3, "SCRIPT>", 0, 6)) // CFSCRIPT TAG
							{
								variables.buffer.append(thisLine.substring(javacast('int',i+1), javacast('int',i+9)) & "&gt;");
								i=i+9;
								startCFScript();
							}
							else if (regionMatches(thisLine, 1, i+3, "QUERY", 0, 5)) // START CFQUERY TAG
							{	// TODO: This sets the value color immediately to match SQL values including the CFQuery tag...
								variables.isCFQueryTag = true;
							} else if (regionMatches(thisLine, 1, i+4, "QUERY", 0, 5)) // END CFQUERY TAG
							{
								variables.isCFQueryTag = false;
								endSQL();
							}
						}
						else if	(
								 	regionMatches(thisLine, 1, i+1, "TA", 0, 2) OR
									regionMatches(thisLine, 1, i+1, "/TA", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "TB", 0, 2) OR
									regionMatches(thisLine, 1, i+1, "/TB", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "TD", 0, 2) OR
									regionMatches(thisLine, 1, i+1, "/TD", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "TF", 0, 2) OR
									regionMatches(thisLine, 1, i+1, "/TF", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "TH", 0, 2) OR
									regionMatches(thisLine, 1, i+1, "/TH", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "TR", 0, 2) OR
									regionMatches(thisLine, 1, i+1, "/TR", 0, 3)
								) // HTML TABLE
						{
							startTag("HTMLTABLES");
						}
						else if (regionMatches(thisLine, 1, i+1, "IMG", 0, 3) OR regionMatches(thisLine, 1, i+1, "STY", 0, 3) OR regionMatches(thisLine, 1, i+1, "/STY", 0, 4)) //IMG or STYLE Tag
						// TODO: Do separate syntax highlighting for stuff inside style
						{
							startTag("HTMLSTYLES");
						}
						else if (
									regionMatches(thisLine, 1, i+1, "FORM", 0, 4) OR
									regionMatches(thisLine, 1, i+1, "/FORM", 0, 5) OR
									regionMatches(thisLine, 1, i+1, "INPUT", 0, 5) OR
									regionMatches(thisLine, 1, i+1, "/INPUT", 0, 5) OR
									regionMatches(thisLine, 1, i+1, "TEXT", 0, 4) OR
									regionMatches(thisLine, 1, i+1, "/TEXT", 0, 5) OR
									regionMatches(thisLine, 1, i+1, "SELECT", 0, 6) OR
									regionMatches(thisLine, 1, i+1, "/SELECT", 0, 7) OR
									regionMatches(thisLine, 1, i+1, "OPT", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "/OPT", 0, 3)
								)
						{
							startTag("HTMLFORMS");
						}
						else if (
								 	regionMatches(thisLine, 1, i+1, "MX:", 0, 3) OR
									regionMatches(thisLine, 1, i+1, "/MX:", 0, 4)
								)
						{
							if (regionMatches(thisLine, 1, i+4, "SCRIPT>", 0, 6)) // MX:SCRIPT TAG
							{
								startTag("ACTIONSCRIPTTAG");
								variables.buffer.append(thisLine.substring(javacast('int',i+1), javacast('int',i+10)) & "&gt;");
								i=i+10;
								startActionscript();
							} else if (regionMatches(thisLine, 1, i+5, "SCRIPT>", 0, 6)) // END MX:SCRIPT TAG
							{
								endActionscript();
								startTag("ACTIONSCRIPTTAG");
								variables.buffer.append(thisLine.substring(javacast('int',i+1), javacast('int',i+11)));
								i=i+12;
								endTag();
							} else {
								startTag("MXML");
								startAttributePos=find(' ',thisLine,i+1); //start finding the next space from current position
								endtagPos=find('>',thisLine,i+1); //start finding the end tag from current position
								if (startAttributePos neq 0) {  // start attribute colors
									variables.buffer.append(thisLine.substring(javacast('int',i+1), javacast('int',startAttributePos)));
									i=startAttributePos-1;
									startMXMLTag();
								} else {
									if (endtagPos neq 0) { // found >
										variables.buffer.append(thisLine.substring(javacast('int',i+1), javacast('int',endtagPos-1)));
										i=i+endtagPos;
										variables.buffer.append("&gt;");
										endHighlight();
									}
								}	
							}
						} else {
							if (variables.isActionscript or variables.isSQL) {
								variables.buffer.append("&lt;");
							} else {
								startTag("HTML");
							}
						}
					}
				}
				else if (character EQ '>')
				{
					if (variables.isCommented AND regionMatches(thisLine, 1, i-2, "--", 0, 2))
					{
						if (regionMatches(thisLine, 1, i-3, "-", 0, 1))
						{
							endComment("CF");
						} else {
							endComment("HTML");
						}
					} else {
						if (variables.isCFSETTag) {
							endCFSET();
						} else if (variables.isActionscript) {
							//This is where a CDATA for AS ends
							variables.buffer.append("&gt;");
						} else if (variables.isSQL) {
							variables.buffer.append("&gt;");
						} else if (variables.isCFQueryTag) {
							endTag();
							startSQL();
						} else if (variables.isMXML) {
							endMXMLTag();
						} else {
							endTag();
						}
					}
				}
				else if (character EQ '"')
				{
					if (variables.isTag OR variables.isCFScript OR variables.isActionscript)
					{
						if (NOT variables.isValue) {
							startValue();
							variables.buffer.append('"');
						} else {
							variables.buffer.append('"');
							endValue();
						}
					} else {
						variables.buffer.append('"');
					}
				}
				else if (character EQ '{')
				{
					startBind();
					variables.buffer.append("{");
					endBind();
				}
				else if (character EQ '}')
				{
					startBind();
					variables.buffer.append("}");
					endBind();
				}
				else if (character EQ '/')
				{
					if ((variables.isCFScript OR variables.isActionscript) AND regionMatches(thisLine, 1, i+1, "/", 0, 1) AND NOT variables.isCommented)
					{
						if (variables.isActionscript) {
							startOneLineComment("MXMLCOMMENT");
							variables.buffer.append("/");
						} else {
							startOneLineComment("HTMLCOMMENT");
							variables.buffer.append("/");
						}
					}
					else if (variables.isCommented)
					{
						if (regionMatches(thisLine, 1, i-1, "*", 0, 1))
						{
							endComment("SCRIPT");
						} else {
							variables.buffer.append("/");
						}
					} else {
						if (regionMatches(thisLine, 1, i+1, "*", 0, 1))
						{
							startComment("SCRIPT");
						} else {
							variables.buffer.append("/");
						}
					}
				}
				else if (variables.isSQL AND character EQ '-')
				{
					if (regionMatches(thisLine, 1, i+1, "-", 0, 1) AND NOT variables.isCommented)
					{
						startOneLineComment("SQLCOMMENT");
						variables.buffer.append("-");
					} else {
						variables.buffer.append("-");
					}
				}
				else if (variables.isSQL AND character EQ "'" AND NOT variables.isCommented)
				{
					if (NOT variables.isValue) {
						startValue();
						variables.buffer.append("'");
					} else {
						variables.buffer.append("'");
						endValue();
					}
				}

				// straight up replacements
				else if (character EQ '\t' OR character EQ '	')
				{
					variables.buffer.append("&nbsp;&nbsp;&nbsp;&nbsp;");
				}
				else if (character EQ ' ')
				{
					variables.buffer.append("&nbsp;");
				}
				else if (character EQ '&')
				{
					if (regionMatches(thisLine, 1, i+1, "##", 0, 1)) {
						variables.buffer.append("&");
					} else {
						variables.buffer.append("&amp;");
					}
				} else {
					if (not variables.isCommented AND not variables.isValue and (i eq 0 OR NOT listcontainsnocase('a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,@', thisLine.substring(javacast('int',i-1),javacast('int',i))))) {
						keywordskip = 0;
						// would like this to be much more generic rather than checking "is"
						if (variables.isActionscript) {
							keywordskip = keywordsearch(thisLine,i,"Actionscript");
						} else if (variables.isCFscript or variables.isCFSetTag) {
							keywordskip = keywordsearch(thisLine,i,"CFscript");
						} else if (variables.isSQL) {
							keywordskip = keywordsearch(thisLine,i,"sql");
						}
						if (keywordskip) {
							i = i + keywordskip;
						} else {
							variables.buffer.append(character.toString());
						}
					} else {
						variables.buffer.append(character.toString());
					}
				}
			}
			variables.buffer.append("<br />");
		</cfscript>
    </cffunction>
	<cffunction name="keywordsearch" access="private" hint="This function searches for keywords." output="false">
    <cfargument name="thisLine" type="any"/>
    <cfargument name="i" type="numeric"/>
		<cfargument name="parser" type="string"/>
    
		<cfset var keywordmap = getConfig().getKeywordmap()/>
		<cfset var words = thisLine.substring(javacast('int',i)).split('[\s(]')/>

		<cfif ArrayLen(words) GT 0>
			<cfset var keyword = words[1]/> <!--- search starting from current position --->
			<cfset var findkey = StructFindKey(keywordmap[parser], keyword)/>
			<cfset var keywordtype = ""/>
			
			<cfif arraylen(findkey)>
				<cfset keywordtype = findkey[1].value/>
				<cfset variables.buffer.append("<span style='" & getStyle(keywordtype) & "'>" & keyword & "</span>")/>
				<cfreturn keyword.length()-1/>
			</cfif>
		</cfif>

    <cfreturn 0/>
  </cffunction>
	<cffunction name="regionMatches" access="private" hint="This function checks if a regionMatches." output="false">
		<cfargument name="string1" type="any"/>
        <cfargument name="caseInsensitive" type="boolean" default="true"/>
        <cfargument name="startPosition1" type="numeric"/>
        <cfargument name="string2" type="any"/>
        <cfargument name="startPosition2" type="numeric"/>
        <cfargument name="endPosition2" type="numeric"/>
		<cfreturn arguments.string1.regionMatches(arguments.caseInsensitive, javacast('int',arguments.startPosition1), arguments.string2, javacast('int',arguments.startPosition2), javacast('int',arguments.endPosition2))/>
    </cffunction>
    <cffunction name="startHighlight" access="private" hint="" output="false">
    	<cfargument name="element" type="string"/>
		<cfset variables.spansOpened = variables.spansOpened + 1/>
		<cfset variables.buffer.append("<span style='" & getStyle(arguments.element) & "'>")/>
    </cffunction>
    <cffunction name="endHighlight" access="private" hint="" output="false">
		<cfargument name="line" type="any"/>
		<cfset variables.spansClosed = variables.spansClosed + 1/>
		<cfset variables.buffer.append("</span>")/>
    </cffunction>
    <cffunction name="startOneLineComment" access="private" output="false">
    	<cfargument name="type" type="string"/>
		<cfscript>
		startHighlight(type);
		variables.isOneLineComment=true;
		variables.isCommented=true;
		</cfscript>	
    </cffunction>
    <cffunction name="endOneLineComment" access="private" output="false">
    	<cfscript>
		endHighlight();
		variables.isOneLineComment=false;
		variables.isCommented=false;
		</cfscript>	
    </cffunction>
	<cffunction name="startComment" access="private" output="false">
    	<cfargument name="type" type="string"/>
        <cfscript>
		if (type  EQ  "CF") {
			startHighlight("CFCOMMENT");
			variables.buffer.append("&lt;");
		} else if (type  EQ  "HTML") {
			if (variables.isMXML) {
				startHighlight("MXMLCOMMENT");
			} else {
				startHighlight("HTMLCOMMENT");
			}
			variables.buffer.append("&lt;");
		} else {
			if (variables.isActionscript) {
				startHighlight("ACTIONSCRIPTCOMMENT");
			} else if (variables.isSQL) {
				startHighlight("SQLCOMMENT");
			} else {
				startHighlight("CFSCRIPTCOMMENT");
			}
			variables.buffer.append("/");
		}
		variables.isCommented=true;
		</cfscript>
    </cffunction>
	<cffunction name="endComment" access="private" output="false">
    	<cfargument name="type" type="string"/>
        <cfscript>
		if (type  EQ  "SCRIPT") {
			variables.buffer.append("/");
		} else {
			variables.buffer.append("&gt;");
		}
		endHighlight();
		variables.isCommented=false;
		</cfscript>
    </cffunction>
	<cffunction name="startTag" access="private" output="false">
    	<cfargument name="type" type="string"/>
		<cfscript>
		if (NOT variables.isCommented AND NOT variables.isValue) {
			if (type  EQ  "CF") {
				startHighlight("CFTAG");
			} else if (type  EQ  "HTMLSTYLES") {
				startHighlight("HTMLSTYLES");
			} else if (type  EQ  "HTMLTABLES") {
				startHighlight("HTMLTABLES");
			} else if (type  EQ  "HTMLFORMS") {
				startHighlight("HTMLFORMS");
			} else if (type EQ "MXML") {
				startHighlight("MXML");
			} else if (type EQ "ACTIONSCRIPTTAG") {
				startHighlight("ACTIONSCRIPTTAG");
			} else { // type is HTML
				startHighlight("HTML");
			}
			variables.isTag=true;
		}
		variables.buffer.append("&lt;");
		</cfscript>
    </cffunction>
	<cffunction name="endTag" access="private" output="false">
		<cfscript>
		variables.buffer.append("&gt;");
		if (NOT variables.isCommented AND NOT variables.isValue) {
			endHighlight();
			variables.isTag=false;
		}
		</cfscript>
    </cffunction>
	<cffunction name="startValue" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			if (variables.isCFSETTag OR variables.isCFScript) {
				startHighlight("CFSCRIPTVALUE");
			} else if (variables.isActionscript) {
				startHighlight("ACTIONSCRIPTVALUE");
			} else if (variables.isMXML) {
				startHighlight("MXMLVALUE");
			} else if (variables.isSQL) {
				startHighlight("SQLVALUE");
			} else {
				startHighlight("VALUE");
			}
			variables.isValue=true;
		}
		</cfscript>
    </cffunction>
	<cffunction name="endValue" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
			variables.isValue=false;
		}
		</cfscript>
	</cffunction>
	<cffunction name="startBind" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			startHighlight("BIND");
		}
		</cfscript>
    </cffunction>
	<cffunction name="endBind" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
		}
		</cfscript>
	</cffunction>
	<cffunction name="startCFSET" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			startHighlight("CFSET");
			variables.isCFSETTag=true;
		}
		</cfscript>
    </cffunction>
	<cffunction name="endCFSET" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
			variables.buffer.append("&gt;");
			endHighlight();
			variables.isCFSETTag=false;
		} else {
			variables.buffer.append("&gt;");
		}
		</cfscript>
    </cffunction>
    <cffunction name="startMXMLTag" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			startHighlight("MXMLATTRIBUTES");
			// TODO: Add in MXML Value colors.
			// setStyle("VALUE","color:##900");
			variables.isMXML=true;
		}
		</cfscript>
    </cffunction>
	<cffunction name="endMXMLTag" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
			variables.buffer.append("&gt;");
			endHighlight();
			// TODO: Add in MXML Value colors.
			// setStyle("VALUE","color:##0000CC");
			variables.isMXML=false;
		} else {
			variables.buffer.append("&gt;");
		}
		</cfscript>
    </cffunction>
	<cffunction name="startCFScript" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
			startHighlight("CFSCRIPT");
			variables.isCFScript=true;
		}
		</cfscript>
	</cffunction>
	<cffunction name="endCFScript" access="private" output="false">
    	<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
			variables.isCFScript=false;
		}
		</cfscript>
	</cffunction>
    <cffunction name="startActionscript" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			endHighlight();
			startHighlight("ACTIONSCRIPT");
			variables.isActionscript=true;
		}
		</cfscript>
	</cffunction>
	<cffunction name="endActionscript" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			variables.isActionscript=false;
		}
		</cfscript>
	</cffunction>
	<cffunction name="startSQL" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			variables.isSQL=true;
		}
		</cfscript>
	</cffunction>
	<cffunction name="endSQL" access="private" output="false">
		<cfscript>
		if (NOT variables.isCommented) {
			variables.isSQL=false;
		}
		</cfscript>
	</cffunction>
	
	<!--- configuration methods --->
	<cffunction name="setConfig" access="public" hint="This sets the coldfish configuration object for the parser to use." output="false">
    	<cfargument name="config" type="any"/>
		<cfset variables.coldfishconfig = config/>
    </cffunction>
	<cffunction name="getConfig" access="public" hint="This sets the coldfish configuration object for the parser to use." output="false">
    	<cfargument name="config" type="any"/>
		<cfreturn variables.coldfishconfig/>
    </cffunction>
	<cffunction name="getStyle" access="private" hint="This function can be used to get the style used in conjunction with a type of language element." output="false">
    	<cfargument name="element" type="string"/>
		<cfreturn getConfig().getStyle(element)/>
    </cffunction>
	<cffunction name="getInitialParser" access="private" hint="You can set the initial parser state with this.  This is helpful for scripts that make initial parsing impossible (ie. Script, Actionscript)" output="false">
		<cfreturn getConfig().getInitialParser()/>
    </cffunction>
	<cffunction name="getKeywordmap" access="private" hint="You can set the keywordmap with this." output="false">
		<cfreturn getConfig().getKeywordMap()/>
    </cffunction>
</cfcomponent>