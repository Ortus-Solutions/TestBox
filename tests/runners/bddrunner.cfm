<cfsetting showdebugoutput="false" >
<cfparam name="url.reporter" default="simple"> 
<!--- One runner --->
<cfset r = new testbox.system.TestBox( "testbox.tests.specs.BDDTest" ) >
<cfoutput>#r.run(reporter="#url.reporter#")#</cfoutput>