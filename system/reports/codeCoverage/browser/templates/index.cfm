<cfoutput>
<h1>Code Coverage Browser</h1> 

<h2>Total Files Processed: #stats.numFiles#</h2>
<h2>Total project coverage: <span style="color:#percentToColor( stats.percTotalCoverage )#">#round( stats.percTotalCoverage*100 )#%</span></h2>

<cfquery name="qryCoverageDataSorted" dbtype="query">
	SELECT filePath, relativeFilePath, numLines, numCoveredLines, numExecutableLines, percCoverage
	from qryCoverageData
	order by percCoverage
</cfquery>

	<table border="1">
		<tr>
			<td>Path</td>
			<td>Coverage</td>
		</tr>
		<cfloop query="qryCoverageDataSorted">
		<tr>
			<!--- Coverage files are named after "real" files --->
			<cfset link = "#replace( relativeFilePath, '\', '/', 'all' )#.html">
			<!--- Trim of leading slash so it's relative --->
			<cfset link = right( link, len( link )-1 )>
			<td><a href="#link#">#relativeFilePath#</a></td>
			<td bgcolor="#percentToColor( percCoverage )#">#round( percCoverage*100 )#%</td>
		</tr>
		</cfloop>
	</table>
	
</cfoutput>
