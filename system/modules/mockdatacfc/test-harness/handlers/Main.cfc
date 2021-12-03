component{

	function index( event, rc, prc ){
		return getInstance( "MockData@MockDataCFC" )
			.mock(
				testSupplier = function( index ){
					return "hello#arguments.index#";
				},

				key 		= "string:50",
				fullName    = "name",
				description = "sentence",
				age         = "age",
				id          = "uuid",
				createdDate = "datetime",
				isActive	= "oneof:true:false",
				number 		= "num:50:100",
				homepage 	= "website",
				longUrl  	= "url",
				pictureUrl  = "imageUrl",
				logIp 		= "ipaddress",

				// one to many complex object definitions
				books = [
					{
						$num = "rand:1:3",
						"id" = "uuid",
						"title" = "words:1:5",
						"categories" = {
							"$num"      = "2",
							"id"        = "uuid",
							"category"  = "words"
						}
					}
				],

				// object definition
				publisher = {
					"id" 	= "uuid",
					"name" 	= "sentence"
				},

				// array of values
				keywords = [
					{
						"$num" 	= "rand:1:10",
						"$type" = "words"
					}
				]
			);
	}

}