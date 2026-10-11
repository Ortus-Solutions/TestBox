# Parallel TestBox runners

This is a proposed API, not a released TestBox feature. Install the framework and CLI changes together.

## Start with the CI path if you already have independent jobs

Each CI job can use the normal serial runner and its existing environment setup:

```sh
box testbox run runner=serial shard=1/4 shardRunId=build-42-attempt-1 outputFile=results/shard-1.json
```

The other jobs use `2/4`, `3/4` and `4/4`. The index is **one-based**. No environment provider is needed: the CI platform starts the jobs and your existing setup prepares the application. Use the same source revision, dependencies, runner options and shared run ID in every job. Include the attempt and commit in that ID, and keep different engine/configuration matrices separate.

Download every job's JSON artifact into one directory, then run:

```sh
box testbox merge directory=downloaded-results outputFile=results/combined.json
```

Upload results even when assertions fail and run the merge job even when a shard fails. Missing, duplicate, mixed-run or incomplete reports fail verification. Empty shards still produce a report, so adding more jobs than bundles cannot silently drop a job. Assertion failures remain failures in the combined result. The combined duration is the longest shard's test duration, **not workflow wall time**; summed shard time is recorded separately.

CI sharding currently uses the standard JSON runner, not the parallel endpoint. The CLI intentionally refuses `workers` together with `shard`; distribute jobs first, then measure before adding concurrency within each machine. There is no remote-job API or GitHub credential configuration in TestBox. CI cancellation, provisioning and artifact transport belong to the CI platform. Code coverage recordings are not combined.

Programmatic integrations use the same hooks:

```cfml
// Each independently provisioned job runs its own selection.
report = new testbox.system.TestBox( directory="tests.specs" )
    .runRaw( shard="1/4", shardRunId="build-42-attempt-1" )
    .getMemento( includeDebugBuffer=true )

// An aggregation job reads every JSON report and validates the complete selection.
combined = new testbox.system.parallel.ShardPlan().merge( reports )
```

`ShardPlan.select(bundles, "1/4", runId, filters, durations)` also exposes the assigned paths and a JSON-serializable plan for another scheduler. Optional duration weights must be identical for every job. The plan fingerprints the bundle assignment and filters; it does not inspect source-file contents or infer environment isolation. Bundle scheduling is deterministic and keeps specs within their bundle. There is no work stealing.

## Configure one endpoint

The native skeleton includes an optional `tests/runner.parallel.bxm`:

```boxlang
<bx:script>
new testbox.system.parallel.Runner(
    provider = new tests.resources.WorkerProvider(),
    directory = "tests.specs"
).serve();
</bx:script>
```

The runner file contains configuration only. Implement isolation in `tests/resources/WorkerProvider.bx`, or instantiate an existing provider there. The supplied template extends `testbox.system.parallel.WorkerProvider`. That base class refuses execution until `startWorker`, `pollWorker` and `stopWorker` are implemented. Discovery and the RUN IDE still work before implementation.

A provider creates one **independent environment per worker**, not one per spec: separate application scope/JVM, database or schema, temporary files, mail sink and other mutable resources as required by the application. TestBox cannot infer that boundary. Do not share mutable fixtures across workers. A provider constructor must not provision resources: it is also instantiated for discovery, assets and cancellation requests.

The HTTP runner defaults to loopback access. Its `directory` configuration defines allowed test roots; query parameters may narrow them or choose known bundles. `maxWorkers` defaults to 32. Requested concurrency is capped at the number of selected bundles, so running a single bundle/suite/spec creates one environment. Use `durations={ bundlePath: milliseconds }` optionally to improve allocation. The `recurse`, glob-style `bundlesPattern`, `labels`, `excludes`, `testSuites` and `testSpecs` filters retain their normal meanings.

The native RUN view is BoxLang-specific. `Coordinator`, `IWorkerProvider`, `WorkerProvider` and `ProgressFile` are CFML classes; a CFML endpoint can use the coordinator and the same SSE protocol without including the native `.bxm` view. Cross-engine compatibility must be verified before release.

