<cfsetting showdebugoutput="false" >
<cfscript>
r = new testbox.system.TestBox( directory={ 
		mapping = "testbox.test.specs", 
		recurse = true,
		filter = function( path ){ return true; }
});

</cfscript>
<cfoutput>#r.run(reporter="simple")#</cfoutput>