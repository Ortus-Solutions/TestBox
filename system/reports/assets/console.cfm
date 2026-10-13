<cfparam name="url" default="#structNew()#"><cfparam name="url.testBundles" default=""><cfoutput>#getHeaderBanner( testbox )#
<!--- Iterate over each bundle tested --->
<cfloop array="#variables.bundleStats#" index="thisBundle">
<!--- Skip if not in the includes list --->
<cfif len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )>
<cfcontinue>
</cfif>
#space()#
<!--- Bundle Name --->
#getBundleIndicator( thisBundle )# (#thisBundle.totalDuration# ms)
<!--- Bundle Report --->
[Passed: #thisBundle.totalPass#] [Failed: #thisBundle.totalFail#] [Errors: #thisBundle.totalError#] [Skipped: #thisBundle.totalSkipped#] [Suites/Specs: #thisBundle.totalSuites#/#thisBundle.totalSpecs#]
#space()#<!--- Bundle Exception Output --->
<cfif !isSimpleValue( thisBundle.globalException )>
#getAlertDivider()#
#color( "red+magenta", "<GLOBAL BUNDLE EXCEPTION>" )#
#getAlertDivider()#
#space()#
#color( "bold+white", "#thisBundle.globalException.type#:#thisBundle.globalException.message#:#thisBundle.globalException.detail#")#
<cfloop array="#thisBundle.globalException.tagContext#" item="thisContext">
<cfif findNoCase( thisBundle.path, reReplace( thisContext.template, "(/|\\)", ".", "all" ) )>
#color( "red+bold", "#thisContext.template#:#thisContext.line#" )#
#color( "bold+white", "#thisContext.codePrintPlain ?: ""#")#
</cfif>
</cfloop>
#getAlertDivider()#
</cfif><!--- Generate Suite Reports --->
<cfloop array="#thisBundle.suiteStats#" index="suiteStats">#genSuiteReport( suiteStats, thisBundle )#</cfloop>
</cfloop>
<!--- Final Stats --->
#getDividerLine( width = 80, style = "bold+white" )#
#color( "bold+cyan", "Final Stats" )#
#getDividerLine( width = 80, style = "bold+white" )#
[ ✅ #color( "green", "Passed:" )# #color( "white", results.getTotalPass() )# ]
[ ❌ #color( "red", "Failed:" )# #color( "white", results.getTotalFail() )# ]
[ 💥 #color( "magenta", "Errors:" )# #color( "white", results.getTotalError() )# ]
[ ⏭️  #color( "yellow", "Skipped:" )# #color( "white", results.getTotalSkipped() )# ]
[ ⏱️  #color( "white+dim", "Duration:" )# #color( "white", "#numberFormat( results.getTotalDuration() )# ms" )# ]
[ 📦 #color( "white+dim", "Bundles/Suites/Specs:" )# #color( "white", results.getTotalBundles() & "/" & results.getTotalSuites() & "/" & results.getTotalSpecs() )# ]
[ 🏷️  #color( "white+dim", "Labels:")# #arrayToList( results.getLabels() )#<cfif !arrayLen( results.getLabels() )>None</cfif>]
#getDividerLine( width = 80, style = "bold+white" )#
<cfif results.getCoverageEnabled()>
#space()#
=================================================================================
Code Coverage
=================================================================================
[Total Coverage: #numberFormat( results.getCoverageData().stats.percTotalCoverage*100, '9.9' )#%]
#space()#
</cfif>
#color( "dim", "TestBox:" )# #space( 1 )# v#testbox.getVersion()#
#color( "dim", "Engine:" )# #space( 2 )# #results.getCFMLEngine()# #results.getCFMLEngineVersion()#
<cfscript>
function genSuiteReport( suiteStats, bundleStats, level = 0 ) output="false" {
    setting enablecfoutputonly="true";
    var tabs     = repeatString( tab(), arguments.level );
    var tabsNext = repeatString( tab(), arguments.level + 1 );
    // Skip suites with no non-skipped content when hideSkipped is enabled.
    // We can't rely on suiteStats.status alone because TestBox may mark a suite as
    // "Skipped" even when it contains a passed spec (filter-specs bug), or mark a
    // suite as "Passed" when all its specs are skipped. Instead, check the rolled-up
    // counters: if totalPass + totalFail + totalError == 0, the suite has no
    // non-skipped specs at any nesting level.
    if ( variables.hideSkipped && ( arguments.suiteStats.totalPass + arguments.suiteStats.totalFail + arguments.suiteStats.totalError ) == 0 ) {
        return "";
    }
    savecontent variable="local.report" {
        // Suite Name
        writeOutput( tabs & getStatusIndicator( arguments.suiteStats.status ) & " " & printByStatus( arguments.suiteStats.status, arguments.suiteStats.name ) & " " & chr( 13 ) );
        // Specs
        for ( local.thisSpec in arguments.suiteStats.specStats ) {
            if ( variables.hideSkipped && local.thisSpec.status == "skipped" ) {
                continue;
            }
            writeOutput( tabsNext & getStatusIndicator( local.thisSpec.status ) & " " & printByStatus( local.thisSpec.status, local.thisSpec.displayName ) & " " & color( "dim", "(" & local.thisSpec.totalDuration & " ms)" & getAttemptsNote( local.thisSpec ) ) & " " & chr( 13 ) );
            // If Spec Failed
            if ( local.thisSpec.status == "failed" ) {
                writeOutput( space() & tabsNext & " ! Failure: " & local.thisSpec.failMessage & " " & local.thisSpec.failDetail & " " & chr( 13 ) & chr( 10 ) & chr( 9 ) & chr( 9 ) & "   " & space() & chr( 10 ) );
            }
            // If Spec Errored Out
            if ( local.thisSpec.status == "error" ) {
                writeOutput( space() & chr( 10 ) & " " & tabsNext & " " & color( "bold+magenta", "💥 Error: " & local.thisSpec.error.message & " " & local.thisSpec.error.detail & " " & chr( 13 ) ) );
                for ( thisStack in local.thisSpec.error.tagContext ) {
                    // Only show non testbox template paths
                    if ( !reFindNoCase( "testbox(\/|\\)system(\/|\\)", thisStack.template ) ) {
                        writeOutput( tabsNext & "  " & color( "bold+red", "-> " & thisStack.template & ":" & thisStack.line ) & chr( 10 ) );
                    }
                }
                writeOutput( chr( 10 ) & space() & chr( 10 ) & color( "bold+white", left( local.thisSpec.error.stackTrace, 1500 ) ) & " " & chr( 13 ) & chr( 13 ) & chr( 10 ) & space() & chr( 10 ) );
            }
            // Attachments of failed specs
            if ( listFindNoCase( "failed,error", local.thisSpec.status ) ) {
                for ( local.thisAttachment in getSpecAttachments( local.thisSpec ) ) {
                    writeOutput( tabsNext & "   " & color( "cyan", "📎 " & local.thisAttachment.name & " (" & local.thisAttachment.type & ") " & local.thisAttachment.path ) & " " & chr( 13 ) & chr( 10 ) );
                }
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