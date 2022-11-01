/**
 * ********************************************************************************
 * Copyright Ortus Solutions, Corp
 * www.ortussolutions.com
 * ********************************************************************************
 * I turn a query of coverage data into stats
 */
component accessors="true" {

    /**
     * Specify a struct of options for the code coverage report.
     * Most importantly, the outputDir where we can find the .json report file.
     */
    property name="reportOptions" type="struct";

    /**
     * Full path to the .json report file.
     */
    property name="CoverageReportFile" type="string";

    public component function init( struct reportOptions = {} ){
        setReportOptions( setDefaultOptions( arguments.reportOptions ) );
        setCoverageReportFile( getReportOptions().outputDir & "coverageReport.json" );
        return this;
    }

    /**
     * Set up the coverage report - wipes any old coverage report.json file.
     * 
     * You'll want to run this from a testbox "Batch Runner" -
     * i.e. a testbox runner which fires _separate requests_ to execute all Testbox specs sequentially.
     * 
     * This helps avoid out-of-memory errors with especially large code bases and/or test bundles.
     */
    public function beginCoverageReport(){
        /**
         * Ensure the coverage report is wiped clean.
         */
        if ( fileExists( getCoverageReportFile() ) ){
            fileDelete( getCoverageReportFile() );
        }
    }

    /**
     * Finish collecting coverage stats.
     */
    public function endCoverageReport(){
        /**
         * Currently does nothing...
         */
    }

    /**
     * Begin processing coverage data IF batching enabled.
     * 
     * @coverageQuery The result from CoverageGenerator's generateData() method.
     * 
     * @returns an aggregated, FULL report of all test coverage data accumulated to this point.
     */
    public any function processCoverageReport( required any coverageQuery ){
        if ( !getReportOptions().isBatched ){
            return arguments.coverageQuery;
        }

        return aggregateCoverageData( arguments.coverageQuery );
    }

    /**
     * TESTBOX multi-step coverage report.
     * 
     * Each test run coverage report is saved to a JSON file at conclusion.
     * That JSON file is merged into the existing 
     *
     * @coverageQuery The result from CoverageGenerator's generateData() method.
     * @returns an aggregated, FULL report of all test coverage data accumulated to this point.
     */
    private function aggregateCoverageData( required any coverageQuery ){
        if ( fileExists( getCoverageReportFile() ) ){
            var currentCoverage = queryToStruct( arguments.coverageQuery );
            var totalCoverage = readCoverageFromReportFile();

            for( var filepath in currentCoverage ){
                var value = currentCoverage[ filepath ];
                if ( totalCoverage.keyExists( filepath ) ){
                    var amended = totalCoverage[ filepath ];
                    // UPDATE LINE DATA
                    amended[ "lineData" ] = amended[ "lineData" ].map(function( line, lineCoveredValue ){
                        // if it's covered in the latest coverage check, use that value. Otherwise use value from file.
                        if ( structKeyExists( value[ "lineData" ], line ) && value[ "lineData" ][ line ] > 0 ){
                            return value[ "lineData" ][ line ];
                        }
                        return lineCoveredValue;
                    });
                    // SUM
                    amended[ "numCoveredLines" ] = amended[ "lineData" ].reduce( function( coveredCount, line, covered ){
                        if ( covered > 0 ){ coveredCount++; }
                        return coveredCount;
                    }, 0 );
                    // NEW CALC:
                    if ( amended[ "numExecutableLines" ] > 0 ){
                        amended[ "percCoverage" ] = amended[ "numCoveredLines" ] / amended[ "numExecutableLines" ];
                    } else {
                        amended[ "percCoverage" ] = 1;
                    }
                    totalCoverage[ filepath ] = amended;
                } else {
                    totalCoverage[ filepath ] = value;
                }
            }

            /**
             * After combining the previous coverage report with the current coverage query data,
             * we save it as JSON to aggregate with the next test run.
             */
            fileWrite( getCoverageReportFile(), serializeJSON( totalCoverage, false, false ) );

            // and convert back to a query for consumption in CoverageStats.cfc
            arguments.coverageQuery = structToQuery( totalCoverage );
        } else {
            /**
             * If no previous coverage data exists, we simply export the current coverage query to a struct
             * and save as json for future test runs to consume.
             */
            fileWrite( getCoverageReportFile(), serializeJSON( queryToStruct( arguments.coverageQuery ), false, false ) );
        }

        return arguments.coverageQuery;
    }

    /**
     * Read test coverage report from .json file and return as a struct.
     * 
     * @returns a struct where `key` is the filePath and the value is each row from the coverage data query.
     */
    private struct function readCoverageFromReportFile(){
        return deSerializeJSON( fileRead( getCoverageReportFile() ) )
            .reduce( function( result, key, row ) {
                if ( !result.keyExists( key ) ){
                    result[ key ] = row;
                }
                return result;
            }, {} );
    }

    /**
     * Convert coverage key/value struct back to query for Testbox consumption.
     *
     * @coverage struct of coverage data in filePath = data struct format.
     */
    private any function structToQuery( required struct coverage ){
        return arguments.coverage.reduce( function( result, key, row ){
            if ( isArray( row ) ){
                return result;
            }
            row.each(function( columnName ) {
                if ( !result.keyExists( columnName ) ) {
                    result.addColumn( columnName, [] );
                }
            });
            result.addRow(row);
            return result;
        }, queryNew( "" ) );
    }

    /**
     * Convert coverage query to a struct so we can de-dupe and serialize to JSON.
     * 
     * @returns a de-duplicated struct where the key is the relativeFilePath from the coverage data.
     */
    private struct function queryToStruct( required any coverage ){
        return arguments.coverage.reduce( function( result, row ) {
            var key = row[ "relativeFilePath" ];
            if ( !result.keyExists( key ) ){
                result[ key ] = row;
            }
            return result;
        }, {} );
    }

    /**
     * Set sane defaults for coverage report options.
     *
     * @opts The options to validate and extend/default.
     */
    private struct function setDefaultOptions( struct opts = {} ){
        if( isNull( opts.outputDir ) ){
            opts.outputDir = "";
        }
        if( isNull( opts.isBatched ) ){
            opts.isBatched = false;
        }
        return opts;
    }
}