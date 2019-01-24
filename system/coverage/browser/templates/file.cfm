<cfoutput>
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>#fileData.relativeFilePath#</title>

			<link rel="stylesheet" href="fontawesome.css">
			<link rel="stylesheet" href="bootstrap.min.css">
			<link rel="stylesheet" href="syntaxhighlighter.css">

			<script	src="jquery-3.3.1.min.js"></script>
			<script src="popper.min.js"></script>
			<script src="bootstrap.min.js"></script>
			<script src="syntaxhighlighter.js"></script>
			<script>
				$( document ).ready(function() {
					var lineNumbersBGColorsJSON = #lineNumbersBGColorsJSON#;
					$.each( lineNumbersBGColorsJSON, function( key, value ) {
						$(`.line.number${key}`).addClass(`text-light bg-${value}`);
					});
				});
			</script>

		</head>
		<body>
			<div class="container my-3">
				<h2>#fileData.relativeFilePath#</h2>
				<h4 class="row">File coverage:&nbsp;&nbsp;<span class="text-#percentToContextualClass( percentage )#">#percentage#%</span></h4>
				<a href="javascript:history.back()"><button type="button" class="btn btn-secondary btn-sm my-1"><i class="fas fa-backward"></i> Back</button></a>
				<hr width="100%">
				<cfset lineData = fileData.lineData>
				<cfset counter = 0>

<script type="text/syntaxhighlighter" class="brush: coldfusion"><![CDATA[
#fileContents#
]]></script>
			</div>
		</body>
	</html>
	</cfoutput>