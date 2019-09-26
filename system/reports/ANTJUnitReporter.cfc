/**
* Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
* www.ortussolutions.com
* ---
* A JUnit reporter for use with the ANT junitreport task, which uses an old version of JUnit formatting.
*/
component extends="BaseReporter"{

	function init(){ return this; }

	/**
	* Get the name of the reporter
	*/
	function getName(){
		return "ANTJUnit";
	}

	/**
	* Do the reporting thing here using the incoming test results
	* The report should return back in whatever format they desire and should set any
	* Specifc browser types if needed.
	* @results.hint The instance of the TestBox TestResult object to build a report on
	* @testbox.hint The TestBox core object
	* @options.hint A structure of options this reporter needs to build the report with
	*/
	any function runReport(
		required testbox.system.TestResult results,
		required testbox.system.TestBox testbox,
		struct options={}
	){
		getPageContextResponse().setContentType( "application/xml" );

		return toJUnit( arguments.results );
	}

	private function toJUnit( required results ){
		var buffer = createObject("java", "java.lang.StringBuilder").init('');
		var r = arguments.results;

		// build top level test suites container
		buffer.append('<testsuites>');

		// iterate over bundles
		var bundlestats = r.getBundleStats();
		for( var thisBundle in bundleStats ){
			// excluding "empty" test suites
			if (structKeyExists(url, 'testBundles') AND len( url.testBundles ) and !listFindNoCase( url.testBundles, thisBundle.path )){
				continue;
			}
			// build test suite header
			buffer.append('<testsuite
			tests="#thisBundle.totalSpecs#"
			failures="#thisBundle.totalFail#"
			errors="#thisBundle.totalError#"
			skipped="#thisBundle.totalSkipped#"
			time="#thisBundle.totalDuration/1000#"
			timestamp="#dateFormat(now(),"yyyy-mm-dd")#T#timeFormat(now(),"HH:mm:ss")#"
			hostname="#xmlFormat( cgi.remote_host )#"
			package="#xmlFormat( thisBundle.path )#"
			name="#xmlFormat( thisBundle.name )#"
			>');

			// build out properties
			buildProperties( buffer );

			// build out tests, even if nested, treat as single threaded
			buildTestSuites( buffer, r, thisBundle, thisBundle.suiteStats );

			// close header
			buffer.append("</testsuite>");
		}

		buffer.append('</testsuites>');

		return buffer.toString();
	}

	private function buildTestSuites(
		required buffer,
		required results,
		required bundleStats,
		required suiteStats,
		parentName=""
	){

		var r 		 = arguments.results;
		var out 	 = arguments.buffer;
		var stats 	 = arguments.suiteStats;
		var index	 = 1;

		// iterate over
		for( var thisSuite in arguments.suiteStats ){
			// build out full suite name
			var fullName = xmlFormat( arguments.parentName & thisSuite.name );

			// build out test cases
			for( var thisSpecStat in thisSuite.specStats ){
				buildTestCase( out, r, thisSpecStat, arguments.bundleStats, fullName );
			}

			// Check embedded suites
			if( arrayLen( thisSuite.suiteStats ) ){
				buildTestSuites( out, r, arguments.bundlestats, thisSuite.suiteStats, xmlFormat( fullName & " " ) );
			}
		}

	}

	private function buildTestCase( required buffer, required results, required specStats, required bundleStats, required fullName ){
		var r 		= arguments.results;
		var out 	= arguments.buffer;
		var stats 	= arguments.specStats;

		// build test case
		out.append('<testcase
			name="#xmlFormat( fullName & " " & stats.name )#"
			time="#stats.totalDuration/1000#"
			classname="#arguments.bundleStats.path#"
			>');

		switch( stats.status ){
			case "failed" : {
				out.append('<failure message="#xmlformat( stats.failMessage )#"><![CDATA[
					#stats.failorigin.toString()#
					]]></failure>');
				break;
			}
			case "skipped" : {
				out.append('<skipped></skipped>');
				break;
			}
			case "error" : {
				out.append('<error type="#xmlFormat( stats.error.type )#" message="#xmlformat( stats.error.message )#"><![CDATA[
					#stats.error.stackTrace.toString()#
					]]></error>');
				break;
			}
		}

		out.append('</testcase>');
	}

	private function buildProperties( required buffer ){
		var out 	= arguments.buffer;

		out.append("<properties>");

		genPropsFromCollection( out, server.coldfusion );
		genPropsFromCollection( out, server.os );
		if( structKeyExists( server, "lucee" ) ){
			genPropsFromCollection( out, server.lucee );
		}
		genPropsFromCollection( out, cgi );

		out.append("</properties>");
	}

	private function genPropsFromCollection(required buffer, required collection ){
		for( var thisProp in arguments.collection ){
			//null check
			if( isNull( arguments.collection[ thisProp ] ) ){
				continue;
			}
			if( isSimpleValue( arguments.collection[ thisProp ] ) ){
				// This is for a nasty Lucee regression where server.os.MacAddress is null, yet isNull() checks say it isn't. 
				// Try/catch is the only way to detect this right now :/
				// Regression known to exist in Lucee 5.2.8.50
				try {
					arguments.buffer.append( '<property name="#xmlFormat( lcase( thisProp ) )#" value="#xmlFormat( arguments.collection[ thisProp ] )#" />' );
				} catch( any e ) {
					arguments.buffer.append( '<property name="#xmlFormat( lcase( thisProp ) )#" value="" />' );					
				}
			}
			else if( isArray( arguments.collection[ thisProp ] ) OR
					 isStruct( arguments.collection[ thisProp ] ) OR
					 isQuery( arguments.collection[ thisProp ] ) ){
				arguments.buffer.append( '<property name="#xmlFormat( lcase( thisProp ) )#" value="#xmlFormat( arguments.collection[ thisProp ].toString() )#" />' );
			}
		}
	}

}
