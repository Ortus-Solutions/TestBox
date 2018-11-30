<!--- 
	Use this runner.cfm instead of you want to make use of the Code Coverage functionalities of TestBox
	Note, this feature requires a licensed copy of FusionRector, whcih is used to intrument your bytecode at runtime	
 --->
<cfsetting showDebugOutput="false">

<cfparam name="url.reporter" 		default="simple">
<cfparam name="url.directory" 		default="tests.specs">
<cfparam name="url.recurse" 		default="true" type="boolean">
<cfscript>

coverageGenerator = new testbox.system.reports.CodeCoverage.data.coverageGenerator();
testbox = new testbox.system.TestBox(
	directory={
		mapping = url.directory,
		recurse = url.recurse
	},
	reporter={
	    type = "CoverageReporter",
	    options = {
		  	pathToCapture = expandPath( '/root' ),
			whitelist = '',
			blacklist = '/testbox,/tests',
	    	passThroughReporter={
	    		type='simple',
	    		option={}
	    	},
	    	/*
	    	Uncomment to use the SonarQube integation
	    	sonarQube = {
				XMLOutputPath = expandpath( '/tests/sonarqube-codeCoverage.xml' )
	    	},*/
	    	browser = {
	    		OutputDir = expandPath( '/tests/CoverageBrowser' )
	    	}
	    }
	} );

// Clear stats before running tests
coverageGenerator.beginCapture();

results = testbox.run();

// Clean up after
coverageGenerator.endCapture( true );

writeoutput( results );
</cfscript>
