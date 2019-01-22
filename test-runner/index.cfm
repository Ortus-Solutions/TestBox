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
</cfscript>
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="generator" content="TestBox v#testbox.getVersion()#">
	<title>TestBox Global Runner</title>
	<script
  src="https://code.jquery.com/jquery-3.3.1.min.js"
  integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8="
  crossorigin="anonymous"></script>
	<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.6/umd/popper.min.js" integrity="sha384-wHAiFfRlMFy6i5SRaxvfOCifBUQy1xHdJ/yoi7FRNXMRBu5WHdZYu1hA6ZOblgut" crossorigin="anonymous"></script>
	<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>
	<script>
	$(document).ready(function() {

	});
	function runTests(){
		console.log($("#runnerForm").serialize());
		$("#tb-results").html( "" );
		$("#btn-run").html( 'Running...' ).css( "opacity", "0.5" );
		$("#tb-results").load( "index.cfm", $("#runnerForm").serialize(), function( data ){
			$("#btn-run").html( 'Run' ).css( "opacity", "1" );
		} );
	}
	function clearResults(){
		$("#tb-results").html( '' );
		$("#target").html( '' );
		$("#labels").html( '' );
	}
	</script>
	<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" integrity="sha384-UHRtZLI+pbxtHCWp1t77Bi1L4ZtiqrqD80Kn4Z8NTSRyMA2Fd33n5dQ8lWUE00s/" crossorigin="anonymous">
	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
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
