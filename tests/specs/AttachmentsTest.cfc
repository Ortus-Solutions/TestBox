/**
 * attach(): files attached to specs, kept in the spec stats and listed by the reporters.
 */
component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Spec attachments", function(){
			beforeEach( function(){
				variables.testbox = new testbox.system.TestBox(
					bundles = "tests.resources.attachments.AttachmentsFixture",
					options = { coverage : { enabled : false } }
				)
				variables.results = variables.testbox.runRaw()
			} )

			it( "starts every spec with no attachments and no attempts", function(){
				var stats = new testbox.system.TestResult().startSpecStats(
					{
						id          : "x",
						name        : "x",
						displayName : "x",
						focused     : false,
						skip        : false,
						labels      : []
					},
					{ id : "suite", specStats : [] }
				)
				expect( stats.attachments ).toBeArray().toBeEmpty()
				expect( stats.attempts ).toBe( 0 )
			} )

			it( "keeps the attachments of a passed spec", function(){
				var stats = findSpec( "passes with an attachment" )
				expect( stats.status ).toBe( "Passed" )
				expect( stats.attachments ).toHaveLength( 1 )
				expect( stats.attachments[ 1 ].path ).toBe( "/tmp/testbox/passed.png" )
				expect( stats.attachments[ 1 ].type ).toBe( "screenshot" )
				expect( stats.attachments[ 1 ].name ).toBe( "passed.png" )
			} )

			it( "keeps the attachments of a failed spec, with names and default types", function(){
				var stats = findSpec( "fails with attachments" )
				expect( stats.status ).toBe( "Failed" )
				expect( stats.attachments ).toHaveLength( 2 )
				expect( stats.attachments[ 1 ].name ).toBe( "The <trace>" )
				expect( stats.attachments[ 1 ].type ).toBe( "trace" )
				expect( stats.attachments[ 2 ].type ).toBe( "file" )
				expect( stats.attachments[ 2 ].name ).toBe( "notes.txt" )
			} )

			it( "keeps the attachments of a spec that errored", function(){
				var stats = findSpec( "errors with an attachment" )
				expect( stats.status ).toBe( "Error" )
				expect( stats.attachments[ 1 ].type ).toBe( "log" )
			} )

			it( "keeps the attachments of xUnit tests", function(){
				var xunit = new testbox.system.TestBox(
					bundles = "tests.resources.attachments.AttachmentsXUnitFixture",
					options = { coverage : { enabled : false } }
				).runRaw()
				var stats = xunit.getBundleStats()[ 1 ].suiteStats[ 1 ].specStats[ 1 ]
				expect( stats.attachments[ 1 ].path ).toBe( "/tmp/testbox/xunit.png" )
			} )

			it( "restores the running spec for attach() after a nested TestBox run", function(){
				expect( function(){
					attach( "/tmp/testbox/outer.txt" )
				} ).notToThrow()
			} )

			it( "refuses attach() when no spec is running", function(){
				var spec = new tests.resources.attachments.AttachmentsXUnitFixture()
				expect( function(){
					spec.attach( "/tmp/testbox/nowhere.txt" )
				} ).toThrow( "TestBox.InvalidContext" )
			} )

			it( "includes the attachments in the JSON report", function(){
				var json = deserializeJSON( new testbox.system.reports.JSONReporter().runReport( variables.results, variables.testbox, {}, true ) )
				var specs = json.bundleStats[ 1 ].suiteStats[ 1 ].specStats
				expect( specs[ 1 ].attachments[ 1 ].path ).toBe( "/tmp/testbox/passed.png" )
			} )

			it( "lists the attachments of failed specs in the text reporter", function(){
				var report = new testbox.system.reports.TextReporter().runReport( variables.results, variables.testbox )
				expect( report ).toInclude( "Attachment: notes.txt (file) /tmp/testbox/notes.txt" )
				expect( report ).toInclude( "Attachment: error.log (log) /tmp/testbox/error.log" )
				expect( report ).notToInclude( "passed.png" )
			} )

			it( "builds JUnit system-out attachment lines", function(){
				var reporter = new testbox.system.reports.BaseReporter()
				var output   = reporter.getJUnitAttachmentsOutput( findSpec( "fails with attachments" ) )
				expect( output ).toBe( "[[ATTACHMENT|/tmp/testbox/trace & more.zip]]#chr( 10 )#[[ATTACHMENT|/tmp/testbox/notes.txt]]" )
				expect( reporter.getJUnitAttachmentsOutput( { status : "Passed" } ) ).toBe( "" )
			} )

			it( "adds escaped system-out attachments to the JUnit test cases", function(){
				var reporter = new testbox.system.reports.JUnitReporter()
				makePublic( reporter, "buildTestCase" )
				var buffer = createObject( "java", "java.lang.StringBuilder" ).init( "" )
				reporter.buildTestCase(
					buffer      = buffer,
					results     = variables.results,
					specStats   = findSpec( "fails with attachments" ),
					bundleStats = variables.results.getBundleStats()[ 1 ]
				)
				var xml = buffer.toString()
				expect( xml ).toInclude( "<system-out>[[ATTACHMENT|/tmp/testbox/trace &amp; more.zip]]" )
				expect( xmlParse( "<root>#xml#</root>" ) ).toBeTypeOf( "xml" )
			} )

			it( "adds system-out attachments to the ANT JUnit test cases", function(){
				var reporter = new testbox.system.reports.ANTJUnitReporter()
				makePublic( reporter, "buildTestCase" )
				var buffer = createObject( "java", "java.lang.StringBuilder" ).init( "" )
				reporter.buildTestCase(
					buffer      = buffer,
					results     = variables.results,
					specStats   = findSpec( "passes with an attachment" ),
					bundleStats = variables.results.getBundleStats()[ 1 ],
					fullName    = "Attachments Fixture"
				)
				expect( buffer.toString() ).toInclude( "<system-out>[[ATTACHMENT|/tmp/testbox/passed.png]]</system-out>" )
			} )
		} )
	}

	/**
	 * Find the stats of a fixture spec by name.
	 *
	 * @name The spec name
	 *
	 * @return The spec stats
	 */
	private struct function findSpec( required string name ){
		for ( var spec in variables.results.getBundleStats()[ 1 ].suiteStats[ 1 ].specStats ) {
			if ( spec.name == arguments.name ) {
				return spec
			}
		}
		throw( type = "AttachmentsTest.SpecNotFound", message = "No spec named [#arguments.name#]" )
	}

}
