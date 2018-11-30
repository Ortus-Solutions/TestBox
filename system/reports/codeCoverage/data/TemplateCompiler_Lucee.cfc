/**
* ********************************************************************************
* Copyright Ortus Solutions, Corp
* www.ortussolutions.com
* ********************************************************************************
* I contain the logic to force a compilation on Railo/Lucee.
* I will not compile on Adobe ColdFusion, so I require my own CFC.
*/
component accessors=true {
	
	function init() {
		// Create this class for some static helper methods
		variables.PageSourceImpl = createObject( 'java', 'lucee.runtime.PageSourceImpl' );
		return this;
	}
			
	/** 
    * Call me to force a .cfm or .cfc to be compiled and the class loaded into memory
    */
	function compileAndLoad( required filePath ) {
		// Attempt to compile and load the class
		PageSourceImpl.best( getPageContext().getPageSources( makePathRelative( arguments.filePath ) ) ).loadPage( getPageContext(), true );		
	}
			
	    
    /** 
    * Accepts an absolute path and returns a relative path
    * Does NOT apply any canonicalization 
    */
    private string function makePathRelative( required string absolutePath ) {
    	if( !isWindows() ) { 
    		return makePathRelativeLinux( arguments.absolutePath );
    	}
    	var driveLetter = listFirst( arguments.absolutePath, ':' );
    	var path = listRest( arguments.absolutePath, ':' );
    	var mapping = locateMapping( driveLetter );
    	return mapping & path;
    }
	    
    /** 
    * Accepts an absolute path and returns a relative path
    * Does NOT apply any canonicalization 
    */
    private string function makePathRelativeLinux( required string absolutePath ) {
    	var rootFolder = listFirst( arguments.absolutePath, '/\' );
    	var path = listRest( arguments.absolutePath, '/\' );
    	var mapping = locateMappingLinux( rootFolder );
    	return mapping & '/' & path;
    }
    
    /** 
    * Accepts a Windows drive letter and returns a CF Mapping
    * Creates the mapping if it doesn't exist
    */
    private string function locateMapping( required string driveLetter  ) {
    	var mappingName = '/' & arguments.driveLetter & '_drive';
    	var mappingPath = arguments.driveLetter & ':/';
    	var mappings = getApplicationSettings().mappings;
    	if( !structKeyExists( mappings, mappingName ) ) {
    		mappings[ mappingName ] = mappingPath;
    		application action='update' mappings='#mappings#';
   		}
   		return mappingName;
    }
    
    
    /** 
    * Accepts a Linux top-level folder and returns a CF Mapping
    * Creates the mapping if it doesn't exist
    */
    private string function locateMappingLinux( required string rootFolder  ) {
    	var mappingName = '/' & arguments.rootFolder & '_root';
    	var mappingPath = '/' & arguments.rootFolder;
    	var mappings = getApplicationSettings().mappings;
    	if( !structKeyExists( mappings, mappingName ) ) {
    		mappings[ mappingName ] = mappingPath;
    		application action='update' mappings='#mappings#';
   		}
   		return mappingName;
    }
    
    /** 
    * Detect if OS is Windows
    */
	private boolean function isWindows(){
		return createObject( "java", "java.lang.System" ).getProperty( "os.name" ).toLowerCase().contains( "win" );
	}
	
}