## Reuse an existing environment manager

If your application already knows how to start, observe and stop its test environments, adapt those operations directly:

```boxlang
<bx:script>
environments = new tests.resources.TestEnvironments();
new testbox.system.parallel.Runner(
    directory = "tests.specs",
    provider = new testbox.system.parallel.WorkerProvider(
        start = ( worker ) => environments.start( worker ),
        poll = ( handle ) => environments.poll( handle ),
        stop = ( handle ) => environments.stop( handle )
    )
).serve();
</bx:script>
```

`TestEnvironments` here is **your application helper**, not a supplied TestBox class. These functions must satisfy the lifecycle table below; the adapter does not invent provisioning or cancellation. `start` starts the assigned bundle request and returns a handle promptly. `poll` returns events and, when finished, the JSON report. `stop` confirms owned-resource cleanup and is safe to call again. Do not create environments in the helper constructor.

For shared preparation or concurrent shutdown, extend `WorkerProvider` and override the relevant hooks. A remote provider can dispatch CI jobs or another worker service and return their reports through the same contract, but ordinary CI matrices should use the simpler shard path above.

## Provider lifecycle

Implement `IWorkerProvider` directly, or extend `WorkerProvider` for default shared-setup, cancellation and finish hooks.

| Method | Contract |
| --- | --- |
| `prepareRun(context)` | Optional shared **immutable** setup. `context.runId`, `workers`, `bundles`, `durations`, `filters`, `output`, `cancellationFile` and `onProgress(message)` are supplied. `output` is a dedicated, initially nonexistent evidence directory outside the checkout. |
| `startWorker(descriptor)` | Create one environment and start its TestBox request. Descriptor has `workerId`, `bundles` and `run` (the shared context). Return an opaque struct handle. Remember ownership before a creation step can throw; clean up partial startup. |
| `pollWorker(handle)` | Return promptly with `{events: [{type, data}], done: false}`. Once finished return `done: true` and `result: {complete: true, report: JSON_REPORTER_MEMENTO}`. `complete` means execution and cleanup evidence are available; failing assertions still constitute a complete report. Include optional `seconds`, `executionSeconds` and `cleanupSeconds` for timing breakdowns. |
| `isCancelled(context)` | Check `context.cancellationFile`. The base implementation does this. Long-running preparation/startup must check cancellation themselves; the coordinator cannot interrupt a blocking provider call. |
| `stopWorker(handle)` | Stop and clean up **only owned resources**, including already-completed handles. Idempotent cleanup/verification is required. Throw when cleanup cannot be confirmed. |
| `stopWorkers(handles, context)` | Optional replacement for sequential stops. Signal all workers first, then wait against a **single 30-second deadline**, force remaining owned processes, and verify cleanup. Report escalation through `context.onShutdownProgress(message)`. This deadline is the provider's responsibility; TestBox cannot force arbitrary environment implementations. |
| `finishRun(context)` | Release shared resources. Called after stopping handles, including when preparation or startup failed. |

The provider must not serialize credentials, application objects or raw exceptions into progress. `ProgressFile` adapts existing TestBox callbacks to bounded JSONL events. Set `TESTBOX_PARALLEL_PROGRESS` to a private worker file and `TESTBOX_PARALLEL_SELECTION` to its JSON filter file when using the supplied HTML runner hook. Other transports can forward native StreamingService events directly. Preserve bundle path, suite ID and spec ID so the IDE can update the correct tree nodes. Flush progress promptly; polling cannot make buffered worker output appear earlier.

Bundles remain the scheduling unit. Each worker executes one balanced batch; there is no work stealing. Specs inside a bundle retain normal TestBox semantics and fixture isolation. `run()` must register descriptors without requiring `beforeAll()` side effects so normal `dryRun` discovery is safe.

## CLI and RUN IDE

Register named runners in `box.json`:

```json
{"testbox":{"runner":[{"serial":"/tests/runner.bxm"},{"parallel":"/tests/runner.parallel.bxm"}]}}
```

```sh
box testbox run runner=parallel workers=4
box testbox run runner=parallel workers=4 interactive=false
```

