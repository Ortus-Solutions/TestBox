<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************
----------------------------------------------------------------------->
<cfcomponent output="false">

	<cfscript>

	this.name = "TestBox API Docs" & hash(getCurrentTemplatePath());
	this.sessionManagement 	= true;
	this.sessionTimeout 	= createTimeSpan(0,0,1,0);
	this.setClientCookies 	= true;

	// API Root
	API_ROOT = getDirectoryFromPath( getCurrentTemplatePath() );
	// ColdBox Root
	TESTBOX_ROOT = REReplaceNoCase( API_ROOT, "apidocs(\\|\/)$", "" );
	// Core Mappings
	this.mappings[ "/colddoc" ]  = API_ROOT;
	// Standlone mappings
	this.mappings[ "/mockbox" ]  = ( structKeyExists( url, "mockbox_root" )  ? url.mockbox_root  : TESTBOX_ROOT );
	this.mappings[ "/testbox" ]  = ( structKeyExists( url, "testbox_root" )  ? url.testbox_root  : TESTBOX_ROOT );
	</cfscript>

</cfcomponent>