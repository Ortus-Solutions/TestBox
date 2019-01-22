<cfscript>
local.lineNumbersBGColors = structMap( filedata.lineData, function( key, value,strct ){
    return ( value > 0 ) ? "LINENUMBERBGSUCCESS" : "LINENUMBERBGDANGER";
});
local.percentage = round( fileData.percCoverage*100 )
</cfscript>
<cfoutput>
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>#fileData.relativeFilePath#</title>

			<script	src="https://code.jquery.com/jquery-3.3.1.min.js" integrity="sha256-FgpCb/KJQlLNfOu91ta32o/NMZxltwRo8QtmkMRdAu8=" crossorigin="anonymous"></script>
			<script src="https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.6/umd/popper.min.js" integrity="sha384-wHAiFfRlMFy6i5SRaxvfOCifBUQy1xHdJ/yoi7FRNXMRBu5WHdZYu1hA6ZOblgut" crossorigin="anonymous"></script>
			<script src="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/js/bootstrap.min.js" integrity="sha384-B0UglyR+jN6CkvvICOB2joaf5I4l3gm9GU6Hc1og6Ls7i6U/mkkaduKaBhlAXv9k" crossorigin="anonymous"></script>
			<link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.6.3/css/all.css" integrity="sha384-UHRtZLI+pbxtHCWp1t77Bi1L4ZtiqrqD80Kn4Z8NTSRyMA2Fd33n5dQ8lWUE00s/" crossorigin="anonymous">
			<link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.2.1/css/bootstrap.min.css" integrity="sha384-GJzZqFGwb1QTTN6wy59ffF1BuGJpLSa9DkKMp0DgiMDm4iYMj70gZWKYbI706tWS" crossorigin="anonymous">
		</head>
		<body>
			<div class="container my-3">
				<h2>#fileData.relativeFilePath#</h2>
				<h4 class="row">File coverage:&nbsp;&nbsp;<span class="text-#percentToContextualClass( local.percentage )#">#percentage#%</span></h4>
				<a href="javascript:history.back()"><button type="button" class="btn btn-secondary btn-sm my-1"><i class="fas fa-backward"></i> Back</button></a>
				<hr width="100%">
				#coldfish.formatFile(filePath=fileData.filePath, lineNumbersStyles=local.lineNumbersBGColors, lineNumberDefaultBG = "LINENUMBERBGSECONDARY")#
			</div>
		</body>
	</html>
	</cfoutput>