<cfsetting showdebugoutput="false" >
<!--- CPU Integration --->
<cfparam name="url.cpu" default="false">
<!--- SETUP THE ROOTS OF THE BROWSER RIGHT HERE --->
<cfset rootMapping 	= "/tests/specs">
<cfif directoryExists( rootMapping )>
	<cfset rootPath = rootMapping>
<cfelse>
	<cfset rootPath = expandPath( rootMapping )>
</cfif>

<!--- param incoming --->
<cfparam name="url.path" default="/">

<!--- Decodes & Path Defaults --->
<cfif !len( url.path )>
	<cfset url.path = "/">
</cfif>

<!--- Prepare TestBox --->
<cfset testbox = new testbox.system.TestBox()>

<!--- Run Tests Action?--->
<cfif structKeyExists( url, "action")>
	<cfif directoryExists( expandPath( rootMapping & url.path ) )>
		<cfoutput>#testbox.init( directory=rootMapping & url.path ).run()#</cfoutput>
	<cfelse>
		<cfoutput><h1>Invalid incoming directory: #rootMapping & url.path#</h1></cfoutput>
	</cfif>
	<cfabort>

</cfif>

<!--- Get list of files --->
<cfdirectory action="list" directory="#rootPath & url.path#" name="qResults" sort="directory asc, name asc">
<!--- Get the execute path --->
<cfset executePath = rootMapping & ( url.path eq "/" ? "/" : url.path & "/" )>
<!--- Get the Back Path --->
<cfif url.path neq "/">
	<cfset backPath = replacenocase( url.path, listLast( url.path, "/" ), "" )>
	<cfset backPath = reReplace( backpath, "/$", "" )>
</cfif>

<!--- Do HTML --->
<!DOCTYPE html>
<html>
<head>
	<meta charset="utf-8">
	<meta name="generator" content="TestBox v#testbox.getVersion()#">
	<title>TestBox Global Runner</title>
	<script><cfinclude template="/testbox/system/reports/assets/js/jquery.js"></script>
	<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" integrity="sha384-UHRtZLI+pbxtHCWp1t77Bi1L4ZtiqrqD80Kn4Z8NTSRyMA2Fd33n5dQ8lWUE00s/" crossorigin="anonymous">
	<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
</head>
<cfoutput>
<body>

<!--- Title --->
<div id="tb-runner" class="container bg-light">
	<div class="row">
		<div class="col-md-4 text-center mx-auto">
			<img class="mt-3" src="http://www.ortussolutions.com/__media/testbox-185.png" alt="TestBox" id="tb-logo"/>
			<br>
			v#testbox.getVersion()#
			<br>
			<a href="index.cfm?action=runTestBox&path=#URLEncodedFormat( url.path )#" target="_blank"><button class="btn btn-primary btn-sm my-1" type="button">Run All</button></a>
		</div>
	</div>
	<div class="row">
		<div class="col-md-12">
			<form name="runnerForm" id="runnerForm">
				<input type="hidden" name="opt_run" id="opt_run" value="true">
				<h1>TestBox Test Browser: </h1>
				<p>
					Below is a listing of the files and folders starting from your root <code>#rootPath#</code>.  You can click on individual tests in order to execute them
					or click on the <strong>Run All</strong> button on your left and it will execute a directory runner from the visible folder.
				</p>

				<fieldset>
					<legend>Contents: #executePath#</legend>
					<cfif url.path neq "/">
						<a href="index.cfm?path=#URLEncodedFormat( backPath )#"><button type="button" class="btn btn-secondary btn-sm my-1"><i class="fas fa-backward"></i> Back</button></a><br><hr>
					</cfif>
					<cfloop query="qResults">
						<cfif refind( "^\.", qResults.name )>
							<cfcontinue>
						</cfif>

						<cfset dirPath = URLEncodedFormat( ( url.path neq '/' ? '#url.path#/' : '/' ) & qResults.name )>
						<cfif qResults.type eq "Dir">
							<a class="btn btn-secondary btn-sm my-1" href="index.cfm?path=#dirPath#"><i class="fas fa-plus-square"></i> #qResults.name#</a><br/>
						<cfelseif listLast( qresults.name, ".") eq "cfm">
							<a class="btn btn-primary btn-sm my-1" href="#executePath & qResults.name#" <cfif !url.cpu>target="_blank"</cfif>>#qResults.name#</a><br/>
						<cfelseif listLast( qresults.name, ".") eq "cfc" and qresults.name neq "Application.cfc">
							<a class="btn btn-primary btn-sm my-1" href="#executePath & qResults.name#?method=runRemote" <cfif !url.cpu>target="_blank"</cfif>>#qResults.name#</a><br/>
						<cfelse>
							#qResults.name#<br/>
						</cfif>

					</cfloop>
				</fieldset>
			</form>
		</div>
	</div>
</div>

</body>
</html>
</cfoutput>