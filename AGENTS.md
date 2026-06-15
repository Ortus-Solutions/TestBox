# Copilot Instructions for TestBox

## Project Overview

TestBox is the Ortus Solutions BDD/TDD testing framework for BoxLang and CFML applications. It supports three engines:

- **BoxLang**: Preferred engine and primary development target. New BoxLang language/runtime features should be designed and tested here first.
- **Adobe ColdFusion**: Supported CFML engine, currently targeted by the Adobe server configs in this repo.
- **Lucee**: Supported CFML engine, currently targeted by the Lucee server configs in this repo.

BoxLang is the preferred engine because Ortus builds it. However, TestBox is a cross-engine framework, so preserve CFML compatibility unless a feature is explicitly BoxLang-only. BoxLang-only features must be guarded and should skip or fail clearly on Adobe ColdFusion and Lucee instead of breaking unrelated CFML workflows.

TestBox provides:

- BDD-style testing with `describe()`, `it()`, lifecycle hooks, labels, focused/skipped specs, and fluent expectations.
- xUnit-style testing with `setup()`, `teardown()`, `test*()` methods, and the `$assert` object.
- MockBox mocking, stubbing, spying, and verification.
- Collection expectations through `expectAll()`, `expectAny()`, `expectSome()`, and `expectNone()`.
- Grouped assertions through `$assert.all()` and `assertAll()`.
- CLI, web, programmatic, and streaming runners.
- Multiple reporters and built-in coverage services.

## Always Use Relevant Skills

This repository ships domain skills in `.agents/skills`. Before implementing, reviewing, or debugging in one of these areas, read the relevant `SKILL.md` file and follow it. Prefer the most specific TestBox skill first, then BoxLang/CFML skills as needed.

### TestBox Skills

- **testbox-runners**: Running tests with CommandBox CLI, BoxLang CLI, HTML runner, programmatic `run()`/`runRaw()`/`runRemote()`, streaming runner options, watcher mode, filtering, dry runs, failure limits, stack traces, and `box.json` setup.
- **testbox-bdd**: BDD suites/specs, `describe()`/`it()`, feature/story/scenario/given/when/then aliases, lifecycle hooks, labels, focused/skipped specs, spec data binding, nested suites, and `asyncAll`.
- **testbox-unit-xunit**: xUnit-style test classes using `test*()` methods, `setup()`/`teardown()`, `beforeTests()`/`afterTests()`, `$assert`, and Arrange-Act-Assert structure.
- **testbox-expectations**: Fluent `expect()` and `expectAll()` matchers, negation, chaining, custom matchers, collection expectations, and expectation behavior.
- **testbox-assertions**: `$assert` methods, dynamic assertion aliases, custom assertion registration, equality, type, collection, exception, and numeric assertions.
- **testbox-mockbox**: MockBox mocks, stubs, spies, `$()` stubbing, `$args()`, `$results()`, `$throws()`, `$callLog()`, verification counts, property injection, `querySim()`, and spying.
- **testbox-cbmockdata**: Realistic mock data generation through cbMockData, including primitive values, nested objects, arrays, and custom suppliers.
- **testbox-reporters**: Reporter selection and authoring, including ANTJUnit, Console, Doc, JSON, JUnit, Min, MinText, Simple, Text, XML, Streaming, reporter options, and `IReporter` implementations.
- **testbox-listeners**: Test run listeners/callbacks such as `onBundleStart`, `onBundleEnd`, `onSuiteStart`, `onSuiteEnd`, `onSpecStart`, and `onSpecEnd`.

### Testing Support Skills

- **boxlang-testing**: Writing, running, and debugging BoxLang tests with TestBox, including BDD, xUnit, expectations, assertions, MockBox, fixtures, async tests, and the BoxLang CLI runner.
- **testing-coverage**: Code coverage configuration, reporting, CI integration, and coverage interpretation for ColdBox, ColdFusion, and BoxLang applications.
- **testing-fixtures**: Fixtures, factories, test data builders, shared fixture files, cbMockData usage, and setup/teardown practices.

### BoxLang And CFML Skills

