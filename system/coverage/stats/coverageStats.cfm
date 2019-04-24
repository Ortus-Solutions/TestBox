<!---
	Template for outputting overview stats about the line coverage details that were captured.
 --->
<cfset ASSETS_DIR=expandPath( "/testbox/system/reports/assets" )>
<cfoutput>
<cfif fullPage>
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<meta name="generator" content="TestBox v#testbox.getVersion()#">
			<title>Pass: #results.getTotalPass()# Fail: #results.getTotalFail()# Errors: #results.getTotalError()#</title>

			<style>#fileRead( '#ASSETS_DIR#/css/main.css' )#</style>
			<script>#fileRead( '#ASSETS_DIR#/js/jquery-3.3.1.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/popper.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/bootstrap.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/stupidtable.min.js' )#</script>
			<script>#fileRead( '#ASSETS_DIR#/js/fontawesome.js' )#</script>
		</head>
		<body>
</cfif>
<cfif isDefined( 'stats' )>
	<cfset totalProjectCoverage = numberFormat( stats.percTotalCoverage * 100, '9.9' )>
	<div class="list-group mb-3">
		<div class="list-group-item list-group-item-info p-2" id="coverageStats">
			<h3 class="clearfix">
				<span>Code Coverage Stats</span>
				<div class="mt-2 h5 float-right">
					<button class="btn btn-link float-right py-0 expand-collapse collapsed" style="text-decoration: none;" id="btn_coverageStats" onclick="toggleDebug( 'coverageStats' )" title="Show coverage stats">
						<i class="fas fa-plus-square"></i>
					</button>
					<span class="ml-2 float-right">
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
					<span>Total Files Processed:<span class="badge badge-info ml-1">#stats.numFiles#</span></span>
				</div>
			</h3>

			<cfif len( coverageData.sonarQubeResults ) >
				<h6 class="mt-2">
					SonarQube code coverage XML file generated in #coverageData.sonarQubeResults#
				</h6>
			</cfif>

			<cfif len( coverageData.browserResults ) >
				<h6 class="my-2">
					Coverage Browser generated in #coverageData.browserResults#
				</h6>
			</cfif>

			<div class="debugdata" <cfif !fullPage>style="display:none;" </cfif>data-specid="coverageStats">
				<ul class="list-group">

					<li class="list-group-item">
						<h4>Files with best coverage:</h4>
						<ol class="list-group">
							<cfloop query="stats.qryFilesBestCoverage">
								<cfset qTarget         = stats.qryFilesBestCoverage>
								<cfset percentage      = numberFormat( qTarget.percCoverage * 100, '9.9' )>
								<cfset trimmedFilePath = replaceNoCase( qTarget.filePath, pathToCapture, '' )>
								<li class="list-group-item">
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
								<cfset qTarget      	= stats.qryFilesWorstCoverage>
								<cfset percentage 		= numberFormat( qTarget.percCoverage * 100, '9.9' )>
								<cfset trimmedFilePath 	= replaceNoCase( qTarget.filePath, pathToCapture, '' )>
								<li class="list-group-item">
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
	</div>
</cfif>
</cfoutput>
<cfif fullPage>
		<script>
			$( document ).ready( function() {
				$(".expand-collapse").click(function (event) {
					let icon = $(this).children(".svg-inline--fa");
					var icon_fa_icon = icon.attr('data-icon');

					if (icon_fa_icon === "minus-square") {
							icon.attr('data-icon', 'plus-square');
					} else if (icon_fa_icon === "plus-square") {
							icon.attr('data-icon', 'minus-square');
					}
				});
			});
			
			function toggleDebug(specid) {
				$( `#btn_${specid}` ).toggleClass( "collapsed" );
				$( "div.debugdata" ).each( function() {
					var $this = $( this );

					// if bundleid passed and not the same bundle
					if ( specid != undefined && $this.attr( "data-specid" ) != specid ) {
						return;
					}
					// toggle.
					$this.slideToggle();
				});
			}
			</script>
		</body>
	</html>
</cfif>