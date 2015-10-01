/**
********************************************************************************
Copyright Since 2005 TestBox Framework by Luis Majano and Ortus Solutions, Corp
www.ortussolutions.com
********************************************************************************
Author 	  : Luis Majano
Description :
Wraps tests in Base ORM services transaction blocks so you can automatically rollback
*/
component extends="mxunit.framework.TestDecorator" {

	function invokeTestMethod(required methodName, args={}){
		var results = "";
		
		transaction action="begin"{
			// mark ColdBox ORM transaction
			request[ "cbox_aop_transaction" ] = true;
			// execute test
			results = getTarget().invokeTestMethod( arguments.methodName, arguments.args );
			// rollback
			transactionRollback();
		};
		
		if( !isNull( "results" ) ){ return results; }
	}

}