- **boxlang-language-fundamentals**: BoxLang syntax, variables, scopes, operators, flow control, exceptions, types, destructuring, and spread syntax.
- **boxlang-best-practices**: BoxLang naming, structure, scoping, error handling, performance, and maintainability.
- **boxlang-cfml-migration**: Differences between BoxLang and CFML, compatibility concerns, `.cfc`/`.bx` conversion, scope behavior, query params, and date handling.
- **boxlang-classes-and-oop**: BoxLang classes, interfaces, inheritance, annotations, properties, constructors, and OOP patterns.
- **boxlang-functional-programming**: Closures, lambdas, arrow functions, higher-order functions, `map`/`filter`/`reduce`, destructuring, and spread syntax.
- **boxlang-application-descriptor**: `Application.bx`, application discovery, app lifecycle, sessions, mappings, `javaSettings`, schedulers, and watchers.
- **boxlang-templating**: `.bxm` templates, HTML mixed with BoxLang, `bx:output`, `bx:loop`, `bx:if`, `bx:include`, and view files.
- **boxlang-file-handling**: File and directory operations, uploads, streaming large files, CSV/JSON processing.
- **boxlang-database-access**: `queryExecute`, `bx:query`, datasources, query params, transactions, stored procedures, and SQL injection prevention.
- **boxlang-java-integration**: `createObject`, Java static methods, imports, type conversion, JARs, closures as functional interfaces, and JSR-223 integration.
- **boxlang-modules-and-packages**: BoxLang modules, `box install`, module settings, compatibility modules, ORM, mail, and premium modules.
- **boxlang-async-programming**: `BoxFuture`, `futureNew`, `asyncRun`, async collection helpers, executors, schedulers, thread components, file watchers, and locks.
- **boxlang-scheduled-tasks**: Scheduler DSL, scheduled task APIs, cron, frequency constraints, lifecycle callbacks, and HTTP scheduled tasks.
- **boxlang-file-watchers**: Watcher lifecycle BIFs, event payloads, recursive monitoring, debounce/throttle, atomic writes, error thresholds, and listeners.
- **boxlang-interceptors**: Interceptor/event system, announcements, custom events, hooks, validation interceptors, security guards, and `BoxRegisterInterceptor()`.

### General Engineering Skills

- **code-reviewer**: High-signal reviews focused on correctness, security, maintainability, performance, and test coverage risks.
- **code-documenter**: Developer-facing documentation, API references, onboarding guides, runbooks, and consistency audits.
- **github-action-authoring**: Composite GitHub Actions, runner platform support, PATH issues, inputs/outputs, PowerShell, installer flags, and CI jobs.
- **java-expert**, **junit-expert**, **mockito-expert**: Java, JUnit 5, and Mockito work when touching Java tooling, integrations, or supporting utilities.
- **alpinejs-expert** and **bootstrap-expert**: Frontend behavior and Bootstrap UI work for web runners, visualizers, or docs UI.

## Repository Structure

- `system/`: Core TestBox framework code.
- `system/TestBox.cfc`: Main orchestrator for bundle discovery, execution, result aggregation, reporter selection, modules, and coverage.
- `system/BaseSpec.cfc`: Base spec class and DSL surface for BDD and xUnit tests.
- `system/Assertion.cfc`: `$assert` implementation and shared assertion primitives such as equality, type checks, collections, path assertions, and set assertions.
- `system/Expectation.cfc`: Fluent BDD matcher implementation used by `expect()`.
- `system/CollectionExpectation.cfc`: Collection expectation modes used by `expectAll()`, `expectAny()`, `expectSome()`, and `expectNone()`.
- `system/MockBox.cfc` and `system/mockutils/`: MockBox internals.
- `system/runners/`: BDD, xUnit, BoxLang CLI, HTML, and streaming runners.
- `system/reports/`: Reporters and reporter assets.
- `system/coverage/`: Coverage service and coverage report rendering.
- `system/modules/`: Bundled runtime dependencies such as cbstreams, cbMockData, and globber.
- `tests/specs/`: Main framework test specs. This directory contains both `.cfc` CFML specs and `.bx` BoxLang-only specs.
- `bx/`: BoxLang browser/test harness assets.
- `cfml/`: CFML browser/test harness assets.
- `docs/`: Release and feature documentation.
- `test-visualizer/`: Static visualizer assets.

## Engine And File-Type Rules

- Use `.bx` for BoxLang-only specs and features.
- Use `.cfc` for cross-engine TestBox framework specs and CFML-compatible code.
- BoxLang-only specs belong under `tests/specs` unless a task explicitly targets a harness under `bx/`.
- Do not duplicate the same feature spec under `bx/tests/specs` and `cfml/tests/specs` unless the harness itself requires it.
- When using BoxLang-only BIFs or types such as `dataNavigate()`, `setOf()`, `BoxSet`, or future Range features, add a runtime guard in the expectation/assertion layer and tests that verify clean behavior.
- Do not call a BoxLang BIF from shared CFML code unless it is guarded or only executed on BoxLang.
- Preserve Adobe ColdFusion and Lucee behavior for existing `.cfc` APIs.

