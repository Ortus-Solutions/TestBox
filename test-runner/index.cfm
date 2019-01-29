<cfparam name="url.target" 		default="">
<cfparam name="url.reporter" 	default="simple">
<cfparam name="url.opt_recurse" default="false">
<cfparam name="url.labels"		default="">
<cfparam name="url.opt_run"		default="false">
<cfscript>
// create testbox
testBox = new testbox.system.TestBox();
// create reporters
reporters = [ "ANTJunit", "Console", "Codexwiki", "Doc", "Dot", "JSON", "JUnit", "Min", "Raw", "Simple", "Tap", "Text", "XML" ];

if( url.opt_run ){
	// clean up
	for( key in URL ){
		url[ key ] = xmlFormat( trim( url[ key ] ) );
	}
	// execute tests
	if( len( url.target ) ){
		// directory or CFC, check by existence
		if( !directoryExists( expandPath( "/#replace( url.target, '.', '/', 'all' )#" ) ) ){
			results = testBox.run( bundles=url.target, reporter=url.reporter, labels=url.labels );
		} else {
			results = testBox.run( directory={ mapping=url.target, recurse=url.opt_recurse }, reporter=url.reporter, labels=url.labels );
		}
		if( isSimpleValue( results ) ){
			switch( url.reporter ){
				case "xml" : case "junit" : case "json" : case "text" : case "tap" : {
					writeOutput( "<textarea name='tb-results-data' id='tb-results-data' rows='20' cols='100'>#results#</textarea>" );break;
				}
				default: { writeOutput( results ); }
			}
		} else {
			writeDump( results );
		}
	} else {
		writeOutput( '<h2>No tests selected for running!</h2>' );
	}
	abort;
}

ASSETS_DIR = expandPath( "/testbox/system/reports/assets" );
</cfscript>

<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="generator" content="TestBox v#testbox.getVersion()#">
	<title>TestBox Global Runner</title>

	<cfoutput>
		<link rel="stylesheet" href="#ASSETS_DIR#/css/fontawesome.css">
		<link rel="stylesheet" href="#ASSETS_DIR#/css/bootstrap.min.css">
		<script	src="#ASSETS_DIR#/js/jquery-3.3.1.min.js"></script>
		<script src="#ASSETS_DIR#/js/popper.min.js"></script>
		<script src="#ASSETS_DIR#/js/bootstrap.min.js"></script>
		<script src="#ASSETS_DIR#/js/stupidtable.min.js"></script>
	</cfoutput>

	<script>
	function runTests(){
		console.log($("#runnerForm").serialize());

		$("#tb-results")
			.html( "" );

		$("#btn-run")
			.attr( "disabled", "disabled" )
			.html( 'Running...' )
			.css( "opacity", "0.5" );

		$("#tb-results")
			.load( "index.cfm", $("#runnerForm").serialize(), function( data ){
				$("#btn-run").removeAttr("disabled").html( 'Run' ).css( "opacity", "1" );
			} );
	}
	function clearResults(){
		$("#tb-results").html( '' );
		$("#target").html( '' );
		$("#labels").html( '' );
	}
	</script>
</head>
<cfoutput>
<body>
<!--- Title --->
<div id="tb-runner" class="container">
	<div class="row">
		<div class="col-md-4 text-center mx-auto">
			<img class="mt-3" src="http://www.ortussolutions.com/__media/testbox-185.png" alt="TestBox" id="tb-logo"/>
			<br>
			v#testbox.getVersion()#
		</div>
	</div>
	<div class="row">
		<div class="col-md-12">
			<form name="runnerForm" id="runnerForm">
				<input type="hidden" name="opt_run" id="opt_run" value="true"/>
				<input type="hidden" name="full_page" id="full_page" value="false"/>

				<h2>TestBox Global Runner</h2>
				<p>Please use the form below to run test bundle(s), directories and more.</p>
				<div class="form-group">
					<label for="target">Bundle(s) or Directory Mapping</label>
					<input  class="form-control" type="text" name="target" id="target" value="#trim( url.target )#" placeholder="Bundle(s)"/>
				</div>
				<div class="form-group form-check">
					<input class="form-check-input" title="Enable directory recursion for directory runner" name="opt_recurse" id="opt_recurse" type="checkbox" value="true" <cfif url.opt_recurse>checked="true"</cfif> />
					<label class="form-check-label" for="opt_recurse"> Recurse Directories</label>
				</div>
				<div class="form-group">
					<label for="labels">List of labels to apply to tests</label>
					<input  class="form-control" title="List of labels to apply to tests" type="text" name="labels" id="labels" value="#url.labels#" placeholder="Label(s)"/>
				</div>
				<div class="form-group">
					<label for="reporter">Reporter</label>
					<select name="reporter" id="reporter" class="custom-select">
						<cfloop array="#reporters#" index="thisReporter">
							<option <cfif url.reporter eq thisReporter>selected="selected"</cfif> value="#thisReporter#">#thisReporter# Reporter</option>
						</cfloop>
					</select>
				</div>
				<div class="form-group">
					<button class="btn btn-sm btn-primary" type="button" onclick="clearResults()">Clear</button>
					<button class="btn btn-sm btn-primary" type="button" id="btn-run" title="Run all the tests" onclick="runTests()">Run</button>
				</div>

		</form>
		</div>
	</div>
</div>

<!--- Results --->
<div id="tb-results" class="container"></div>

</body>
</html>
</cfoutput>
