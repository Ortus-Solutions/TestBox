component extends="testbox.system.BaseSpec" {

	function run(){
		describe( "Independent CI shards", function(){
			it( "selects identical disjoint groups regardless of discovery order", function(){
				var planner = new testbox.system.parallel.ShardPlan()
				var first   = planner.select(
					[ "tests.C", "tests.A", "tests.B" ],
					"1/2",
					"build-42"
				)
				var second = planner.select(
					[ "tests.B", "tests.C", "tests.A" ],
					"2/2",
					"build-42"
				)
				expect( first.plan.id ).toBe( second.plan.id )
				expect( first.bundles.toList() ).toBe( "tests.A,tests.C" )
				expect( second.bundles.toList() ).toBe( "tests.B" )
			} )
			it( "retains empty shards when there are more jobs than bundles", function(){
				var selection = new testbox.system.parallel.ShardPlan().select( [ "tests.A" ], "2/3", "build-42" )
				expect( selection.bundles ).toBeEmpty()
				expect( selection.plan.count ).toBe( 3 )
			} )
			it( "rejects malformed shard selections and duplicate bundles", function(){
				var planner = new testbox.system.parallel.ShardPlan()
				for ( var shard in [ "0/2", "3/2", "1/0", "1.5/2", "2", "-1/2" ] ) {
					expect( function(){
						planner.select( [ "tests.A" ], shard, "build-42" )
					} ).toThrow()
				}
				expect( function(){
					planner.create( [ "tests.A", "tests.a" ], 2, "build-42" )
				} ).toThrow()
				expect( function(){
					planner.create( [ "tests.A" ], 2, "" )
				} ).toThrow()
			} )
			it( "merges out-of-order reports and retains failed assertions", function(){
				var reports = reportsFor( "build-42" )
				reports[ 1 ].totalPass = 0
				reports[ 1 ].totalFail = 1
				var combined = new testbox.system.parallel.ShardPlan().merge( [ reports[ 2 ], reports[ 1 ] ] )
				expect( combined.totalBundles ).toBe( 2 )
				expect( combined.totalFail ).toBe( 1 )
				expect( combined.passed ).toBeFalse()
				expect( combined.sharding.coverageMatched ).toBeTrue()
				expect( combined.sharding.summedShardMilliseconds ).toBe( 300 )
				expect( combined.sharding.longestShardMilliseconds ).toBe( 200 )
			} )
			it( "rejects a missing report or a duplicate shard artifact", function(){
				var planner = new testbox.system.parallel.ShardPlan()
				var reports = reportsFor( "build-42" )
				expect( function(){
					planner.merge( [ reports[ 1 ] ] )
				} ).toThrow()
				expect( function(){
					planner.merge( [ reports[ 1 ], reports[ 1 ] ] )
				} ).toThrow()
			} )
			it( "rejects different runtime matrices", function(){
				var reports = reportsFor( "build-42" )
				reports[ 1 ].CFMLEngine = "BoxLang"
				reports[ 2 ].CFMLEngine = "Lucee"
				expect( function(){
					new testbox.system.parallel.ShardPlan().merge( reports )
				} ).toThrow()
			} )
			it( "rejects reports from another run or filter set", function(){
				var planner = new testbox.system.parallel.ShardPlan()
				var reports = reportsFor( "build-42" )
				var other   = reportsFor( "build-43" )
				expect( function(){
					planner.merge( [ reports[ 1 ], other[ 2 ] ] )
				} ).toThrow()
				other = reportsFor( "build-42", { "labels" : [ "integration" ] } )
				expect( function(){
					planner.merge( [ reports[ 1 ], other[ 2 ] ] )
				} ).toThrow()
			} )
			it( "rejects missing or unexpected executed bundles and corrupt manifests", function(){
				var planner = new testbox.system.parallel.ShardPlan()
				var reports = reportsFor( "build-42" )
				reports[ 2 ].bundleStats = []
				expect( function(){
					planner.merge( reports )
				} ).toThrow()
				reports = reportsFor( "build-42" )
				reports[ 2 ].bundleStats[ 1 ].path = "tests.Other"
				expect( function(){
					planner.merge( reports )
				} ).toThrow()
				reports = reportsFor( "build-42" )
				reports[ 1 ].shard.plan.groups[ 2 ] = [ "tests.Other" ]
				expect( function(){
					planner.merge( reports )
				} ).toThrow()
			} )
			it( "does not call interrupted execution a passing run", function(){
				var reports = reportsFor( "build-42" )
				reports[ 2 ].shard.complete = false
				expect( new testbox.system.parallel.ShardPlan().merge( reports ).passed ).toBeFalse()
			} )
			it( "refuses to imply that coverage recordings were merged", function(){
				var reports = reportsFor( "build-42" )
				reports[ 2 ].coverage = { "enabled" : true }
				expect( function(){
					new testbox.system.parallel.ShardPlan().merge( reports )
				} ).toThrow()
			} )
			it( "balances recorded durations consistently", function(){
				var planner = new testbox.system.parallel.ShardPlan()
				var plan    = planner.create(
					[ "tests.A", "tests.B", "tests.C" ],
					2,
					"build-42",
					{},
					{ "tests.A" : 100, "tests.B" : 40, "tests.C" : 30 }
				)
				expect( plan.groups[ 1 ].toList() ).toBe( "tests.A" )
				expect( plan.groups[ 2 ].toList() ).toBe( "tests.B,tests.C" )
			} )
			it( "merges empty job reports without silently dropping them", function(){
				var testbox = new testbox.system.TestBox( bundles = "tests.parallel.fixtures.OneSpec" )
				var reports = []
				for ( var i = 1; i <= 3; i++ ) {
					reports.append( testbox.runRaw( shard = i & "/3", shardRunId = "empty-42" ).getMemento() )
				}
				var result = new testbox.system.parallel.ShardPlan().merge( reports )
				expect( result.passed ).toBeTrue()
				expect( result.totalPass ).toBe( 1 )
				expect( result.sharding.shards ).toBe( 3 )
			} )
			it( "executes real bundles through runRaw and combines both CI job results", function(){
				var testbox = new testbox.system.TestBox(
					bundles = "tests.parallel.fixtures.OneSpec,tests.parallel.fixtures.TwoSpec,tests.parallel.fixtures.IExample,tests.parallel.fixtures.AbstractExample"
				)
				var one    = testbox.runRaw( shard = "1/2", shardRunId = "integration-42" ).getMemento()
				var two    = testbox.runRaw( shard = "2/2", shardRunId = "integration-42" ).getMemento()
				var result = new testbox.system.parallel.ShardPlan().merge( [ two, one ] )
				expect( result.passed ).toBeTrue()
				expect( result.totalPass ).toBe( 2 )
				expect( result.totalBundles ).toBe( 2 )
			} )
		} )
	}

	private array function reportsFor( required string runId, struct filters = {} ){
		var planner = new testbox.system.parallel.ShardPlan()
		var reports = []
		for ( var i = 1; i <= 2; i++ ) {
			var selection = planner.select(
				[ "tests.A", "tests.B" ],
				i & "/2",
				runId,
				filters
			)
			reports.append( {
				"shard"         : { "index" : i, "plan" : selection.plan, "complete" : true },
				"totalBundles"  : 1,
				"totalPass"     : 1,
				"totalFail"     : 0,
				"totalError"    : 0,
				"totalSpecs"    : 1,
				"totalDuration" : i * 100,
				"bundleStats"   : [ { "path" : selection.bundles[ 1 ] } ]
			} )
		}
		return reports
	}

}