## Current Assertion And Expectation Surface

Core equality flows through `Assertion.equalize()`. Keep it as the single shared equality engine for `$assert.isEqual()`, `$assert.isNotEqual()`, `expect().toBe()`, Data Navigator path value assertions, arrays, structs, queries, XML, UDFs, and BoxLang sets.

Important newer features include:

- `Expectation.withContext( message )` for contextual failure messages.
- Collection modes: `expectAll()`, `expectAny()`, `expectSome()`, and `expectNone()`.
- Grouped assertions: `$assert.all()` and `assertAll()`.
- Truthiness matchers: `toBeTruthy()` and `toBeFalsy()`.
- Identity matcher: `toBeSameInstanceAs()` and negated dynamic form.
- Size alias: `toHaveSize()` delegates to `toHaveLength()`.
- Exception predicate matcher: `toThrowMatching( predicate )`.
- Include helpers: `toIncludeAll()`, `toIncludeAny()`, `toIncludeNone()` and `$assert.includesAll()`/`includesAny()`/`includesNone()`.
- BoxLang Data Navigator expectations: `toHavePath()`, `toHavePathValue()`, `toHavePathType()`, `toHavePathSatisfying()`, `path()`, and `queryPath()`.
- BoxLang Set expectations: `toBeASet()`, `toEqualSet()`, `toBeSubsetOf()`, `toBeSupersetOf()`, `toBeDisjointFrom()`, `toHaveUnion()`, `toHaveIntersection()`, `toHaveDifference()`, and `toHaveSymmetricDifference()`.

For dynamic negation, `Expectation.onMissingMethod()` treats matcher names starting with `not` as negated calls. Prefer implementing the positive matcher once with `this.isNot` handling when that preserves semantics. For methods where negated behavior has different semantics, such as multi-result path checks, share private helpers instead of catching assertion failures from the positive method.

## BDD And xUnit Patterns

BDD specs:

```cfml
component extends="testbox.system.BaseSpec" {
    function run() {
        describe( "Feature Name", function() {
            beforeEach( function() {
                // setup
            } );

            it( "does something", function() {
                expect( actual ).toBe( expected );
            } );
        } );
    }
}
```

BoxLang BDD specs:

```boxlang
class extends="testbox.system.BaseSpec" {
    function run() {
        describe( "Feature Name", () => {
            it( "does something", () => {
                expect( actual ).toBe( expected );
            } );
        } );
    }
}
```

xUnit specs:

```cfml
component extends="testbox.system.BaseSpec" {
    function setup() {
        // setup before each test
    }

    function testSomething() {
        var actual = target.doWork();
        $assert.isEqual( expected, actual );
    }

    function teardown() {
        // cleanup after each test
    }
}
```

## Formatting And Style

- Follow `.cfformat.json` conventions.
- Use spaced markers and calls: `func( arg )`, `{ key : value }`, `[ item, item ]`, `( condition )`.
- Use padded binary operators: `a + b`, `x == y`.
- Use 4-space indentation in CFML and BoxLang files.
- Prefer double quotes for strings unless local code clearly uses single quotes for a reason.
- Do not use semicolons in normal CFML/BoxLang code. Semicolons are allowed only where the language or existing convention requires them, such as property/param declarations, no-body BoxLang components, and ACF/Lucee `continue`/`break` cases.
- Keep changes small and local. Avoid unrelated formatting churn.
- Add focused tests for all new features and bug fixes.

## Running Tests

Read `.agents/skills/testbox-runners/SKILL.md` before changing runners, runner options, test execution behavior, or CI test commands.

### Preferred BoxLang CLI Runner

Use the BoxLang runner for BoxLang-only specs and for fast focused validation:

```bash
./run
./run --directory=tests.specs --reporter=text
./run --bundles=tests.specs.DataNavigatorSpec --recurse=false --reporter=text
./run --bundles=tests.specs.SetExpectationsSpec --recurse=false --reporter=text
./run --bundles=tests.specs.SetExpectationsSpec,tests.specs.DataNavigatorSpec --recurse=false --reporter=text
```

Important: use `--bundles=...` with the BoxLang runner. Do not pass a bundle as `bundles=...` without the leading `--`. For `.bx` specs, prefer `./run`; `box testbox run` can route through a CFML engine depending on the active CommandBox server and may fail to resolve BoxLang-only specs.

