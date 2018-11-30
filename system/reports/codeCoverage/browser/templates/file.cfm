<cfscript>
local.lineData=javaProxy.toCFML(filedata.lineData);
local.lineNumbersBGColors = local.lineData.map(function(key,value,strct){
    return (value > 0) ? "LINENUMBERBGSUCCESS" : "LINENUMBERBGDANGER";
});
</cfscript>
<cfoutput>
	<h1>#fileData.relativeFilePath#</h1>
	<h2>File coverage: <span style="color:#percentToColor( fileData.percCoverage )#">#round( fileData.percCoverage*100 )#%</span></h2>
	<a href="javascript:history.back()"><< Back <<</a>	
	<hr width="100%">
	#coldfish.formatFile(filePath=fileData.filePath, lineNumbersStyles=local.lineNumbersBGColors, lineNumberDefaultBG = "LINENUMBERBGSECONDARY")#
</cfoutput>