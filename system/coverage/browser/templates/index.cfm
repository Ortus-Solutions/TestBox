<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>Code Coverage Browser</title>

		<script	src="https://code.jquery.com/jquery-3.3.1.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
		<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.6/umd/popper.min.js" integrity="sha384-wHAiFfRlMFy6i5SRaxvfOCifBUQy1xHdJ/yoi7FRNXMRBu5WHdZYu1hA6ZOblgut" crossorigin="anonymous"></script>
		<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>
		<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" integrity="sha384-UHRtZLI+pbxtHCWp1t77Bi1L4ZtiqrqD80Kn4Z8NTSRyMA2Fd33n5dQ8lWUE00s/" crossorigin="anonymous">
		<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
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
