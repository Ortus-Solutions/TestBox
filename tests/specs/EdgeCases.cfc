component extends="testbox.system.BaseSpec" {

	function run(){

		describe("Tests sparse array", function(){

			it("works", function(){
				var expected = ["a"];
				expected[3] = "c";
				var actual = expected;
				expect(expected).toBe(actual); // this is line 10
			});

		});

	}
}