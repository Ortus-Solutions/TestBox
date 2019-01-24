<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>Code Coverage Browser</title>

		<link rel="stylesheet" href="fontawesome.css">
		<link rel="stylesheet" href="bootstrap.min.css">
		<script	src="jquery-3.3.1.min.js"></script>
		<script src="popper.min.js"></script>
		<script src="bootstrap.min.js"></script>

	</head>
	<body>
		<div class="container my-3">
			<h2>Code Coverage Browser</h2>

			<h4>Total Files Processed: #stats.numFiles#</h4>
			<h4>Total project coverage: <span class="text-#percentToContextualClass( stats.percTotalCoverage )#">#round( stats.percTotalCoverage*100 )#%</span></h4>

			<cfquery name="qryCoverageDataSorted" dbtype="query">
				SELECT filePath, relativeFilePath, numLines, numCoveredLines, numExecutableLines, percCoverage
				from qryCoverageData
				order by percCoverage
			</cfquery>

			<table class="table my-3">
				<thead>
					<tr>
						<th>Path</th>
						<th>Coverage</th>
					</tr>
				<thead>
				<tbody>
					<cfloop query="qryCoverageDataSorted">
					<cfset local.percentage = round( percCoverage*100 )>
					<tr>
						<!--- Coverage files are named after "real" files --->
						<cfset link = "#replace( relativeFilePath, '\', '/', 'all' )#.html">
						<!--- Trim of leading slash so it's relative --->
						<cfset link = right( link, len( link )-1 )>
						<td><a href="#link#">#relativeFilePath#</a></td>
						<td>
							<div class="progress position-relative">
								<div class="progress-bar bg-#percentToContextualClass( local.percentage )#" role="progressbar" style="width: #percentage#%" aria-valuenow="#percentage#" aria-valuemin="0" aria-valuemax="100"></div>
								<div class="progress-bar bg-danger" role="progressbar" style="width: #100-percentage#%" aria-valuenow="#100-percentage#" aria-valuemin="0" aria-valuemax="100"></div>
								<span class="justify-content-center text-light d-flex position-absolute w-100">#percentage#% coverage</span>
							</div>
						</td>
					</tr>
					</cfloop>
				</tbody>
			</table>
		</div>
	</body>
</html>
</cfoutput>
