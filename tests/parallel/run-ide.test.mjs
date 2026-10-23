import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";
import path from "node:path";
const root = process.argv[2] || path.resolve(import.meta.dirname,"../..");
const context = {
    window: { location: { href: "http://localhost/tests/index.bxm" } },
    Date, URL, URLSearchParams, console, crypto: { randomUUID: () => "abcdefab-cdef-abcd-efab-cdefabcdefab" },
    setInterval: () => 1, clearInterval: () => {}, setTimeout: fn => fn(),
    document: { addEventListener: (event, fn) => { if (event === "alpine:init") fn(); } },
    Alpine: { directive: () => {}, data: (_name, factory) => { context.factory = factory; } },
    EventSource: class {
        listeners = {}; closed = false;
        constructor(url) { this.url = url; }
        addEventListener(type, fn) { (this.listeners[type] ||= []).push(fn); }
        emit(type, data) { for (const fn of this.listeners[type] || []) fn({data: JSON.stringify(data)}); }
        close() { this.closed = true; }
    },
    fetch: async () => ({ok: true, json: async () => ({cancelling:true})})
};
vm.createContext(context);
for (const file of ["worker-progress.js", "run.js"]) {
    vm.runInContext(fs.readFileSync(path.join(root, "bx/tests/assets/js", file), "utf8"), context);
}
const progress = context.window.createTestBoxWorkerProgress();
progress.reset();
progress.apply("testRunStart", {workerBundleCounts:[2,1]});
progress.apply("workerStart", {workerId:1});
progress.apply("bundleStart", {workerId:1, path:"One"});
assert.match(progress.status(progress.workers[0]), /Discovering specs in One/);
progress.apply("bundleReady", {workerId:1, totalSpecs:2});
progress.apply("specEnd", {workerId:1, id:"a", bundlePath:"One", status:"Passed"});
progress.apply("specEnd", {workerId:1, id:"a", bundlePath:"One", status:"Passed"});
assert.equal(progress.summary.passed, 1, "duplicate events must not inflate live totals");
progress.apply("specEnd", {workerId:2, id:"b", bundlePath:"Two", status:"Failed"});
progress.apply("bundleEnd", {workerId:1, path:"One", totalPass:2});
progress.apply("bundleEnd", {workerId:1, path:"One", totalPass:2});
assert.equal(progress.summary.bundles, 1);
assert.equal(progress.summary.passed, 2, "bundle result reconciles missing spec events");
assert.equal(progress.summary.failed, 1, "worker events remain independent");
progress.now = 3662000;
assert.equal(progress.elapsed(1000,0), "01:01:01");
assert.equal(progress.elapsed(1000,61000), "00:01:00");
progress.apply("workerEnd", {workerId:1, complete:true, hasReport:true, totalBundles:2,totalPass:3});
progress.apply("runCancelling", {});
progress.apply("testRunEnd", {results:{parallel:{cancelled:true}}});
assert.equal(progress.workers[0].state, "completed");
assert.equal(progress.workers[1].state, "cancelled");
assert.equal(progress.summary.passed, 3);
assert.equal(progress.plural(1,"error"), "1 error");
assert.equal(progress.plural(2,"spec"), "2 specs");

const ui = context.factory();
ui.preferences.runnerUrl = "runner.parallel.bxm";
ui.preferences.directory = "tests.specs";
ui.preferences.workers = 4;
ui.parallelCapabilities = {workers:true,maxWorkers:8};
ui.isLoading = false;
ui.runAllTests();
const stream = ui.eventSource;
assert.equal(new URL(stream.url).searchParams.get("workers"), "4");
assert.equal(new URL(stream.url).searchParams.get("action"), "run");
assert.match(new URL(stream.url).searchParams.get("runId"), /^[a-f0-9]{32}$/);
stream.emit("testRunStart", {workers:2,totalBundles:2,workerBundleCounts:[1,1]});
await ui.stopTests();
assert.equal(ui.isStopping, true);
assert.equal(ui.isRunning, true, "Stop waits for server-side cleanup");
assert.equal(stream.closed, false, "Stop must retain the cleanup stream");
stream.emit("testRunEnd", {results:{totalBundles:1,totalSuites:1,totalSpecs:1,totalDuration:1234,
    totalPass:1,totalFail:0,totalError:0,totalSkipped:0,parallel:{cancelled:true}}});
assert.equal(ui.globalStats.totalSpecs, 1);
assert.equal(ui.globalStats.totalDuration, 1234);
assert.equal(ui.isRunning, false);
assert.equal(stream.closed, true);
assert.equal(ui.workerProgress.workers[0].state, "cancelled");

ui.parallelCapabilities = null;
ui.preferences.workers = 2;
ui.runAllTests();
assert.equal(ui.isRunning, false);
assert.match(ui.globalError, /does not support multiple workers/);
console.log("RUN IDE contracts passed: interleaving, reconciliation, live clocks, terminal states, cancellation and final results.");
