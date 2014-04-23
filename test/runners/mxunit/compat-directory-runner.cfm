<cfset r = new testbox.system.compat.runner.DirectoryTestSuite()
				.run( directory="#expandPath( '/testbox/test/specs' )#", 
					  componentPath="testbox.test.specs" )>
<cfoutput>#r.getResultsOutput( 'simple' )#</cfoutput>
