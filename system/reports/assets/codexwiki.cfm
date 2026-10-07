<cfparam name="url" default="#structNew()#"><cfparam name="url.testBundles" default=""><cfoutput>
= Stats (#results.getTotalDuration()# ms) =

* '''Bundles/Suites/Specs:''' #results.getTotalBundles()#/#results.getTotalSuites()#/#results.getTotalSpecs()#
* '''Pass:''' #results.getTotalPass()#
* '''Failures:''' #results.getTotalFail()#
* '''Errors:''' #results.getTotalError()#
* '''Skipped:''' #results.getTotalSkipped()#
<cfif !arrayLen( results.getLabels() )>
* '''Labels Applied:''' #arrayToList( results.getLabels() )#
</cfif>
<cfif results.getCoverageEnabled()>
* '''Coverage:''' #numberFormat( results.getCoverageData().stats.percTotalCoverage*100, '9.9' )#%
</cfif>

#chr(10)#

<cfloop array="#variables.bundleStats#" index="thisBundle">
<!--- Skip if not in the includes list --->
<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
	<cfcontinue>
</cfif>
= #thisBundle.name# (#thisBundle.totalDuration# ms) =

* '''Suites/Specs:''' #thisBundle.totalSuites#/#thisBundle.totalSpecs#
* '''Pass:''' #thisBundle.totalPass#
* '''Failures:''' #thisBundle.totalFail#
* '''Errors:''' #thisBundle.totalError#
* '''Skipped:''' #thisBundle.totalSkipped#

#chr(10)#

<!-- Global Error --->
<cfif !isSimpleValue( thisBundle.globalException )>
== Global Bundle Exception ==
* #thisBundle.globalException.type#:#thisBundle.globalException.message#:#thisBundle.globalException.detail#
<pre>#thisBundle.globalException.stacktrace#</pre>
</cfif>

<cfloop array="#thisBundle.suiteStats#" index="suiteStats">
#genSuiteReport( suiteStats, thisBundle )#
</cfloop>

</cfloop>

<!--- Recursive Output --->
<cfscript>
function genSuiteReport( suiteStats, bundleStats, level = 2 ) output="false" {
    var headings = repeatString( "=", arguments.level );
    var nl       = chr( 10 );

    savecontent variable="local.report" {
        writeOutput( nl & nl & nl );
        writeOutput( headings & " " & arguments.suiteStats.name & " (" & arguments.suiteStats.totalDuration & " ms) " & headings & " " & nl & nl );
        arguments.level++;
        writeOutput( nl & nl );

        for ( local.thisSpec in arguments.suiteStats.specStats ) {
            writeOutput( nl );
            writeOutput( "<p>" & local.thisSpec.displayName & " (" & local.thisSpec.totalDuration & " ms)</p>" & nl & nl );

            if ( local.thisSpec.status == "failed" ) {
                writeOutput( nl );
                writeOutput( "* '''" & encodeForHTML( local.thisSpec.failMessage ) & "'''" & nl );
                writeOutput( "<pre>" & local.thisSpec.failOrigin.toString() & "</pre>" & nl );
            }
            writeOutput( nl & nl );

            if ( local.thisSpec.status == "error" ) {
                writeOutput( nl );
                writeOutput( "* '''" & encodeForHTML( local.thisSpec.error.message ) & "'''" & nl );
                writeOutput( "<pre>" & local.thisSpec.error.stacktrace & "</pre>" & nl );
            }
            writeOutput( nl );
        }
        writeOutput( nl & nl & nl );

        // Do we have nested suites
        if ( arrayLen( arguments.suiteStats.suiteStats ) ) {
            writeOutput( nl );
            for ( local.nestedSuite in arguments.suiteStats.suiteStats ) {
                writeOutput( nl );
                writeOutput( genSuiteReport( local.nestedSuite, arguments.bundleStats, arguments.level ) & nl );
            }
            writeOutput( nl );
        }
        writeOutput( nl & nl & nl );
    }

    return local.report;
}
</cfscript>
</cfoutput>
