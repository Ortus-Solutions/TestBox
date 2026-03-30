/**
 * Regression tests for MetadataSmokeReporter (HTML output for Smoke Test runner).
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "MetadataSmokeReporter", function(){
			it( "getName returns MetadataSmoke", function(){
				var rep = new testbox.system.reports.MetadataSmokeReporter();
				expect( rep.getName() ).toBe( "MetadataSmoke" );
			} );

			it( "renderHtml returns HTML with title and summary links", function(){
				var tb   = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var rep  = new testbox.system.reports.MetadataSmokeReporter();
				var html = rep.renderHtml(
					tb,
					{
						"smokeResult" : {
							"success"           : true,
							"errorMessage"      : "",
							"componentCount"    : 0,
							"discovered"        : 0,
							"attempted"         : 0,
							"skippedComponents" : []
						},
						"runnerErrors"       : [],
						"ran"                : true,
						"manifestPath"       : "/tests/specs/manifest.json",
						"invokeEnabled"      : false,
						"smokeRunnerSummary" : {
							"testsUrl"              : "/tests/runner.cfm",
							"smokeRunUrl"           : "/tests/runner.cfm?metadataSmoke=true",
							"smokeRunUrlWithInvoke" : "/tests/runner.cfm?metadataSmoke=true&metadataSmokeInvoke=true"
						}
					},
					true
				);
				expect( len( html ) ).toBeGT( 100 );
				expect( html ).toInclude( "Smoke Test" );
				expect( html ).toInclude( "dummy invoke" );
				expect( html ).toInclude( "DOCTYPE" );
			} );

			it( "renderHtml includes runner errors when present", function(){
				var tb   = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
				var rep  = new testbox.system.reports.MetadataSmokeReporter();
				var html = rep.renderHtml(
					tb,
					{
						"smokeResult"        : {},
						"runnerErrors"       : [ "missing manifest" ],
						"ran"                : false,
						"manifestPath"       : "",
						"invokeEnabled"      : false,
						"smokeRunnerSummary" : {}
					},
					true
				);
				expect( html ).toInclude( "Cannot run Smoke Test" );
				expect( html ).toInclude( "missing manifest" );
			} );
		} );
	}

}