The patched CLI checks `action=capabilities` before executing. Its `auto` display uses CommandBox's CI/TTY detection; `interactive=true|false` overrides the preference, subject to terminal support. CI logs append bundle progress, duration in milliseconds and pass/fail/error counts. Interactive output retains completed worker rows and appends the normal summary and native timing table. Ctrl-C immediately requests POST cancellation and keeps reading cleanup progress.

Open `tests/runner.parallel.bxm` directly to use the native RUN IDE, or set its Runner URL in the existing skeleton's Settings. Choose Workers, then run all tests or a bundle/suite/spec. The worker strip shows shared preparation, discovery/execution, cumulative counts, elapsed time and completion. Stop requests cancellation; it stays disabled while shutdown is pending and the stream stays open until cleanup finishes. Workers are disabled for runners that do not advertise support. Existing serial runners continue to work.

## Protocol and result

`action=capabilities` returns `{workers:true,maxWorkers:32,cancellation:true}`. `dryRun=true` returns normal discovery with a `parallel` capabilities property. `action=run&streaming=true&runId=32_LOWERCASE_HEX&workers=N` streams one run. Identities are scoped to the configured endpoint and claimed once; reconnection cannot start duplicate workers. POST `action=cancel&runId=...` marks only an active, known run. Do not close the stream when cancelling: final cleanup can take up to the provider's grace deadline.

The stream adds `testRunStart`, `runPhase`, `workerStart`, `bundleReady`, `workerEnd`, `workerError` and `runCancelling` around normal bundle/suite/spec events. The coordinator adds `runId`, `workerId` to worker events and increasing `sequence`. Exactly one `testRunEnd` follows cleanup, with the combined JSON memento in `results`. Result `parallel` contains coverage verification, cancellation, infrastructure errors, per-worker stats, wall time and shared preparation/cleanup timing. Cancellation is incomplete execution, not an assertion failure. Cleanup failures still report errors.

Private evidence is retained under the runner's temporary storage root for diagnosis; applications can set `storageRoot` explicitly. Delete old run directories only after reviewing the results and confirming all owned resources are gone. The framework does not infer retention or remove unrelated environments.

The proposed API does not combine coverage recordings or support arbitrary reporter side effects across processes. It does not make an application safe to parallelize automatically. Validate exact selected-bundle coverage, provider cleanup and representative assertion outcomes before adopting a worker count.

## Performance expectations

More workers are useful when there is spare capacity and enough bundles to keep them busy. Setup and cleanup are part of the elapsed time; the slowest bundle or worker sets a floor. Separate CI machines can provide additional capacity, but a shared database, filesystem or external service may still become the bottleneck.

In two focused CommuniArts comparisons of the same 46 request specs within each pair, two to four workers reduced total time from 4m49s to 4m35s (4.9%, with JFR enabled) and from 4m12s to 3m45s (10.6%, on a different pinned runtime). These are separate single comparisons, not repeated estimates or TestBox framework-suite benchmarks. Individual bundle times increased with concurrency. An earlier full-suite four-worker run passed in about 15m39s, but its older serial comparison used different source and coverage and cannot establish a controlled speedup. Eight workers later still took roughly 35 minutes.

Each isolated worker can need its own JVM, database, search process, temporary files and connections. Watch CPU, memory pressure, database limits and CI runner cost. Measure complete runs with identical inputs before changing a default. The timing breakdown is intended to make diminishing returns visible.

## Focused verification

Run `box task run taskFile=tests/parallel/Verify` for coordinator, provider, progress, endpoint and shard contracts, and `node tests/parallel/run-ide.test.mjs` for UI progress/clock/cancellation contracts. The normal serial result shape remains unchanged unless sharding is requested.

Lucee does not expose the abstract component modifier in its metadata. Shard planning therefore probes bundle construction on Lucee to exclude abstract declarations, using the same guard as serial execution. Keep bundle pseudo-constructors free of environment setup and mutable test data; put that work in test lifecycle hooks. This discovery cost happens in each CI job.
