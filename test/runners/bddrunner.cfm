<cfsetting showdebugoutput="false" >
<cfparam name="url.reporter" default="simple"> 
<!--- One runner --->
<cfset r = new testbox.system.TestBox( "testbox.test.specs.BDDTest" ) >
<cfoutput>#r.run(reporter="#url.reporter#")#</cfoutput>