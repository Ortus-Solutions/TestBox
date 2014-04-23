<cfsetting showdebugoutput="false" >
<!--- Directory Runner --->
<cfset r = new testbox.system.TestBox( directory="testbox.test.specs" ) >
<cfoutput>#r.run(reporter="simple")#</cfoutput>