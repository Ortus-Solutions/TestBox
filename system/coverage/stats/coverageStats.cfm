<!---
	Template for outputting overview stats about the line coverage details that were captured.
 --->
<cfoutput>
	<cfif isDefined( 'stats' )>
		<cfset totalProjectCoverage = round( stats.percTotalCoverage*100 )>

		<div class="list-group-item list-group-item-info" id="coverageStats">
			<h2 class="clearfix">
				<span>Coverage Stats</span>
				<div class="mt-2 h5 float-right">
					<button class="btn btn-link float-right py-0 expand-collapse collapsed" id="btn_coverageStats" onclick="toggleDebug( 'coverageStats' )" title="Show coverage stats">
						<i class="arrow" aria-hidden="true"></i>
					</button>
					<span class="ml-2">Total Files Processed:<span class="badge badge-info ml-1">#stats.numFiles#</span></span>
					<span>
						<span class="h5 float-left">Total project coverage:</span>
						<div class="float-left" style="width:200px;">
							<div class="ml-1 progress position-relative" style="height: 1.4rem;">
								<div class="progress-bar bg-#codeBrowser.percentToContextualClass(totalProjectCoverage)#" role="progressbar" style="width: #totalProjectCoverage#%" aria-valuenow="#totalProjectCoverage#" aria-valuemin="0" aria-valuemax="100">
								</div>
								<div class="progress-bar bg-secondary" role="progressbar" style="width: #100 - totalProjectCoverage#%" aria-valuenow="#100 - totalProjectCoverage#" aria-valuemin="0" aria-valuemax="100">
								</div>
								<span class="justify-content-center text-light d-flex position-absolute w-100" style="line-height: 1.25rem; font-size: 1.2rem;">
									#totalProjectCoverage#% coverage
								</span>
							</div>
						</div>
					</span>
				</div>
			</h2>

			<cfif len( coverageData.sonarQubeResults ) >
				<h6 class="mt-2">
					SonarQube code coverage XML file generated in #coverageData.sonarQubeResults#
				</h6>
			</cfif>

			<cfif len( coverageData.browserResults ) >
				<h6 class="mt-2">
					Coverage Browser generated in #coverageData.browserResults#
				</h6>
			</cfif>
			<div class="my-3 debugdata" style="display:none;" data-specid="coverageStats">
				<ul class="list-group">
					<li class="list-group-item">
						<h4>Files with best coverage:</h4>
						<ol class="list-group">
							<cfloop query="stats.qryFilesBestCoverage">
								<cfset percentage = round( percCoverage*100 )>
								<cfset trimmedFilePath = replaceNoCase( filePath, pathToCapture, '' )>
								<li class="list-group-item list-group-item-#codeBrowser.percentToContextualClass( percentage )#">
									<span class="col-9">#trimmedFilePath#</span>
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
									<span class="col-9">#trimmedFilePath#</span>
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
			</div>
		</div>


	</cfif>
</cfoutput>