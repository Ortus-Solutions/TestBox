<!---
	Template for outputting overview stats about the line coverage details that were captured.
 --->
<cfoutput>
	<cfif len( coverageData.sonarQubeResults ) >
		SonarQube code coverage XML file generated at #coverageData.sonarQubeResults#<br><br>
	</cfif>

	<cfif len( coverageData.browserResults ) >
		Coverage Browser generated in #coverageData.browserResults#<br><br>
	</cfif>

	<cfif isDefined( 'stats' )>
		<cfset totalProjectCoverage = round( stats.percTotalCoverage*100 )>
		<ul class="list-group">
			<li class="list-group-item"><h4>Total Files Processed: #stats.numFiles#</h4></li>
			<li class="list-group-item"><h4>Total project coverage: <span class="text-#codeBrowser.percentToContextualClass(totalProjectCoverage)#">#totalProjectCoverage#%</span></h4></li>
			<li class="list-group-item">
				<h4>Files with best coverage:</h4>
				<ol class="list-group">
					<cfloop query="stats.qryFilesBestCoverage">
						<cfset percentage = round( percCoverage*100 )>
						<li class="list-group-item list-group-item-#codeBrowser.percentToContextualClass( percentage )#">
							<span class="col-9">#filePath#</span>
								<div class=" col-3 d-inline-flex float-right">
								<div class="progress position-relative w-100">
									<div class="progress-bar bg-#codeBrowser.percentToContextualClass( percentage )#" role="progressbar" style="width: #percentage#%" aria-valuenow="#percentage#" aria-valuemin="0" aria-valuemax="100"></div>
									<div class="progress-bar bg-secondary" role="progressbar" style="width: #100-percentage#%" aria-valuenow="#100-percentage#" aria-valuemin="0" aria-valuemax="100"></div>
									<span class="justify-content-center text-light d-flex position-absolute w-100">#percentage#% coverage</span>
								</div>
							</div>
						</li>
					</cfloop>
				</ol>
			</li>
			<li class="list-group-item">
				<h4>Files with worst coverage:</h4>
				<ol class="list-group">
					<cfloop query="stats.qryFilesWorstCoverage">
						<cfset percentage = round( percCoverage*100 )>
						<li class="list-group-item list-group-item-#codeBrowser.percentToContextualClass( percentage )#">
							<span class="col-9">#filePath#</span>
								<div class=" col-3 d-inline-flex float-right">
								<div class="progress position-relative w-100">
									<div class="progress-bar bg-#codeBrowser.percentToContextualClass( percentage )#" role="progressbar" style="width: #percentage#%" aria-valuenow="#percentage#" aria-valuemin="0" aria-valuemax="100"></div>
									<div class="progress-bar bg-secondary" role="progressbar" style="width: #100-percentage#%" aria-valuenow="#100-percentage#" aria-valuemin="0" aria-valuemax="100"></div>
									<span class="justify-content-center text-light d-flex position-absolute w-100">#percentage#% coverage</span>
								</div>
							</div>
						</li>
					</cfloop>
				</ol>
			</li>
		</ul>
	</cfif>
</cfoutput>