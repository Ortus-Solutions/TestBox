component displayName="TestBox xUnit suite for CF9" labels="lucee,cf" extends="testbox.system.BaseSpec"{

/*********************************** LIFE CYCLE Methods ***********************************/

	function beforeTests(){
		application.salvador = 1;
	}

	function afterTests(){
		structClear( application );
	}

	function setup(){
		request.foo = 1;
	}

	function teardown(){
		structDelete( request, "foo" );
	}

/*********************************** Test Methods ***********************************/

	any function testFloatingPointNumberAddition() output="false" {
		var sum = 196.4 + 196.4 + 180.8 + 196.4 + 196.4 + 180.8 + 609.6;
		// sum.toString() outputs: 1756.8000000000002
		//debug( sum );
		//$assert.isEqual( sum, 1756.8 );
	}

	function testIncludes(){
		$assert.includes( "hello", "HE" );
		$assert.includes( [ "Monday", "Tuesday" ] , "monday" );
	}

	function testIncludesWithCase(){
		$assert.includesWithCase( "hello", "he" );
		$assert.includesWithCase( [ "Monday", "Tuesday" ] , "Monday" );
	}

	function testnotIncludesWithCase(){
		$assert.notincludesWithCase( "hello", "aa" );
		$assert.notincludesWithCase( [ "Monday", "Tuesday" ] , "monday" );
	}

	function testNotIncludes(){
		$assert.notIncludes( "hello", "what" );
		$assert.notIncludes( [ "Monday", "Tuesday" ] , "Friday" );
	}

	function testIsEmpty(){
		$assert.isEmpty( [] );
		$assert.isEmpty( {} );
		$assert.isEmpty( "" );
		$assert.isEmpty( queryNew("") );
	}

	function testIsNotEmpty(){
		$assert.isNotEmpty( [1,2] );
		$assert.isNotEmpty( {name="luis"} );
		$assert.isNotEmpty( "HelloLuis" );
		$assert.isNotEmpty( querySim( "id, name
			1 | luis") );
	}

	function testSkipped() skip{
		$assert.fail( "This Test should fail" );
	}

	boolean function isLucee(){
		return structKeyExists( server, "lucee" );
	}

	function testThatShouldFail(){
		try{
			$assert.fail( "This Test should fail" );
		}
		catch(Any e){
			// should get here
		}
	}

	function testThatShouldFailWithShortcut(){
		try{
			fail( "This Test should fail" );
		}
		catch(Any e){
			// should get here
		}
	}

	function testAssert() {
		$assert.assert( application.salvador == 1 );
	}

	function testAssertShortcut() {
		assert( application.salvador == 1 );
	}

	function testisTrue() {
		$assert.isTrue( 1 );
	}

	function testisFalse() {
		$assert.isFalse( 0 );
	}

	// Used in testIsEqual()
	function f1(){}


	function testisEqual() {

		var query = queryNew("");
		queryAddColumn(query, "id", [1,2,3,4]);
		queryAddColumn(query, "data", ["tahi","rua","toru", "wha"]);
		struct = {query=query};
		$assert.isEqual(struct, duplicate(struct));

		$assert.isEqual(
			[1,12],		// strings
			[1*1, 1*12]	// doubles
		);

		$assert.isEqual(f1, f1);

		$assert.isEqual( new testbox.system.MockBox(), new testbox.system.MockBox() );

		var xmlString = '<root><item attr="value" /><item attr="again" /></root>';
		$assert.isEqual( XMLParse(xmlString), XMLParse(xmlString) );

		$assert.isEqual( 0, 0 );
		$assert.isEqual( "hello", "HEllO" );
		$assert.isEqual( [], [] );
		$assert.isEqual( [1,2,3, {name="hello", test="this"} ], [1,2,3, {test="this", name="hello"} ] );
	}

	function testIsEqualQuery() {

		var a = '';
		var b = '';
		var testQuery = queryNew("column_a,column_b");
		queryAddRow(testQuery);
		querySetCell(testQuery,'column_a','1');
		querySetCell(testQuery,'column_b','2');

		a = new Query(
				sql = "SELECT column_a ,column_b
						FROM testQuery",
				dbtype = "query",
				testQuery = testQuery
			).execute().getResult();

		b = new Query(
				sql = "SELECT column_b ,column_a
						FROM testQuery",
				dbtype = "query",
				testQuery = testQuery
			).execute().getResult();

		$assert.isEqual(a, b);
	}

	function testisNotEqual() {
		$assert.isNotEqual( this, new testbox.system.MockBox() );
		$assert.isNotEqual( "hello", "test" );
		$assert.isNotEqual( 1, 2 );
		$assert.isNotEqual( [], [1,3] );
	}

	function testisEqualWithCase() {
		$assert.isEqualWithCase( "hello", "hello" );
	}

	function testnullValue() {
		$assert.null( javaCast("null", "") );
	}

	function testNotNullValue() {
		$assert.notNull( 44 );
	}

	function testTypeOf() {
		$assert.typeOf( "array", [ 1,2 ] );
		$assert.typeOf( "boolean", false );
		$assert.typeOf( "component", this );
		$assert.typeOf( "date", now() );
		$assert.typeOf( "time", timeformat( now() ) );
		$assert.typeOf( "float", 1.1 );
		$assert.typeOf( "numeric", 1 );
		$assert.typeOf( "query", querySim( "id, name
			1 | luis") );
		$assert.typeOf( "string", "hello string" );
		$assert.typeOf( "struct", { name="luis", awesome=true } );
		$assert.typeOf( "uuid", createUUID() );
		$assert.typeOf( "url", "https://www.coldbox.org" );
	}

	function testNotTypeOf() {
		$assert.notTypeOf( "array", 1 );
		$assert.notTypeOf( "boolean", "hello" );
		$assert.notTypeOf( "component", {} );
		$assert.notTypeOf( "date", "monday" );
		$assert.notTypeOf( "time", "1");
		$assert.notTypeOf( "float", "Hello" );
		$assert.notTypeOf( "numeric", "eeww2" );
		$assert.notTypeOf( "query", [] );
		$assert.notTypeOf( "string", this );
		$assert.notTypeOf( "struct", [] );
		$assert.notTypeOf( "uuid", "123" );
		$assert.notTypeOf( "url", "coldbox" );
	}

	function testInstanceOf() {
		$assert.instanceOf( new testbox.system.MockBox(), "testbox.system.MockBox" );
	}

	function testNotInstanceOf() {
		$assert.notInstanceOf( this, "testbox.system.MockBox" );
	}

	function testMatch(){
		$assert.match( "This testing is my test", "(TEST)$" );
	}

	function testMatchWithCase(){
		$assert.matchWithCase( "This testing is my TEST", "(TEST)$" );
	}

	function testNotMatchWithCase(){
		$assert.notMatchWithCase( "This testing is my TEST", "(test)$" );
	}

	function testNotMatch(){
		$assert.notMatch( "This testing is my test", "(hello)$" );
	}

	function testKey(){
		$assert.key( {name="luis", awesome=true}, "awesome" );
	}

	function testNotKey(){
		$assert.notKey( {name="luis", awesome=true}, "test" );
	}

	function testDeepKey(){
		$assert.deepKey( {name="luis", awesome=true, parent = { age=70 } }, "age" );
	}

	function testNotDeepKey(){
		$assert.notDeepKey( {name="luis", awesome=true, parent = { age=70 } }, "luis" );
	}

	function testLengthOf(){
		$assert.lengthOf( "heelo", 5 );
		$assert.lengthOf( [1,2], 2 );
		$assert.lengthOf( {name="luis"}, 1 );
		$assert.lengthOf( querySim( "id, name
			1 | luis"), 1 );

	}

	function testNotLengthOf(){
		$assert.notLengthOf( "heelo", 3 );
		$assert.notLengthOf( [1,2], 5 );
		$assert.notLengthOf( {name="luis"}, 5 );
		$assert.notLengthOf( querySim( "id, name
			1 | luis"), 0 );
	}

	/**
	* @expectedException
	*/
	function testExpectedExceptionNoValue(){
		// This method should throw an invalid exception and pass
		throw( type="InvalidException", message="This test method should pass with an expected exception" );
	}

	/**
	* @expectedException InvalidException
	*/
	function testExpectedExceptionWithValue(){
		// This method should throw an invalid exception and pass
		throw( type="InvalidException", message="This test method should pass with an expected exception of type InvalidException" );
	}

	/**
	* @expectedException InvalidException:(pass with an)
	*/
	function testExpectedExceptionWithValueAndRegex(){
		// This method should throw an invalid exception and pass
		throw( type="InvalidException", message="This test method should pass with an expected exception of type InvalidException" );
	}

	function testExpectedExceptionFromMethod(){
		expectedException();
		// This method should throw an invalid exception and pass
		throw( type="InvalidException", message="This test method should pass with an expected exception" );
	}

	function testExpectedExceptionFromMethodWithType(){
		expectedException( "InvalidException" );
		// This method should throw an invalid exception and pass
		throw( type="InvalidException", message="This test method should pass with an expected exception" );
	}

	function testExpectedExceptionFromMethodWithTypeAndRegex(){
		expectedException( "InvalidException", "(pass with an)" );
		// This method should throw an invalid exception and pass
		throw( type="InvalidException", message="This test method should pass with an expected exception" );
	}

	function testIsGT(){
		$assert.isGT( "b", "a" );
		$assert.isGT( 5, 3 );
		$assert.isGT( "01/01/2013", "01/01/2012" );
	}

	function testIsGTE(){
		$assert.isGTE( "b", "b" );
		$assert.isGTE( 5, 5 );
		$assert.isGTE( "01/01/2013", "01/01/2013" );
	}

	function testIsLT(){
		$assert.isLT( "a", "d" );
		$assert.isLT( 5, 30 );
		$assert.isLT( "01/01/2013", "01/02/2013" );
		$assert.isLT( "01/01/2013 08:00:00", "01/01/2013 12:00:00" );
	}

	function testIsLTE(){
		$assert.isLTE( "b", "b" );
		$assert.isLTE( 5, 10 );
	}

/*********************************** NON-RUNNABLE Methods ***********************************/

	function nonStandardNamesWillNotRun() {
		fail( "Non-test methods should not run" );
	}

	private function privateMethodsDontRun() {
		fail( "Private method don't run" );
	}

}