<cfoutput>
<!-- Stats --->
<section class="border border-info my-1 p-1 bg-light clearfix" id="globalStats">

	<h2>Stats (#results.getTotalDuration()# ms)</h2>
	<p>
		Bundles/Suites/Specs: #results.getTotalBundles()#/#results.getTotalSuites()#/#results.getTotalSpecs()#
		<br>
		<span class="badge badge-success" data-status="passed">Pass: #results.getTotalPass()#</span>
		<span class="badge badge-warning" data-status="failed">Failures: #results.getTotalFail()#</span>
		<span class="badge badge-danger" data-status="error">Errors: #results.getTotalError()#</span>
		<span class="badge badge-secondary" data-status="skipped">Skipped: #results.getTotalSkipped()#</span>
		<br>
		<cfif arrayLen( results.getLabels() )>
		Labels Applied: #arrayToList( results.getLabels() )#<br>
		</cfif>
		<cfif results.getCoverageEnabled()>
		Coverage: #numberFormat( results.getCoverageData().stats.percTotalCoverage*100, '9.9' )#%
		</cfif>
	</p>
</section>

<!--- Bundle Info --->
<cfloop array="#variables.bundleStats#" index="thisBundle">
	<!--- Skip if not in the includes list --->
	<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
		<cfcontinue>
	</cfif>
	<section class="bundle" id="bundle-#thisBundle.path#">

		<!--- bundle stats --->
		<h2>#thisBundle.name# (#thisBundle.totalDuration# ms)</h2>
		<p>
			Suites/Specs: #thisBundle.totalSuites#/#thisBundle.totalSpecs#
			<br>
			<span class="badge badge-success" 	data-status="passed" data-bundleid="#thisBundle.id#">Pass: #thisBundle.totalPass#</span>
			<span class="badge badge-warning" 	data-status="failed" data-bundleid="#thisBundle.id#">Failures: #thisBundle.totalFail#</span>
			<span class="badge badge-danger" 	data-status="error" data-bundleid="#thisBundle.id#">Errors: #thisBundle.totalError#</span>
			<span class="badge badge-secondary" 	data-status="skipped" data-bundleid="#thisBundle.id#">Skipped: #thisBundle.totalSkipped#</span>
		</p>

		<!-- Global Error --->
		<cfif !isSimpleValue( thisBundle.globalException )>
			<h2>Global Bundle Exception</h2>
			<p>#thisBundle.globalException.stacktrace#</p>
		</cfif>

		<!-- Iterate over bundle suites -->
		<cfloop array="#thisBundle.suiteStats#" index="suiteStats">
			<section class="suite #statusToBootstrapClass( suiteStats.status )#" data-suiteid="#suiteStats.id#">
			<dl>
				#genSuiteReport( suiteStats, thisBundle )#
			</dl>
			</section>
		</cfloop>

	</section>
</cfloop>

<cfscript>
function statusToBootstrapClass( status ) output="false" {
    if ( lcase( arguments.status ) == "failed" ) {
        bootstrapClass = "text-warning";
    } else if ( lcase( arguments.status ) == "error" ) {
        bootstrapClass = "text-danger";
    } else if ( lcase( arguments.status ) == "passed" ) {
        bootstrapClass = "text-success";
    } else if ( lcase( arguments.status ) == "skipped" ) {
        bootstrapClass = "text-secondary";
    }

    return bootstrapClass;
}
</cfscript>

<!--- Recursive Output --->
<cfscript>
function genSuiteReport( suiteStats, bundleStats ) output="false" {
    var nl = chr( 10 );
    var t1 = chr( 9 );
    var t2 = repeatString( t1, 2 );
    var t3 = repeatString( t1, 3 );
    var t4 = repeatString( t1, 4 );
    var t5 = repeatString( t1, 5 );
    var t6 = repeatString( t1, 6 );

    savecontent variable="local.report" {
        // Suite Results
        writeOutput( nl & t2 & nl & t2 & nl & t2 );
        writeOutput( "<h2>+" & arguments.suiteStats.name & " (" & arguments.suiteStats.totalDuration & " ms)</h2>" & nl & t2 & "<dl>" & nl & t3 );
        for ( local.thisSpec in arguments.suiteStats.specStats ) {
            // Spec Results
            writeOutput( nl & t4 & nl & t4 );
            thisSpecStatusClass = statusToBootstrapClass( local.thisSpec.status );
            writeOutput( nl & nl & t4 );
            writeOutput( '<dt class="spec ' & thisSpecStatusClass & '" data-bundleid="' & arguments.bundleStats.id & '" data-specid="' & local.thisSpec.id & '">' & nl & t5 );
            writeOutput( local.thisSpec.displayName & " (" & local.thisSpec.totalDuration & " ms)" & nl & t4 & "</dt>" & nl & nl & t4 );

            if ( local.thisSpec.status == "failed" ) {
                writeOutput( nl & t5 & "<dd>" & encodeForHTML( local.thisSpec.failMessage ) & "</dd>" & nl & t5 );
                writeOutput( '<dd><textarea cols="100" rows="20">' & local.thisSpec.failOrigin.toString() & "</textarea></dd>" & nl & t4 );
            }
            writeOutput( nl & nl & t4 );

            if ( local.thisSpec.status == "error" ) {
                writeOutput( nl & t5 & "<dd>" & encodeForHTML( local.thisSpec.error.message ) & "</dd>" & nl & t5 );
                writeOutput( '<dd><textarea cols="100" rows="20">' & local.thisSpec.error.stacktrace & "</textarea></dd>" & nl & t4 );
            }
            writeOutput( nl & t3 );
        }

        // Do we have nested suites
        writeOutput( nl & nl & t3 & nl & t3 );
        if ( arrayLen( arguments.suiteStats.suiteStats ) ) {
            writeOutput( nl & t4 );
            for ( local.nestedSuite in arguments.suiteStats.suiteStats ) {
                writeOutput( nl & t5 );
                writeOutput( '<section class="suite ' & statusToBootstrapClass( arguments.suiteStats.status ) & '" data-bundleid="' & arguments.bundleStats.id & '">' & nl & t5 );
                writeOutput( "<dl>" & nl & t6 );
                writeOutput( genSuiteReport( local.nestedSuite, arguments.bundleStats ) );
                writeOutput( nl & t5 & "</dl>" & nl & t5 & "</section>" & nl & t4 );
            }
            writeOutput( nl & t3 );
        }
        writeOutput( nl & nl & t2 & "</dl>" & nl & t2 );
        writeOutput( nl & t1 );
    }

    return local.report;
}
</cfscript>
</cfoutput>
