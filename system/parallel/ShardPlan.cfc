/** Portable bundle selection and report validation for independent CI jobs. */
component {

	struct function create(
		required array bundles,
		required numeric count,
		required string runId,
		struct filters   = {},
		struct durations = {}
	){
		if ( count < 1 || count != int( count ) || !len( trim( runId ) ) || len( runId ) > 200 ) {
			throw(
				type    = "TestBox.Sharding.InvalidPlan",
				message = "Use a positive shard count and a shared run ID (up to 200 characters)."
			)
		}
		var sorted = duplicate( bundles )
		sorted.sort( "text" )
		var seen = {}
		for ( var bundle in sorted ) {
			if ( !isSimpleValue( bundle ) || !len( bundle ) || seen.keyExists( bundle ) ) {
				throw( type = "TestBox.Sharding.InvalidPlan", message = "Select unique, nonempty bundle paths." )
			}
			seen[ bundle ] = true
		}
		if ( !sorted.len() ) {
			throw( type = "TestBox.Sharding.InvalidPlan", message = "No bundles matched the selection." )
		}
		var groups      = partition( sorted, count, durations )
		var filterNames = filters.keyArray()
		filterNames.sort( "text" )
		var filterIdentity = filterNames.map( function( key ){
			return [ key, filters[ key ] ]
		} )
		return {
			"version" : 1,
			"runId"   : runId,
			"id"      : lCase( hash( serializeJSON( [ 1, runId, sorted, groups, filterIdentity ] ), "SHA-256" ) ),
			"count"   : count,
			"bundles" : sorted,
			"groups"  : groups,
			"filters" : duplicate( filters )
		}
	}

	struct function select(
		required array bundles,
		required string shard,
		required string runId,
		struct filters   = {},
		struct durations = {}
	){
		if ( !reFind( "^[1-9][0-9]*/[1-9][0-9]*$", shard ) ) {
			throw(
				type    = "TestBox.Sharding.InvalidPlan",
				message = "Shard must use index/count, for example 1/4."
			)
		}
		var index = val( listFirst( shard, "/" ) )
		var count = val( listLast( shard, "/" ) )
		if ( index > count ) {
			throw( type = "TestBox.Sharding.InvalidPlan", message = "Shard index cannot exceed its count." )
		}
		var plan = create( bundles, count, runId, filters, durations )
		return {
			"index"   : index,
			"plan"    : plan,
			"bundles" : duplicate( plan.groups[ index ] )
		}
	}

	private string function fingerprint( required struct plan ){
		var names = plan.filters.keyArray()
		names.sort( "text" )
		var filters = names.map( function( key ){
			return [ key, plan.filters[ key ] ]
		} )
		return serializeJSON( [
			plan.version,
			plan.runId,
			plan.id,
			plan.count,
			plan.bundles,
			plan.groups,
			filters
		] )
	}

	/** Shared scheduling for local workers and CI shards. Empty shards are valid. */
	array function partition(
		required array bundles,
		required numeric workers,
		struct durations = {}
	){
		var weighted = []
		for ( var bundle in bundles ) {
			var weight = durations[ bundle ] ?: 1000
			if ( !isNumeric( weight ) || weight <= 0 ) {
				throw(
					type    = "TestBox.Sharding.InvalidPlan",
					message = "Bundle durations must be positive numbers."
				)
			}
			weighted.append( { "path" : bundle, "weight" : weight } )
		}
		weighted.sort( function( a, b ){
			return a.weight == b.weight ? compare( a.path, b.path ) : ( a.weight > b.weight ? -1 : 1 )
		} )
		var groups = []
		var loads  = []
		for ( var i = 1; i <= workers; i++ ) {
			groups.append( [] )
			loads.append( 0 )
		}
		for ( var item in weighted ) {
			var target = 1
			for ( var i = 2; i <= workers; i++ ) {
				if ( loads[ i ] < loads[ target ] ) {
					target = i
				}
			}
			groups[ target ].append( item.path )
			loads[ target ] += item.weight
		}
		return groups
	}

	/** Missing/duplicate/mixed artifacts are infrastructure failures, never a passing subset. */
	struct function merge( required array reports ){
		if ( !reports.len() || !isStruct( reports[ 1 ].shard ?: "" ) ) {
			throw(
				type    = "TestBox.Sharding.InvalidResults",
				message = "Supply JSON results containing shard manifests."
			)
		}
		var plan      = reports[ 1 ].shard.plan
		var canonical = create(
			plan.bundles,
			plan.count,
			plan.runId,
			plan.filters
		)
		// Duration-balanced plans can differ from the default partition. Validate their assignment and identity below.
		var names = plan.filters.keyArray()
		names.sort( "text" )
		var identity = names.map( function( key ){
			return [ key, plan.filters[ key ] ]
		} )
		if (
			plan.version != 1 || plan.groups.len() != plan.count || compare(
				plan.id,
				lCase(
					hash(
						serializeJSON( [
							1,
							plan.runId,
							canonical.bundles,
							plan.groups,
							identity
						] ),
						"SHA-256"
					)
				)
			) != 0
		) {
			throw( type = "TestBox.Sharding.InvalidResults", message = "Invalid shard plan identity." )
		}
		var planned = []
		for ( var group in plan.groups ) {
			planned.append( group, true )
		}
		planned.sort( "text" )
		if (
			compare( serializeJSON( planned ), serializeJSON( canonical.bundles ) ) != 0 || reports.len() != plan.count
		) {
			throw(
				type    = "TestBox.Sharding.InvalidResults",
				message = "Missing shard reports or invalid bundle assignment."
			)
		}
		var combined = {
			"totalBundles"      : 0,
			"totalSuites"       : 0,
			"totalSpecs"        : 0,
			"totalPass"         : 0,
			"totalFail"         : 0,
			"totalError"        : 0,
			"totalSkipped"      : 0,
			"totalDuration"     : 0,
			"bundleStats"       : [],
			"coverage"          : { "enabled" : false },
			"labels"            : [],
			"excludes"          : [],
			"version"           : reports[ 1 ].version ?: "",
			"CFMLEngine"        : reports[ 1 ].CFMLEngine ?: "",
			"CFMLEngineVersion" : reports[ 1 ].CFMLEngineVersion ?: ""
		}
		var received       = {}
		var summedDuration = 0
		var complete       = true
		for ( var report in reports ) {
			for ( var metadata in [ "version", "CFMLEngine", "CFMLEngineVersion" ] ) {
				if ( compareNoCase( report[ metadata ] ?: "", reports[ 1 ][ metadata ] ?: "" ) != 0 ) {
					throw(
						type    = "TestBox.Sharding.InvalidResults",
						message = "Keep different TestBox versions and runtime matrices in separate result sets."
					)
				}
			}
			var shard = report.shard ?: {}
			var index = shard.index ?: 0
			if (
				!isNumeric( index ) || index != int( index ) || index < 1 || index > plan.count || received.keyExists(
					index
				) || compare( fingerprint( shard.plan ?: {} ), fingerprint( plan ) ) != 0
			) {
				throw(
					type    = "TestBox.Sharding.InvalidResults",
					message = "Duplicate shard or results from a different run, selection or filter set."
				)
			}
			received[ index ] = true
			var reportBundles = report.bundleStats ?: []
			var actual        = reportBundles.map( function( bundle ){
				return bundle.path
			} )
			actual.sort( "text" )
			var expected = duplicate( plan.groups[ index ] )
			expected.sort( "text" )
			if (
				compare( serializeJSON( actual ), serializeJSON( expected ) ) != 0 || ( report.totalBundles ?: 0 ) != actual.len()
			) {
				throw(
					type    = "TestBox.Sharding.InvalidResults",
					message = "Shard " & index & " did not execute exactly its assigned bundles."
				)
			}
			if ( report.coverage.enabled ?: false ) {
				throw(
					type    = "TestBox.Sharding.InvalidResults",
					message = "Coverage recording aggregation is not supported."
				)
			}
			complete = complete && ( shard.complete ?: false ) && !( report.parallel.cancelled ?: false ) && !arrayLen(
				report.parallel.errors ?: []
			)
			for (
				var key in [
					"totalBundles",
					"totalSuites",
					"totalSpecs",
					"totalPass",
					"totalFail",
					"totalError",
					"totalSkipped"
				]
			) {
				combined[ key ] += report[ key ] ?: 0
			}
			combined.bundleStats.append( report.bundleStats ?: [], true )
			combined.totalDuration = max( combined.totalDuration, report.totalDuration ?: 0 )
			summedDuration += report.totalDuration ?: 0
		}
		combined.sharding = {
			"planId"                   : plan.id,
			"runId"                    : plan.runId,
			"shards"                   : plan.count,
			"complete"                 : complete,
			"coverageMatched"          : true,
			"longestShardMilliseconds" : combined.totalDuration,
			"summedShardMilliseconds"  : summedDuration
		}
		combined.passed = complete && combined.totalFail == 0 && combined.totalError == 0
		return combined
	}

}