Useful BoxLang runner options include:

```bash
./run --dry-run
./run --dry-run=json
./run --stream --show-failed-only --stacktrace=short
./run --filter-specs="specific spec name" --hide-skipped=true
./run --labels=unit --excludes=integration
./run --slow-threshold-ms=250 --top-slowest=10
```

### CommandBox And CFML Engines

Install dependencies:

```bash
box install
```

Start engine-specific servers:

```bash
box run-script start:boxlang
box run-script start:adobe
box run-script start:lucee
```

View engine logs:

```bash
box run-script log:boxlang
box run-script log:adobe
box run-script log:lucee
```

Run CommandBox/TestBox CLI workflows for CFML-compatible tests when the task requires Adobe ColdFusion or Lucee coverage:

```bash
box testbox run
box testbox run bundles=tests.specs.AssertionsTest
box testbox run reporter=json
box testbox run labels=unit --excludes=integration
```

Format checks:

```bash
box run-script format
box run-script format:check
box run-script format:watch
```

Release script:

```bash
box run-script release
```

## Reporters And Output

Core reporters are selected by string name or custom reporter class path. Built-in reporters include:

- `json`
- `xml`
- `raw`
- `simple`
- `dot`
- `text`
- `junit`
- `antjunit`
- `console`
- `min`
- `mintext`
- `tap`
- `doc`
- `codexwiki`

CLI mode defaults to a text-style reporter; web mode defaults to `simple`. The BoxLang CLI runner defaults to `console`, and switches to `text` internally for streaming output to avoid stdout conflicts.

Reporter implementations live in `system/reports` and should implement or conform to `IReporter.cfc`. Use reporter options structs for reporter-specific behavior instead of adding global runner flags unless the option affects runner behavior.

## Coverage

Coverage support lives in `system/coverage`. Coverage is configured through the TestBox `options.coverage` struct and can be integrated into web runners and CI reports. Use the `testing-coverage` skill before changing coverage collection, report generation, coverage paths, or CI coverage behavior.

## Mocking And Fixtures

MockBox is integrated through `BaseSpec` helpers. Use `testbox-mockbox` for mocking behavior and `testing-fixtures` or `testbox-cbmockdata` for test data setup.

Common patterns:

```cfml
var mockService = createMock( "path.to.Service" );
mockService.$( "methodName" ).$results( "mockValue" );
mockService.$( "methodName" ).$args( "arg1" ).$results( "specificResult" );

var spy = createSpy( targetObject, "methodName" );
var stub = createStub().$( "getData" ).$results( mockData );
var emptyMock = createEmptyMock( "com.interfaces.IService" );

expect( mockService.$callLog().getData ).toHaveLength( 1 );
expect( mockService.$times( 2, "methodName" ) ).toBeTrue();
```

## BoxLang-Only Feature Guidance

For Data Navigator, Set, Range, or other BoxLang runtime features:

- Put specs in `.bx` files under `tests/specs`.
- Use `./run --bundles=... --recurse=false --reporter=text` for focused validation.
- Add runtime checks at the matcher/assertion boundary so CFML engines receive a clear unsupported-feature error or a clean skip.
- Keep shared equality in `Assertion.equalize()` unless there is a strong reason to introduce a separate comparison abstraction.
- For BoxLang `BoxSet`, use `isInstanceOf( target, "BoxSet" )` until a stable `isSet()` BIF exists in the BoxLang runtime used by TestBox. Compare sets by `size()` plus `contains()` semantics, not by array order.
- For Data Navigator path assertions, keep missing-path semantics explicit: positive path assertions fail when a path is missing, while negated path assertions pass when a path is missing.

## Dependency Notes

Project dependencies are managed by CommandBox in `box.json`:

- `cbstreams`: functional collection utilities.
- `cbMockData`: mock data generation.
- `globber`: file pattern discovery.

Development dependencies include `commandbox-boxlang` and `commandbox-cfformat`.

## Validation Expectations

- For a focused bug fix, run the smallest relevant spec bundle first.
- For assertion or expectation changes, run the touched spec plus nearby assertion/BDD specs when practical.
- For BoxLang-only features, run the focused `.bx` spec with `./run`.
- For cross-engine behavior, run relevant CFML-compatible specs through CommandBox and, when required, verify against BoxLang, Adobe ColdFusion, and Lucee servers.
- Do not leave a feature marked complete unless tests exist and the relevant runner passes.
