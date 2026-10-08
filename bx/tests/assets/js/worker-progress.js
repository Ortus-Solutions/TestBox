/* Shared SSE consumer for the RUN IDE. Worker ownership stays on the server. */
window.createTestBoxWorkerProgress = () => ( {
    workers: [], runnerErrors: [], phase: "", started: 0, now: 0, stopped: 0, cancelled: false,
    reset() {
        this.workers = [];
        this.runnerErrors = [];
        this.phase = "Connecting to runner";
        this.started = this.now = Date.now();
        this.stopped = 0;
        this.cancelled = false;
    },
    elapsed( started = this.started, stopped = this.stopped ) {
        if ( !started ) return "00:00:00";
        const seconds = Math.max( 0, Math.floor( ( ( stopped || this.now ) - started ) / 1000 ) );
        return [ Math.floor( seconds / 3600 ), Math.floor( seconds % 3600 / 60 ), seconds % 60 ]
            .map( n => String( n ).padStart( 2, "0" ) ).join( ":" );
    },
    plural( count, noun ) { return `${ count } ${ noun }${ count === 1 ? "" : "s" }`; },
    get summary() {
        return this.workers.reduce( ( totals, worker ) => ( {
            bundles: totals.bundles + worker.completed,
            total: totals.total + worker.total,
            passed: totals.passed + worker.passed,
            failed: totals.failed + worker.failed,
            errors: totals.errors + worker.errors,
            skipped: totals.skipped + worker.skipped
        } ), { bundles: 0, total: 0, passed: 0, failed: 0, errors: 0, skipped: 0 } );
    },
    status( worker ) {
        if ( worker.state !== "working" ) return worker.message;
        if ( !worker.bundle ) return worker.message;
        if ( worker.specTotal === null ) return `Discovering specs in ${ worker.bundle }`;
        return `Executing ${ worker.bundle } (${ worker.specs }/${ this.plural( worker.specTotal, "spec" ) } ran)`;
    },
    recount( worker ) {
        for ( const key of [ "passed", "failed", "errors", "skipped" ] ) {
            worker[ key ] = Object.values( worker.bundles ).reduce( ( n, b ) => n + b[ key ], 0 );
        }
    },
    apply( type, data ) {
        this.now = Date.now();
        if ( type === "testRunStart" ) {
            this.workers = ( data.workerBundleCounts || [] ).map( ( total, i ) => ( {
                id: i + 1, total, completed: 0, passed: 0, failed: 0, errors: 0, skipped: 0,
                bundle: "", specTotal: null, specs: 0, bundles: {},
                state: "working", message: "Waiting for shared setup", started: 0, stopped: 0
            } ) );
        }
        if ( type === "runPhase" ) this.phase = data.message;
        if ( type === "runCancelling" ) {
            this.cancelled = true;
            this.phase = data.message || "Cancellation received; stopping workers (up to 30 seconds)";
            this.workers.filter( w => !w.stopped ).forEach( w => {
                w.bundle = ""; w.message = "Stopping environment";
            } );
        }
        if ( type === "testRunEnd" ) {
            const report = data.results || data;
            this.cancelled = Boolean( report.parallel?.cancelled || data.cancelled );
            this.runnerErrors = report.parallel?.errors || [];
            this.stopped = this.now;
            this.phase = this.runnerErrors.length ? ( this.cancelled ? "Cancelled; cleanup could not be confirmed" : "Run failed; see runner errors" ) :
                this.cancelled ? "Cancelled; environment cleanup finished" : "Run completed; environment cleanup finished";
            this.workers.forEach( w => {
                if ( !w.stopped ) {
                    w.stopped = this.now;
                    w.state = this.cancelled ? "cancelled" : "error";
                    w.message = this.cancelled ? "Cancelled" : "Worker did not complete";
                }
            } );
        }
        const worker = this.workers.find( w => w.id === Number( data.workerId ) );
        if ( !worker ) return;
        if ( type === "workerStart" ) {
            worker.started = this.now;
            worker.message = "Preparing isolated environment";
            this.phase = "Executing selected bundles";
        }
        if ( type === "workerError" ) {
            worker.state = "error";
            worker.message = data.message || "Worker failed";
        }
        if ( type === "bundleStart" ) {
            worker.bundle = data.path;
            worker.specTotal = null;
            worker.specs = 0;
        }
        if ( [ "bundleReady", "suiteStart" ].includes( type ) ) {
            const count = data.totalSpecs ?? data.bundleTotalSpecs;
            if ( count !== undefined ) worker.specTotal = count;
        }
        const path = data.bundlePath || data.path || worker.bundle;
        if ( [ "specEnd", "bundleEnd" ].includes( type ) ) {
            const bundle = worker.bundles[ path ] ||= { passed: 0, failed: 0, errors: 0, skipped: 0, seen: {}, done: false };
            if ( type === "specEnd" && !bundle.seen[ data.id ] ) {
                bundle.seen[ data.id ] = true;
                const key = { passed: "passed", failed: "failed", error: "errors", skipped: "skipped" }[ data.status?.toLowerCase() ];
                if ( key ) bundle[ key ]++;
                worker.specs++;
            }
            if ( type === "bundleEnd" ) {
                if ( !bundle.done ) worker.completed++;
                Object.assign( bundle, { done: true, passed: data.totalPass || 0, failed: data.totalFail || 0,
                    errors: data.totalError || 0, skipped: data.totalSkipped || 0 } );
                worker.bundle = "";
                worker.message = worker.completed === worker.total ? "Finalizing environment cleanup" : "Starting next bundle";
            }
            this.recount( worker );
        }
        if ( type === "workerEnd" ) {
            worker.stopped = this.now;
            if ( data.hasReport ) {
                worker.passed = data.totalPass || 0; worker.failed = data.totalFail || 0;
                worker.errors = data.totalError || 0; worker.skipped = data.totalSkipped || 0;
                worker.completed = data.totalBundles || 0;
            }
            worker.state = !data.complete ? "error" : worker.errors ? "error" : worker.failed ? "failed" : "completed";
            worker.message = !data.complete ? "Worker failed" : "Completed";
        }
    }
} );
