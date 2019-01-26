<cfoutput>
<!DOCTYPE html>
<html>
	<head>
		<meta charset="utf-8">
		<title>Code Coverage Browser</title>

		<link rel="stylesheet" href="#variables.ASSETS_DIR#/css/fontawesome.css">
		<link rel="stylesheet" href="#variables.ASSETS_DIR#/css/bootstrap.min.css">
		<script	src="#variables.ASSETS_DIR#/js/jquery-3.3.1.min.js"></script>
		<script src="#variables.ASSETS_DIR#/js/popper.min.js"></script>
		<script src="#variables.ASSETS_DIR#/js/bootstrap.min.js"></script>
		<script src="#variables.ASSETS_DIR#/js/stupidtable.min.js"></script>

		<script>
			$(function(){
				$("table").stupidtable();
			});
		</script>



	<style>
		th.sorting-asc > span:after {
			content: "\2193";
		}

		th.sorting-desc > span:after {
			content: "\2191";
		}
	</style>

	</head>
	<body>
		<div class="container-fluid my-3">
			<h2 class="text-center">Code Coverage Browser</h2>

			<table class="table-borderless">
				<thead>
					<tr class="h4 pr-3">
						<th class="text-right pr-3">
							Total Files Processed:
						</th>
						<th style="width: 30%">
							#stats.numFiles#
						</th>
					</tr>
				</thead>
				<tbody>
					<tr class="h4 pr-3">
						<td class="text-right pr-3">
							Total project coverage:
						</td>
						<td style="width: 300px">
							<cfset percTotalCoverage = round( stats.percTotalCoverage * 100 )>
							<div class="progress position-relative" style="line-height: 2.5rem;font-size: 1.5rem; height:40px;">
								<div class="progress-bar bg-#percentToContextualClass( percTotalCoverage )#" role="progressbar" style="width: #percTotalCoverage#%" aria-valuenow="#percTotalCoverage#" aria-valuemin="0" aria-valuemax="100"></div>
								<div class="progress-bar bg-danger" role="progressbar" style="width: #100-percTotalCoverage#%" aria-valuenow="#100-percTotalCoverage#" aria-valuemin="0" aria-valuemax="100"></div>
								<span class="justify-content-center text-light d-flex position-absolute w-100">#percTotalCoverage#% coverage</span>
							</div>
						</td>
					</tr>
				</tbody>
			</table>


			<cfquery name="qryCoverageDataSorted" dbtype="query">
				SELECT filePath, relativeFilePath, numLines, numCoveredLines, numExecutableLines, percCoverage
				from qryCoverageData
				order by percCoverage
			</cfquery>

			<table class="table my-3">
				<thead>
					<tr>
						<th data-sort="string"><span class="btn btn-link">Path</span></th>
						<th data-sort="string" data-sort-onload=yes data-sort-default="asc"><span class="btn btn-link">Coverage</span></th>
					</tr>
				<thead>
				<tbody>
					<cfloop query="qryCoverageDataSorted">
					<cfset percentage = round( percCoverage * 100 )>
					<tr>
						<!--- Coverage files are named after "real" files --->
						<cfset link = "#replace( relativeFilePath, '\', '/', 'all' )#.html">
						<!--- Trim of leading slash so it's relative --->
						<cfset link = right( link, len( link ) - 1 )>
						<td data-sort-value="#relativeFilePath#"><a href="#link#">#relativeFilePath#</a></td>
						<td data-sort-value="#percentage#">
							<div class="progress position-relative" style="height: 1.4rem;">
								<div
									class="progress-bar bg-#percentToContextualClass( percentage )#"
									role="progressbar"
									style="width: #percentage#%"
									aria-valuenow="#percentage#"
									aria-valuemin="0"
									aria-valuemax="100">
								</div>
								<div
									class="progress-bar bg-danger"
									role="progressbar"
									style="width: #100 - percentage#%"
									aria-valuenow="#100 - percentage#"
									aria-valuemin="0"
									aria-valuemax="100">
								</div>
								<span
									class="justify-content-center text-light d-flex position-absolute w-100"
									style="line-height: 1.25rem; font-size: 1.2rem;"
								>
									#percentage#% coverage
								</span>
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
