/**
 * Copyright Since 2005 Ortus Solutions, Corp
 * www.ortussolutions.com
 */
component {

	this.name                   = "TestBox Development Suite";
	this.sessionManagement      = true;
	// Local mappings
	this.mappings[ "/testbox" ] = getDirectoryFromPath( getCurrentTemplatePath() );

}
