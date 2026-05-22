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

			it( "compact embed rerun labels: primary Re-run when last run was normal smoke", function(){
				var hadInvoke  = structKeyExists( url, "metadataSmokeInvoke" );
				var prevInvoke = hadInvoke ? url.metadataSmokeInvoke : "";
				try {
					if ( hadInvoke ) {
						structDelete( url, "metadataSmokeInvoke" );
					}
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
							"manifestPath"       : "",
							"invokeEnabled"      : false,
							"smokeRunnerSummary" : {
								"testsUrl"              : "/tests/runner.cfm",
								"smokeRunUrl"           : "/tests/runner.cfm?metadataSmoke=true",
								"smokeRunUrlWithInvoke" : "/tests/runner.cfm?metadataSmoke=true&metadataSmokeInvoke=true"
							},
							"smokeEmbedCompact"     : true,
							"fullPage"              : false,
							"smokeEmbedRerunLabels" : true
						},
						true
					);
					expect( html ).toInclude( "fa-redo" );
					expect( html ).toInclude( "Re-run Smoke Test" );
					expect( html ).toInclude( "fa-bolt" );
					expect( html ).toInclude( "Smoke Test with Dummy Invoke" );
					expect( html ).notToInclude( "Re-run Smoke Test with Dummy Invoke" );
				} finally {
					if ( hadInvoke ) {
						url.metadataSmokeInvoke = prevInvoke;
					}
				}
			} );

			it( "compact embed rerun labels: dummy Re-run when last run used dummy invoke (URLs match)", function(){
				var hadInvoke  = structKeyExists( url, "metadataSmokeInvoke" );
				var prevInvoke = hadInvoke ? url.metadataSmokeInvoke : "";
				try {
					url.metadataSmokeInvoke = true;
					var tb                  = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
					var rep                 = new testbox.system.reports.MetadataSmokeReporter();
					var sameInvokeUrl       = "/tests/runner.cfm?metadataSmoke=true&metadataSmokeInvoke=true";
					var html                = rep.renderHtml(
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
							"manifestPath"       : "",
							"invokeEnabled"      : true,
							"smokeRunnerSummary" : {
								"testsUrl"              : "/tests/runner.cfm",
								"smokeRunUrl"           : sameInvokeUrl,
								"smokeRunUrlWithInvoke" : sameInvokeUrl
							},
							"smokeEmbedCompact"     : true,
							"fullPage"              : false,
							"smokeEmbedRerunLabels" : true
						},
						true
					);
					expect( html ).toInclude( "Re-run Smoke Test with Dummy Invoke" );
					expect( html ).toInclude( "fa-redo" );
					expect( html ).notToInclude( "fa-search" );
				} finally {
					if ( hadInvoke ) {
						url.metadataSmokeInvoke = prevInvoke;
					} else {
						structDelete( url, "metadataSmokeInvoke" );
					}
				}
			} );

			it( "compact embed rerun labels: two URLs differ after dummy invoke — primary Run, outline Re-run dummy", function(){
				var hadInvoke  = structKeyExists( url, "metadataSmokeInvoke" );
				var prevInvoke = hadInvoke ? url.metadataSmokeInvoke : "";
				try {
					url.metadataSmokeInvoke = true;
					var tb                  = new testbox.system.TestBox( options = { coverage : { enabled : false } } );
					var rep                 = new testbox.system.reports.MetadataSmokeReporter();
					var html                = rep.renderHtml(
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
							"manifestPath"       : "",
							"invokeEnabled"      : true,
							"smokeRunnerSummary" : {
								"testsUrl"              : "/tests/runner.cfm",
								"smokeRunUrl"           : "/tests/runner.cfm?metadataSmoke=true",
								"smokeRunUrlWithInvoke" : "/tests/runner.cfm?metadataSmoke=true&metadataSmokeInvoke=true"
							},
							"smokeEmbedCompact"     : true,
							"fullPage"              : false,
							"smokeEmbedRerunLabels" : true
						},
						true
					);
					expect( html ).toInclude( "fa-search" );
					expect( html ).toInclude( "Run Smoke Test" );
					expect( html ).toInclude( "Re-run Smoke Test with Dummy Invoke" );
				} finally {
					if ( hadInvoke ) {
						url.metadataSmokeInvoke = prevInvoke;
					} else {
						structDelete( url, "metadataSmokeInvoke" );
					}
				}
			} );
		} );
	}

}
