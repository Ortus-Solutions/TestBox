<!---
	The files attached to a spec with attach(): screenshots show as thumbnails that open full size, traces offer
	the command that opens them, and every file links to its path.
	Inputs: arguments.data.spec, arguments.data.inline (embed the images, default true; false links them to the
	failure card that already shows them)
--->
<cfset local.views  = variables.helper.attachments( arguments.data.spec )>
<!--- not ?: : Adobe treats a false inline as missing --->
<cfset local.inline = !structKeyExists( arguments.data, "inline" ) || arguments.data.inline>
<cfset local.shots  = []>
<cfloop array="#local.views#" item="thisView">
	<cfif local.inline && len( thisView.src )>
		<cfset arrayAppend( local.shots, thisView )>
	</cfif>
</cfloop>
<cfoutput>
<cfif arrayLen( local.views )>
	<div class="tb-attachments">
		<cfif arrayLen( local.shots )>
			<div class="tb-shots">
				<cfloop array="#local.shots#" item="thisView">
					<figure class="tb-shot">
						<button
							type="button"
							class="tb-shot__open"
							@click="zoom( $event )"
							title="View #encodeForHtml( thisView.name )# full size"
						>
							<img src="#thisView.src#" alt="#encodeForHtml( thisView.name )#" loading="lazy">
						</button>
						<figcaption>#encodeForHtml( thisView.name )#</figcaption>
					</figure>
				</cfloop>
			</div>
		</cfif>
		<ul class="tb-spec__attachments">
			<!--- an embedded screenshot already shows above as a thumbnail --->
			<cfloop array="#local.views#" item="thisView">
				<cfif !( local.inline && len( thisView.src ) )>
				<li>
					<cfif thisView.kind == "image" && len( thisView.src ) && !local.inline>
						<a href="##failure-#encodeForHtml( arguments.data.spec.id )#" title="#encodeForHtml( thisView.path )#">#encodeForHtml( thisView.name )#</a>
					<cfelse>
						<a href="#encodeForHtml( thisView.href )#" title="#encodeForHtml( thisView.path )#">#encodeForHtml( thisView.name )#</a>
					</cfif>
					<span class="tb-spec__ms">(#encodeForHtml( thisView.type )#)</span>
					<cfif len( thisView.command )>
						<button
							type="button"
							class="btn btn-link btn-sm p-0 align-baseline"
							@click="copy( #encodeForHtml( serializeJSON( thisView.command ) )#, 'Command copied: run it to open the trace.' )"
						>Copy show-trace command</button>
					</cfif>
				</li>
				</cfif>
			</cfloop>
		</ul>
	</div>
</cfif>
</cfoutput>
