component{

	property name="streams" inject="StreamBuilder@cbstreams";

	function index( event, rc, prc ){
		var people = [
			{ id=1, name = "stream", color="blue" },
			{ id=2, name = "builder", color="red" },
			{ id=3, name = "joe", color="green" }
		];


		return streams.new( people )
			.filter( function( item ){
				return item.color eq "red";
			} )
			.map( function( item ){
				return item.name;
			} )
			.findFirst()
			.get();
	}

}