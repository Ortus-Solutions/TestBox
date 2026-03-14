document.addEventListener( "alpine:init", () => {
	Alpine.data( "testboxRun", () => ( {
		// State
		isLoading: true,
		isRunning: false,
		globalError: null,
		globalErrorDetail: null,

		// Preferences (Merged with URL options)
		preferences: {
			theme: "dark",
			runnerUrl: "",
			directory: "",
			recurse: true,
			bundlesPattern: "",
			labels: "",
			excludes: ""
		},

		// Data
		bundles: [],
		globalStats: {
			totalBundles: 0,
			totalSuites: 0,
			totalSpecs: 0,
			totalDuration: 0,
			totalPass: 0,
			totalFail: 0,
			totalError: 0,
			totalSkipped: 0
		},

		// UI Filters
		searchQuery: "",
		statusFilters: {
			passed: true,
			failed: true,
			error: true,
			skipped: true
		},

		// The active EventSource connection for streaming test results
		eventSource: null,
		// Indicates testRunEnd was received for the current stream
		runCompleted: false,
		// Indicates we are intentionally stopping/closing the current stream
		isStopping: false,
		// Set to the bundle path when running a single bundle; null when running all
		activeBundlePath: null,
		// Counts specEnd events received during the current run for progress tracking
		specsCompleted: 0,
		// Internal flag to ensure init runs only once
		_initialized: false,

		/**
		 * Initializes the Alpine Component. Runs exactly once to load preferences and kick off the dry run.
		 */
		init() {
			if ( this._initialized ) return;
			this._initialized = true;

			this.loadPreferences();
			this.fetchDryRun();
		},

		/**
		 * Loads configuration from LocalStorage and merges it with the URL initial options.
		 */
		loadPreferences() {
			// Start with defaults, override with localStorage, then override with URL params on first load
			let savedPref = localStorage.getItem( "testboxPreferences" );

			if ( savedPref ) {
				try {
					Object.assign( this.preferences, JSON.parse( savedPref ) );
				} catch ( e ) {
					console.error( "Failed to parse saved preferences", e );
				}
			}

			// Apply window.initialOptions injected from run.bxm URL params
			if ( window.initialOptions ) {
				// Only apply if they were explicitly provided
				for ( let key in window.initialOptions ) {
					if ( window.initialOptions[ key ] !== null && window.initialOptions[ key ] !== undefined && window.initialOptions[ key ] !== "" ) {
						// typecast recurse correctly
						if ( key === "recurse" ) {
							this.preferences[ key ] = ( window.initialOptions[ key ] === true || window.initialOptions[ key ] === "true" );
						} else {
							this.preferences[ key ] = window.initialOptions[ key ];
						}
					}
				}
			}
		},

		/**
		 * Persists the current configuration to LocalStorage and reloads the window to apply them.
		 */
		savePreferences() {
			localStorage.setItem( "testboxPreferences", JSON.stringify( this.preferences ) );
			// Reload page to apply new settings via URL or we could just fetchDryRun again, but reload is cleaner to reset state
			window.location.reload();
		},

		/**
		 * Clears all saved preferences from LocalStorage and reloads the window to restore defaults.
		 */
		resetPreferences() {
			localStorage.removeItem( "testboxPreferences" );
			window.location.reload();
		},

		/**
		 * Toggles the UI theme between dark and light modes, persisting the choice.
		 */
		toggleTheme() {
			this.preferences.theme = this.preferences.theme === "dark" ? "light" : "dark";
			localStorage.setItem( "testboxPreferences", JSON.stringify( this.preferences ) );
		},

		/**
		 * Builds the runner URL with query parameters based on preferences and any additional params provided.
		 * This allows us to easily switch between dry run and actual run with streaming, as well as apply filters.
		 *
		 * @param {object} params - Dictionary of additional URL overrides to inject
		 * @returns {string} The fully constructed URL.
		 */
		buildRunnerUrl( params = {} ) {
			// Start with the base runner URL and append query parameters
			let url = new URL( this.preferences.runnerUrl, window.location.href );

			// Core parameters from preferences
			url.searchParams.append( "directory", this.preferences.directory );
			url.searchParams.append( "recurse", this.preferences.recurse );
			url.searchParams.append( "bundlesPattern", this.preferences.bundlesPattern );

			if ( this.preferences.labels ) {
				url.searchParams.append( "labels", this.preferences.labels );
			}

			if ( this.preferences.excludes ) {
				url.searchParams.append( "excludes", this.preferences.excludes );
			}

			for ( let key in params ) {
				url.searchParams.append( key, params[ key ] );
			}

			return url.toString();
		},

		/**
		 * Performs a dry run to fetch the test structure and initialize the UI state before actual execution.
		 * This allows us to display all bundles/suites/specs in a pending state and then update them in real-time as the tests run.
		 */
		async fetchDryRun() {
			this.isLoading = true;
			this.globalError = null;

			let url = this.buildRunnerUrl( { dryRun : true } );

			try {
				let response = await fetch( url );
				if ( !response.ok ) {
					throw new Error( `HTTP Error: ${ response.status } ${ response.statusText }` );
				}

				let text = await response.text();
				let data;
				try {
					data = JSON.parse( text );
				} catch ( e ) {
					throw new Error( "Invalid JSON returned from runner." );
				}

				this.initializeState( data );
			} catch ( e ) {
				this.globalError = "Failed to load test structure.";
				this.globalErrorDetail = e.message;
			} finally {
				this.isLoading = false;
			}
		},

		/**
		 * Parses the dry run JSON payload and maps it into the reactive bundles state array.
		 *
		 * @param {object} data - The dry run JSON payload from the server.
		 */
		initializeState( data ) {
			// Reset stats
			this.globalStats = {
				totalBundles: 0,
				totalSuites: 0,
				totalSpecs: 0,
				totalDuration: 0,
				totalPass: 0,
				totalFail: 0,
				totalError: 0,
				totalSkipped: 0
			};

			this.bundles = [];

			if ( !data.bundles ) return;

			data.bundles.forEach( b => {
				let bundle = {
					id: b.id || b.path || b.name,
					name: b.name,
					path: b.path,
					status: "pending",
					expanded: false,
					type: "bundle",
					totalDuration: 0,
					totalPass: 0,
					totalFail: 0,
					totalError: 0,
					totalSkipped: 0,				debugBuffer: [],
				showDebug: false,					suites: [],
					specs: [] // top-level specs
				};

				if ( b.suites && b.suites.length ) {
					b.suites.forEach( s => {
						let suite = {
							id: s.id,
							name: s.name,
							status: "pending",
							expanded: false,
							specs: []
						};

						if ( s.specs && s.specs.length ) {
							s.specs.forEach( sp => {
								suite.specs.push( this.createSpecNode( sp ) );
							} );
						}
						bundle.suites.push( suite );
					} );
				} else if ( b.specs && b.specs.length ) {
					// xUnit or no suites
					b.specs.forEach( sp => {
						bundle.specs.push( this.createSpecNode( sp ) );
					} );
				}

				this.bundles.push( bundle );
			} );
		},

		/**
		 * Helper to factory generate a spec node containing unified baseline reactive properties.
		 *
		 * @param {object} sp - The target spec metadata payload.
		 * @returns {object} The initialized reactive node specification.
		 */
		createSpecNode( sp ) {
			return {
				id: sp.id,
				name: sp.name,
				status: sp.skip ? "skipped" : "pending",
				totalDuration: 0,
				failMessage: "",
				failDetail: "",
				error: null
			};
		},

		/**
		 * Dynamically calculates global counting statistics across all bundles, suites, and specs (Getter).
		 * - After a completed run: returns the accurate stats received from the testRunEnd SSE event.
		 * - During a run or before any run: computes structure from the bundle tree. For single-bundle
		 *   runs the structure is scoped to the active bundle, giving an accurate progress bar denominator.
		 */
		get metaGlobalStats() {
			// Post-run: return the accurate server-reported counts verbatim.
			if ( this.runCompleted ) {
				return { ...this.globalStats };
			}

			// During a run / initial load: derive structure from the bundle tree.
			// For single-bundle runs scope to only the active bundle so the progress
			// bar denominator matches what the server is actually executing.
			let targetBundles = ( this.isRunning && this.activeBundlePath )
				? this.bundles.filter( b => b.path === this.activeBundlePath )
				: this.bundles;

			let totalB  = ( this.isRunning && this.activeBundlePath ) ? 1 : this.bundles.length;
			let totalSu = 0;
			let totalSp = 0;

			targetBundles.forEach( b => {
				totalSu += b.suites.length;
				totalSp += b.specs.length;
				b.suites.forEach( s => {
					totalSp += s.specs.length;
				} );
			} );

			return {
				totalBundles: totalB,
				totalSuites:  totalSu,
				totalSpecs:   totalSp,
				totalDuration: this.globalStats.totalDuration,
				totalPass:     this.globalStats.totalPass,
				totalFail:     this.globalStats.totalFail,
				totalError:    this.globalStats.totalError,
				totalSkipped:  this.globalStats.totalSkipped
			};
		},

		/**
		 * Overall run status for styling the results summary card border.
		 */
		get globalRunStatus() {
			if ( this.isRunning ) return 'running';
			const s = this.metaGlobalStats;
			if ( s.totalFail > 0 )    return 'failed';
			if ( s.totalError > 0 )   return 'error';
			if ( s.totalPass > 0 )    return 'passed';
			if ( s.totalSkipped > 0 ) return 'skipped';
			return 'pending';
		},

		/**
		 * Returns the tree of bundles recursively filtered by search query and status selections (Getter).
		 */
		get filteredBundles() {
			return this.bundles.filter( b => {
				// if search matches bundle name, show it
				let searchMatch = b.path.toLowerCase().includes( this.searchQuery.toLowerCase() );
				let statusMatch = this.isStatusVisible( b.status );

				if ( !statusMatch ) return false;

				if ( searchMatch ) return true;

				// check children
				let hasVisibleSuite = b.suites.some( s => this.isSuiteVisible( s, true ) );
				let hasVisibleSpec = b.specs.some( sp => this.isSpecVisible( sp, true ) );

				return hasVisibleSuite || hasVisibleSpec;
			} );
		},

		/**
		 * Evaluates a suite's visibility based on active user filters and direct matches.
		 *
		 * @param {object} suite - Target suite configuration.
		 * @param {boolean} ignoreParentMatch - Ignores parent scoping matches.
		 * @returns {boolean} Whether the item should be visible in HTML tree.
		 */
		isSuiteVisible( suite, ignoreParentMatch = false ) {
			let statusMatch = this.isStatusVisible( suite.status );
			if ( !statusMatch ) return false;

			if ( !ignoreParentMatch && this.searchQuery && suite.name.toLowerCase().includes( this.searchQuery.toLowerCase() ) ) return true;

			return suite.specs.some( sp => this.isSpecVisible( sp, true ) ) || ( suite.name.toLowerCase().includes( this.searchQuery.toLowerCase() ) );
		},

		/**
		 * Evaluates a spec's visibility based on name search and explicit status filters.
		 *
		 * @param {object} spec - Target spec configuration.
		 * @param {boolean} ignoreStatus - Force ignoring status filters.
		 * @returns {boolean} Whether the item should be visible in HTML tree.
		 */
		isSpecVisible( spec, ignoreStatus = false ) {
			if ( !ignoreStatus && !this.isStatusVisible( spec.status ) ) return false;
			return spec.name.toLowerCase().includes( this.searchQuery.toLowerCase() );
		},

		/**
		 * Checks if a specific status type is active in the global toggles.
		 * Pending and Running states bypass strict filter.
		 *
		 * @param {string} status - Test execution status condition.
		 * @returns {boolean} Resultant status eligibility.
		 */
		isStatusVisible( status ) {
			// 'pending' and 'running' are always visible unless we are strictly filtering
			if ( status === "pending" || status === "running" ) return true;
			if ( status === "passed" && !this.statusFilters.passed ) return false;
			if ( status === "failed" && !this.statusFilters.failed ) return false;
			if ( status === "error" && !this.statusFilters.error ) return false;
			if ( status === "skipped" && !this.statusFilters.skipped ) return false;
			return true;
		},

		/**
		 * Retrieves the bootstrap icon visual representation for a given status or node type.
		 *
		 * @param {string} status - Node execution status.
		 * @param {string} type - Node classification (bundle, suite, spec).
		 * @returns {string} Fully qualified bootstrap icon string CSS.
		 */
		getStatusIcon( status, type = "" ) {
			switch ( status ) {
				case "passed": return "bi-check-circle-fill text-success";
				case "failed": return "bi-x-circle-fill text-danger";
				case "error": return "bi-exclamation-octagon-fill text-warning";
				case "skipped": return "bi-dash-circle-fill text-info";
				case "running": return "bi-hourglass-split text-primary spinner-icon";
				default:
					if ( type === "bundle" ) return "bi-box";
					if ( type === "suite" ) return "bi-folder2-open";
					// spec
					return "bi-circle text-secondary";
			}
		},

		/**
		 * Transforms a test execution status into a specific Bootstrap contextual color class.
		 *
		 * @param {string} status - Target execution status label.
		 * @returns {string} Resolving BS semantic intent class (e.g., success/danger).
		 */
		getStatusColorClass( status ) {
			switch ( status ) {
				case "passed": return "success";
				case "failed": return "danger";
				case "error": return "warning";
				case "skipped": return "info";
				case "running": return "primary";
				default: return "secondary";
			}
		},

		/**
		 * Resets duration, statistics, and state indicators back to "pending".
		 * When bundlePath is provided, only that bundle (and its children) is reset;
		 * all other bundles are left untouched so their previous results remain visible.
		 *
		 * @param {string|null} bundlePath - If set, only reset this bundle; otherwise reset all.
		 */
		resetExecutionState( bundlePath = null ) {
			this.runCompleted = false;
			this.isStopping = false;

			const resetSpec = ( sp ) => {
				sp.status = "pending";
				sp.totalDuration = 0;
				sp.failMessage = "";
				sp.failDetail = "";
				sp.error = null;
			};

			const resetBundle = ( b ) => {
				b.status = "pending";
				b.totalDuration = 0;
				b.totalPass = 0;
				b.totalFail = 0;
				b.totalError = 0;
				b.totalSkipped = 0;
				b.suites.forEach( s => {
					s.status = "pending";
					s.specs.forEach( resetSpec );
				} );
				b.specs.forEach( resetSpec );
			};

			if ( bundlePath ) {
				const b = this.bundles.find( b => b.path === bundlePath );
				if ( b ) resetBundle( b );
			} else {
				this.bundles.forEach( resetBundle );
			}

			// Always wipe run stats so metaGlobalStats reflects the new run, not the previous one.
			this.globalStats = {
				totalBundles: 0, totalSuites: 0, totalSpecs: 0, totalDuration: 0,
				totalPass: 0, totalFail: 0, totalError: 0, totalSkipped: 0
			};
			this.specsCompleted = 0;
			this.globalError = null;
			this.globalErrorDetail = null;
		},

		/**
		 * Initiates a full systematic test run handling all loaded framework bundles.
		 */
		runAllTests() {
			this.activeBundlePath = null;
			this.resetExecutionState();
			this.isRunning = true;
			this.startEventSource( this.buildRunnerUrl( { streaming : true } ) );
		},

		/**
		 * Initiates a targeted isolated test run for a single bundle.
		 * Only that bundle resets to pending; all other bundles keep their last result (dimmed).
		 *
		 * @param {string} bundlePath - Bundle path to run.
		 */
		runBundle( bundlePath ) {
			this.activeBundlePath = bundlePath;
			this.resetExecutionState( bundlePath );
			this.isRunning = true;

			// Expand the target bundle and all its suites so results are immediately visible
			const b = this.bundles.find( b => b.path === bundlePath );
			if ( b ) {
				b.expanded = true;
				b.suites.forEach( s => s.expanded = true );
			}

			// Single-bundle run: only pass streaming + bundles — no directory/recurse/pattern
			let url = new URL( this.preferences.runnerUrl, window.location.href );
			url.searchParams.append( "streaming", "true" );
			url.searchParams.append( "bundles", bundlePath );
			this.startEventSource( url.toString() );
		},

		/**
		 * Safely initiates connection with the underlying BoxLang runner's Server-Sent Events stream
		 * and subsequently wires listeners mapping real-time broadcast payloads logically to the interface states.
		 *
		 * @param {string} url - The targeted SSE endpoint string.
		 */
		startEventSource( url ) {
			this.eventSource = new EventSource( url );

			this.eventSource.addEventListener( "bundleStart", ( e ) => {
				let data = JSON.parse( e.data );
				let bundle = this.bundles.find( b => b.path === data.path || b.id === data.id );
				if ( bundle ) bundle.status = "running";
			} );

			this.eventSource.addEventListener( "bundleEnd", ( e ) => {
				let data = JSON.parse( e.data );
				let bundle = this.bundles.find( b => b.path === data.path || b.id === data.id );
				if ( bundle ) {
					bundle.status = this.determineBundleStatus( data );
					bundle.totalDuration = data.totalDuration || 0;
					bundle.totalPass = data.totalPass || 0;
					bundle.totalFail = data.totalFail || 0;
					bundle.totalError = data.totalError || 0;
					bundle.totalSkipped = data.totalSkipped || 0;
					bundle.debugBuffer = data.debugBuffer || [];
				}
			} );

			this.eventSource.addEventListener( "suiteStart", ( e ) => {
				let data = JSON.parse( e.data );
				let suiteAndBundle = this.findSuite( data.id );
				if ( suiteAndBundle ) suiteAndBundle.suite.status = "running";
			} );

			this.eventSource.addEventListener( "suiteEnd", ( e ) => {
				let data = JSON.parse( e.data );
				let suiteAndBundle = this.findSuite( data.id );
				if ( suiteAndBundle ) suiteAndBundle.suite.status = this.determineBundleStatus( data );
			} );

			this.eventSource.addEventListener( "specStart", ( e ) => {
				let data = JSON.parse( e.data );
				let specInfo = this.findSpec( data.id );
				if ( specInfo ) specInfo.spec.status = "running";
			} );

			this.eventSource.addEventListener( "specEnd", ( e ) => {
				let data = JSON.parse( e.data );
				let specInfo = this.findSpec( data.id );
				if ( specInfo ) {
					specInfo.spec.status = data.status.toLowerCase();
					specInfo.spec.totalDuration = data.totalDuration || 0;
					specInfo.spec.failMessage = data.failMessage || "";
					specInfo.spec.failDetail = data.failDetail || "";
					specInfo.spec.error = data.error || null;
				}
				this.specsCompleted++;
			} );

			// Server-sent fatal error (event: error with JSON payload)
			this.eventSource.addEventListener( "error", ( e ) => {
				if ( !e.data ) return; // native connection close fires with no data — let onerror handle it
				let data = JSON.parse( e.data );
				this.globalError = data.message || "A fatal error occurred during testing.";
				this.globalErrorDetail = data.detail || "";
				this.isStopping = true;
				this.stopTests();
			} );

			this.eventSource.addEventListener( "testRunEnd", ( e ) => {
				let data = JSON.parse( e.data );
				// Capture all run-level counters so metaGlobalStats can reflect exactly
				// what was executed (full harness *or* a single-bundle run).
				this.globalStats.totalBundles  = data.totalBundles;
				this.globalStats.totalSuites   = data.totalSuites;
				this.globalStats.totalSpecs    = data.totalSpecs;
				this.globalStats.totalDuration = data.totalDuration;
				this.globalStats.totalPass     = data.totalPass;
				this.globalStats.totalFail     = data.totalFail;
				this.globalStats.totalError    = data.totalError;
				this.globalStats.totalSkipped  = data.totalSkipped;
				this.runCompleted = true;
				this.isStopping = true;
				this.stopTests();
			} );

			this.eventSource.onerror = () => {
				// onerror races with testRunEnd on normal server close — defer one tick
				// so testRunEnd has a chance to set runCompleted/isStopping first.
				setTimeout( () => {
					if ( this.isStopping || this.runCompleted || !this.isRunning ) return;
					this.globalError = "Connection to test runner lost.";
					this.isStopping = true;
					this.stopTests();
				}, 0 );
			};
		},

		/**
		 * Manually closes the active SSE communication stream dropping the runner state,
		 * gracefully transitioning dangling/timeout instances to an explicit stopped status.
		 */
		stopTests() {
			if ( this.eventSource ) {
				// Detach handlers before closing to avoid close-related onerror noise.
				this.eventSource.onerror = null;
				this.eventSource.onmessage = null;
				this.eventSource.onopen = null;
				this.eventSource.close();
				this.eventSource = null;
			}
			this.isRunning = false;
			this.activeBundlePath = null;

			// Mark any stuck 'running' states as 'error' or 'skipped' (optional)
			this.bundles.forEach( b => {
				if ( b.status === "running" ) b.status = "error";
				b.suites.forEach( s => {
					if ( s.status === "running" ) s.status = "error";
					s.specs.forEach( sp => {
						if ( sp.status === "running" ) sp.status = "skipped";
					} );
				} );
				b.specs.forEach( sp => {
					if ( sp.status === "running" ) sp.status = "skipped";
				} );
			} );
		},

		/**
		 * Performs an iterative traversal nested search to isolate a matching suite configuration by ID.
		 *
		 * @param {string} id - Active reference ID representing requested target.
		 * @returns {object|null} Resolving pair returning parent and matched item explicitly.
		 */
		findSuite( id ) {
			for ( let b of this.bundles ) {
				for ( let s of b.suites ) {
					if ( s.id === id ) return { bundle: b, suite: s };
				}
			}
			return null;
		},

		/**
		 * Performs an iterative traversal nested search to isolate a corresponding spec node configuration by ID.
		 * Supports deep-diving internal suite-bound lists or standalone xUnit top-tier bounds respectively.
		 *
		 * @param {string} id - Extrapolated reference ID of lookup element.
		 * @returns {object|null} Extended trace collection grouping targeting tree elements implicitly.
		 */
		findSpec( id ) {
			for ( let b of this.bundles ) {
				for ( let s of b.suites ) {
					for ( let sp of s.specs ) {
						if ( sp.id === id ) return { bundle: b, suite: s, spec: sp };
					}
				}
				// Top-level specs (xUnit style — no parent suite)
				for ( let sp of b.specs ) {
					if ( sp.id === id ) return { bundle: b, suite: null, spec: sp };
				}
			}
			return null;
		},

		/**
		 * Resets the entire UI to initial discovery state, wiping all run results and
		 * re-fetching the test bundle structure via a fresh dry run. Stops any active run first.
		 */
		refreshTests() {
			if ( this.isRunning ) {
				this.stopTests();
			}
			this.bundles           = [];
			this.runCompleted      = false;
			this.activeBundlePath  = null;
			this.specsCompleted    = 0;
			this.globalError       = null;
			this.globalErrorDetail = null;
			this.globalStats = {
				totalBundles: 0, totalSuites: 0, totalSpecs: 0, totalDuration: 0,
				totalPass: 0, totalFail: 0, totalError: 0, totalSkipped: 0
			};
			this.fetchDryRun();
		},

		/**
		 * Expands all bundle cards in the test tree.
		 */
		expandAll() {
			this.bundles.forEach( b => {
				b.expanded = true;
				b.suites.forEach( s => s.expanded = true );
			} );
		},

		/**
		 * Collapses all bundle cards in the test tree.
		 */
		collapseAll() {
			this.bundles.forEach( b => {
				b.expanded = false;
				b.suites.forEach( s => s.expanded = false );
			} );
		},

		/**
		 * Computes the overarching roll-up derivation status of dynamic container
		 * representations mapping test results progressively.
		 *
		 * @param {object} data - Reference map holding error, fail, or sequence metric states.
		 * @returns {string} Derived string representing logical test aggregate status.
		 */
		determineBundleStatus( data ) {
			if ( data.totalError > 0 ) return "error";
			if ( data.totalFail > 0 ) return "failed";
			if ( data.totalPass > 0 ) return "passed";
			if ( data.totalSkipped > 0 ) return "skipped";
			return "pending"; // default
		}
	} ) );

	// x-tooltip: wraps Bootstrap 5 Tooltip per element.
	// Usage: x-tooltip (reads data-bs-title or title attr) | x-tooltip.bottom (placement modifier)
	Alpine.directive( "tooltip", ( el, { modifiers }, { cleanup } ) => {
		let instance = new bootstrap.Tooltip( el, {
			title:     () => el.getAttribute( "data-bs-title" ) || el.getAttribute( "title" ) || "",
			trigger:   "hover focus",
			placement: modifiers[ 0 ] || "top"
		} );
		// Hide immediately on click so tooltips don't linger after buttons are pressed
		const hideOnClick = () => instance.hide();
		el.addEventListener( "click", hideOnClick );
		cleanup( () => {
			el.removeEventListener( "click", hideOnClick );
			instance.dispose();
		} );
	} );
} );
