<cfparam name="variables.runnerToolbarTestsUrl" default="">
<cfset variables.runnerToolbarRunAllUrl = variables.runnerToolbarTestsUrl>
<cfif len( trim( variables.runnerToolbarTestsUrl ) ) && !findNoCase( "opt_run=", variables.runnerToolbarTestsUrl )>
	<cfset variables.runnerToolbarRunAllUrl = variables.runnerToolbarTestsUrl & ( find( "?", variables.runnerToolbarTestsUrl ) ? "&" : "?" ) & "opt_run=true">
</cfif>
<cfoutput>
<div class="d-flex justify-content-between align-items-end">
	<div>
		<div>
			<img src="data:image/png;base64, #toBase64( fileReadBinary( '#ASSETS_DIR#/images/TestBoxLogo125.png' ) )#" height="75" alt="TestBox">
			<span class="badge badge-info">v#testbox.getVersion()#</span>
		</div>
	</div>
	<div>
		<input class="d-inline col-7 ml-2 form-control float-right mb-1" type="text" name="bundleFilter" id="bundleFilter" placeholder="Filter Bundles..." size="35">
		<div class="buttonBar mb-1 float-right">
			<cfif len( trim( variables.runnerToolbarTestsUrl ) )>
				<a class="ml-1 btn btn-sm btn-primary float-right" href="#encodeForHTML( variables.runnerToolbarRunAllUrl )#" title="Run all tests">
					<i class="fas fa-running"></i> Run All Tests
				</a>
			</cfif>
			<button
				id="collapse-bundles"
				class="ml-1 btn btn-sm btn-primary float-right"
				title="Collapse all bundles"
				type="button"
			>
				<i class="fas fa-minus-square"></i> Collapse All Bundles
			</button>
			<button
				id="expand-bundles"
				class="ml-1 btn btn-sm btn-primary float-right"
				title="Expand all bundles"
				type="button"
			>
				<i class="fas fa-plus-square"></i> Expand All Bundles
			</button>
		</div>
	</div>
</div>
</cfoutput>
