<cfset totalIndex = 1>
<cfoutput>1..#results.getTotalSpecs()##chr(13)#
<cfloop array="#variables.bundleStats#" index="thisBundle">
<cfloop array="#thisBundle.suiteStats#" index="suiteStats">#genSuiteReport( suiteStats, thisBundle )#</cfloop>
</cfloop>
</cfoutput>

<!--- LOCAL FUNCTIONS --->
<cfscript>
function getStatusBit( status ) output="false" {
    switch ( arguments.status ) {
        case "failed": {
            return "not ok";
        }
        case "error": {
            return "not ok";
        }
        case "skipped": {
            return "ok";
        }
        default: {
            return "ok";
        }
    }
}
</cfscript>

<cfscript>
function renderOrigin( origin ) output="false" {
    var sb = createObject( "java", "java.lang.StringBuilder" ).init( "" );
    for ( var thisRow in arguments.origin ) {
        for ( var thisKey in thisRow ) {
            sb.append( "## #thisKey#:#thisRow[ thisKey ]# #chr( 13 )#" );
        }
    }
    return sb.toString();
}
</cfscript>

<!--- Recursive Output --->
<cfscript>
function genSuiteReport( suiteStats, bundleStats ) output="false" {
    savecontent variable="local.report" {
        for ( local.thisSpec in arguments.suiteStats.specStats ) {
            writeOutput( getStatusBit( local.thisSpec.status ) & " " & totalIndex & " " & arguments.suiteStats.name & " " & local.thisSpec.displayName );
            if ( local.thisSpec.status == "failed" ) {
                writeOutput( " ## TODO " & local.thisSpec.failMessage & " " & chr( 13 ) & chr( 10 ) & renderOrigin( local.thisSpec.failorigin ) );
            } else if ( local.thisSpec.status == "skipped" ) {
                writeOutput( " ## SKIP " & chr( 13 ) );
            } else if ( local.thisSpec.status == "error" ) {
                writeOutput( " ## TODO " & local.thisSpec.error.message & " " & chr( 13 ) & chr( 10 ) );
                writeOutput( "## " & replace( local.thisSpec.error.stackTrace, chr( 10 ), chr( 13 ) & "## ", "all" ) & " " & chr( 13 ) );
            } else {
                writeOutput( chr( 13 ) );
            }
            writeOutput( chr( 10 ) );
            totalIndex++;
        }
        if ( arrayLen( arguments.suiteStats.suiteStats ) ) {
            writeOutput( chr( 10 ) );
            for ( local.nestedSuite in arguments.suiteStats.suiteStats ) {
                writeOutput( genSuiteReport( local.nestedSuite, arguments.bundleStats ) );
            }
            writeOutput( chr( 10 ) );
        }
        writeOutput( chr( 10 ) & chr( 10 ) );
    }
    return local.report;
}
</cfscript>
