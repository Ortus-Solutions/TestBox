<cfoutput>
	<!DOCTYPE html>
	<html>
		<head>
			<meta charset="utf-8">
			<title>#fileData.relativeFilePath#</title>

			<link rel="stylesheet" href="bootstrap.min.css">
			<link rel="stylesheet" href="syntaxhighlighter.css">

			<script	src="jquery-3.3.1.min.js"></script>
			<script src="syntaxhighlighter.js"></script>
			<script>
				$( document ).ready( function(){
					var lineNumbersBGColorsJSON = #lineNumbersBGColorsJSON#;
					$.each( lineNumbersBGColorsJSON, function( key, value ) {
						$( `.line.number${key}` ).addClass( `text-light bg-${value}` );
					});
				});
			</script>

		</head>
		<body>
			<div class="container-fluid my-3">
				<h2 class="row text-center">
					<div class="d-inline-block mx-auto col-5">
						<span class="d-inline-block">#fileData.relativeFilePath#</span>
						<span class="d-inline">
							<div class="progress position-relative h-100" style="line-height: 2.5rem;font-size: 1.5rem;">
								<div class="progress-bar bg-#percentToContextualClass( percentage )#" role="progressbar" style="width: #percentage#%" aria-valuenow="#percentage#" aria-valuemin="0" aria-valuemax="100"></div>
								<div class="progress-bar bg-danger" role="progressbar" style="width: #100-percentage#%" aria-valuenow="#100-percentage#" aria-valuemin="0" aria-valuemax="100"></div>
								<span class="justify-content-center text-light d-flex position-absolute w-100">#percentage#% coverage</span>
							</div>
						</span>
					</div>
				</h2>
				<a href="javascript:history.back()"><button type="button" class="btn btn-secondary btn-sm my-1">&laquo; Back</button></a>
				<hr width="100%">

<script type="text/syntaxhighlighter" class="brush: coldfusion"><![CDATA[
#fileContents#
]]></script>
			</div>
		</body>
	</html>
	</cfoutput>