<cfsetting showdebugoutput="false" >
<cfset r = new testbox.system.TestBox( "testbox.test.specs.MXUnitCompatTest" ) >
<cfoutput>#r.run()#</cfoutput>