<cfoutput>#getHeaderBanner( testbox )#
<!--- Iterate over each bundle tested --->
<cfloop array="#variables.bundleStats#" index="thisBundle">
<!--- Skip if not in the includes list --->
<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
<cfcontinue>
</cfif>
_____________________________________________________________
#space()#
<!--- Bundle Name --->
#getBundleIndicator( thisBundle )##thisBundle.name# (#thisBundle.totalDuration# ms)
<!--- Bundle Report --->
[Passed: #thisBundle.totalPass#] [Failed: #thisBundle.totalFail#] [Errors: #thisBundle.totalError#] [Skipped: #thisBundle.totalSkipped#] [Suites/Specs: #thisBundle.totalSuites#/#thisBundle.totalSpecs#]
#space()#<!--- Bundle Exception Output --->
<cfif !isSimpleValue( thisBundle.globalException )>
#space()#
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
<GLOBAL BUNDLE EXCEPTION>
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#space()#
#thisBundle.globalException.type#:#thisBundle.globalException.message#:#thisBundle.globalException.detail#
<cfloop array="#thisBundle.globalException.tagContext#" item="thisContext">
	<cfif findNoCase( thisBundle.path, reReplace( thisContext.template, "(/|\\)", ".", "all" ) )>
	#thisContext.template#:#thisContext.line#
	#thisContext.codePrintPlain ?: ""#
	</cfif>
</cfloop>
#space()#
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
</cfif><!--- Generate Suite Reports --->
<cfloop array="#thisBundle.suiteStats#" index="suiteStats">#genSuiteReport( suiteStats, thisBundle )#</cfloop>
</cfloop>
<!--- Final Stats --->
#space()#
#space()#
#getDividerLine()#
Final Stats
#getDividerLine()#
#space()#
[Passed: #results.getTotalPass()#] [Failed: #results.getTotalFail()#] [Errors: #results.getTotalError()#] [Skipped: #results.getTotalSkipped()#] [Bundles/Suites/Specs: #results.getTotalBundles()#/#results.getTotalSuites()#/#results.getTotalSpecs()#]
<!--- Code Coverage --->
<cfif results.getCoverageEnabled()>
#space()#
#getDividerLine()#
Code Coverage
#getDividerLine()#
[Total Coverage: #numberFormat( results.getCoverageData().stats.percTotalCoverage*100, '9.9' )#%]
#space()#
</cfif>
<!--- Final Test Stats --->
#space()#
TestBox: #space( 6 )# v#testbox.getVersion()#
Duration: #space( 5 )# #results.getTotalDuration()# ms
CFML Engine: #space( 2 )# #results.getCFMLEngine()# #results.getCFMLEngineVersion()#
Labels: #space( 7 )# #arrayToList( results.getLabels() )#<cfif !arrayLen( results.getLabels() )>None</cfif>
#space()#

<!--- Legend --->
√ Passed #space( 2 )# - Skipped #space( 2 )# !! Exception/Error #space( 2 )# X Failure
<!--- Generate Suite Reports Recursively --->
<cfscript>
function genSuiteReport( suiteStats, bundleStats, level = 0 ) output="false" {
    setting enablecfoutputonly="true";
    var tabs     = repeatString( tab(), arguments.level );
    var tabsNext = repeatString( tab(), arguments.level + 1 );
    savecontent variable="local.report" {
        // Suite Name
        writeOutput( tabs & "( " & getStatusIndicator( arguments.suiteStats.status ) & " ) " & arguments.suiteStats.name & " " & chr( 13 ) );
        // Specs
        for ( local.thisSpec in arguments.suiteStats.specStats ) {
            writeOutput( tabsNext & "( " & getStatusIndicator( local.thisSpec.status ) & " ) " & local.thisSpec.displayName & " (" & local.thisSpec.totalDuration & " ms) " & chr( 13 ) );
            // If Spec Failed
            if ( local.thisSpec.status == "failed" ) {
                writeOutput( space() & tabsNext & " ! Failure: " & local.thisSpec.failMessage & " " & local.thisSpec.failDetail & " " & chr( 13 ) & chr( 10 ) & chr( 9 ) & chr( 9 ) & "   " & space() & chr( 10 ) );
            }
            // If Spec Errored Out
            if ( local.thisSpec.status == "error" ) {
                writeOutput( space() & chr( 10 ) & " " & tabsNext & " X Error: " & local.thisSpec.error.message & " " & local.thisSpec.error.detail & " " & chr( 13 ) );
                for ( thisStack in local.thisSpec.error.tagContext ) {
                    // Only show non testbox template paths
                    if ( !reFindNoCase( "testbox(\/|\\)system(\/|\\)", thisStack.template ) ) {
                        writeOutput( tabsNext & "-> " & thisStack.template & ":" & thisStack.line & chr( 10 ) );
                    }
                }
                writeOutput( chr( 10 ) & space() & chr( 10 ) & left( local.thisSpec.error.stackTrace, 1500 ) & " " & chr( 13 ) & chr( 13 ) & chr( 10 ) & space() & chr( 10 ) );
            }
        }
        // Do we have nested suites
        if ( arrayLen( arguments.suiteStats.suiteStats ) ) {
            for ( local.nestedSuite in arguments.suiteStats.suiteStats ) {
                writeOutput( genSuiteReport( local.nestedSuite, arguments.bundleStats, arguments.level + 1 ) );
            }
        }
    }
    return local.report;
}
</cfscript>
</cfoutput>
