<cfsetting showdebugoutput="false" >
<cfparam name="url.reporter" default="simple"> 
<!--- One runner --->
<cfset r = new testbox.system.TestBox( bundles="testbox.test.specs.AssertionsTest", labels="railo" ) >
<cfoutput>#r.run(reporter="#url.reporter#")#</cfoutput>