# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

### Added

- TESTBOX-471 Ask AI on failures: copy a ready-made prompt, preview it, open it in ChatGPT or Claude, or copy it as JSON for a coding agent. It is on by default with a first-use notice and is controlled by the `aiAssist`, `aiProviders`, `aiContextLines`, `aiStackFrames` and `aiPrompt` reporter options.
- TESTBOX-471 The `urlParams` reporter option sets the run params the re-run links carry when a report is produced from code and there is no url scope.
- TESTBOX-471 `build/vendor` rebuilds the inlined front-end libraries with one command (`box run-script assets:update`) and CI keeps them honest.
- TESTBOX-469 New `AgentReporter` (`reporter=agent`): a compact, token-efficient JSON reporter for AI agents and automation. It emits totals plus only failed/errored specs, with options `detail`, `maxFailures`, `maxMessageLength`, `includeStack`, `stackDepth`, `includeSkipped` and `includeDebug`.
- Browser testing on BoxLang with the bx-playwright module: `testbox.system.BrowserSpec` with `browse( callback, options )`, `this.playwright()` and `browserAvailable()`, the `browserProfile` and `baseURL` class annotations, one browser per bundle closed after the bundle (and, as a safety net, every browser a run opened is closed when the run ends, even when an `afterAll()` throws or a spec aborts the request), and the kept screenshots, trace and videos of a failed `browse()` attached to the spec. Specs skip with an install hint when bx-playwright is missing or the engine is not BoxLang. The logic lives in `testbox.system.browser.BrowserSupport`.
- Browser matchers in `testbox.system.browser.BrowserMatchers`, registered for every `BrowserSpec` bundle and usable from any BoxLang spec with `addMatchers()`: `toHaveTitle()`, `toHaveURL()`, `toHavePath()` and `toSee()` for pages, `toHaveText()`, `toBeVisible()`, `toBeHidden()`, `toHaveCount()` and `toHaveValue()` for locators, plus their `not` forms. They delegate to the retrying bx-playwright assertions, also when negated, and fail with the bx-playwright message.
- `attach( path, type, name )` in every spec to attach files to the running spec, kept in the new `attachments` array of the spec stats for passed and failed specs. The JSON report includes them, the Simple report links them, the JUnit and ANT JUnit reports add a `<system-out>` with one `[[ATTACHMENT|path]]` line per file, and the text, console and stream outputs list them under failed specs.
- Spec retries: a `retries` argument on `it()`, `fit()` and `xit()`, a `retries` bundle annotation, a `retries` method annotation for xUnit tests, and a global `retries` runner option (BoxLang runner `--retries=N`). The spec value wins over the bundle annotation, which wins over the global option. A failing or erroring spec reruns its `beforeEach()`, body and `afterEach()` (or `setup()`, test and `teardown()`) up to N more times and records the final attempt. Skipped specs are never retried. The new `attempts` spec stat counts the runs and the text, console, Simple and stream outputs show "(passed after N attempts)".
- BoxLang runner `--failed`: every run writes `{reportpath}/.testbox-failed.json` with the bundles and spec ids that failed or errored, and `./run --failed` reruns only those. Bundles that failed outside of a spec (`beforeAll()`, `afterAll()`) are listed, not rerun. When the file is missing or lists nothing, it prints a message and runs nothing.
- BoxLang runner `--web-server`, `--web-server-url` and `--web-server-timeout`: start a web server command before the tests, wait until its URL answers, stop it and its child processes after the tests, and exit with code 1 when it does not answer in time. The URL becomes the default `baseURL` of `BrowserSpec` bundles through `server.testbox.webServerURL`.

### Changed

- TESTBOX-471 The HTML reporters (`Simple`, `Min`, `Dot`, `Doc`) are rebuilt on Bootstrap 5.3, Bootstrap Icons, Alpine and Prism, with light and dark themes and the new TestBox logos. Everything is still inlined so reports run airgapped, and a page went from about 1.4 MB to about 0.45 MB.
- TESTBOX-471 The verdict is the first thing in every HTML report: a sticky green or red banner with the counts, a proportion bar and status filters, and bundle exceptions get their own alert.
- TESTBOX-471 Re-run links (run bundle, suite or spec) now carry `labels`, `excludes`, `directory`, `reporter` and the other params of the original run.
- TESTBOX-471 `Dot` opens a spec's details in a drawer instead of `alert()`, `Doc` is a styled page with a bundle navigation, and the status chips of `Min` and `Dot` now filter.
- TESTBOX-471 Report templates keep only markup. Their logic moved to `system/reports/ReportHelper.cfc` and `BaseHTMLReporter.cfc`.
- `Playwright.AssertionFailed` exceptions now count as spec failures, like `TestBox.AssertionFailed`, in BDD specs and xUnit tests, keeping their message and detail. Other `Playwright.*` errors still count as errors.
- xUnit failures now also record the failure detail in the spec stats.

### Fixed

- The `run` script now quotes its arguments, so runner options with spaces reach the BoxLang runner intact.

### Removed

- TESTBOX-471 The `url.fullPage` switch of the HTML reporters. A report is always a complete page.

## [7.1.0] - 2026-09-11

<https://testbox.ortusbooks.com/readme/release-history/whats-new-with-7.1.0>

### Added

- TESTBOX-451 BDD class `skip` annotation support for skipping entire test classes.
- TESTBOX-457 Expectation context support via `expect( value ).withContext( message )` that prepends semantic context to all failure messages including negated matchers and custom matchers.
- TESTBOX-458 Collection expectation modes: `expectAny()`, `expectSome()`, and `expectNone()` alongside existing `expectAll()` with detailed failure summaries including element index/key and pass count reporting.
- TESTBOX-459 Grouped assertions via `$assert.all()`, `assertAll()` that run multiple assertion closures and report every failure at once instead of stopping at the first.
- TESTBOX-460 New matchers: `toBeTruthy()`, `toBeFalsy()`, `toBeSameInstanceAs()`, `toHaveSize()`, `toThrowMatching()`, `toIncludeAll()`, `toIncludeAny()`, and `toIncludeNone()`.
- TESTBOX-461 Set expectations: `toBeASet()`, `toEqualSet()`, `toBeSubsetOf()`, `toBeSupersetOf()`, `toBeDisjointFrom()`, `toHaveUnion()`, `toHaveIntersection()`, `toHaveDifference()`, and `toHaveSymmetricDifference()` for working with BoxLang Set objects.
- TESTBOX-462 Range expectations: `toBeRange()`, `toContainValue()`, `toContainRange()`, `toBeInRange()`, `toBeBeforeRange()`, `toBeAfterRange()`, `toBeBounded()`, `toBeUnbounded()`, `toBeHalfBounded()`, `toBeIterable()`, `toBeAscending()`, `toBeDescending()`, `toHaveStep()`, and `toClampTo()` for BoxLang Range objects.
- TESTBOX-463 Data navigator expectations: `toHavePath()`, `toHavePathValue()`, `toHavePathType()`, `toHavePathSatisfying()`, `path()`, and `queryPath()` for navigating and asserting against nested BoxLang data structures using dot-notation, array indexes, wildcards, filters, and recursive descent.
- TESTBOX-464 New assertion BIFs: `$assert.isTruthy()`, `$assert.isFalsy()`, `$assert.includesAll()`, `$assert.includesAny()`, and `$assert.includesNone()`.

### Changed

- TESTBOX-466 The `coverageEnabled` URL parameter in the CFML test runner now defaults to `false` instead of `true`. Code coverage requires FusionReactor and is now opt-in. Pass `?coverageEnabled=true` to restore the previous behavior.

### Improvements

- TESTBOX-455 Expand the BoxLang CLI url-scope guard so it skips only when the scope truly isn't there, instead of assuming it is always absent in CLI mode.
- Improve matcher failure messages with optional contextual prefix for distinguishing chained expectations.
- Improve `expectAll()` failure messages to include pass/fail counts and per-element failure details with index/key context.
- Add the [What's New With 7.1.0](https://testbox.ortusbooks.com/readme/release-history/whats-new-with-7.1.0) release page documenting all new assertion and expectation features.

### Fixed

- TESTBOX-448 Fix MockBox `$args()` struct-order fragility and add Set/Range support to argument matching.
- TESTBOX-449 Encode HTML for bundle and spec names in the Simple reporter so markup in test names no longer breaks the report.
- TESTBOX-450 Equalize assertions now handle different types of date and date/time objects for equality, instead of blindly calling `actual.equals()`.
- TESTBOX-452 Fix `GetPageContextResponse()` error while running BoxLang in Adobe compatibility mode.
- TESTBOX-453 Fix the BoxLang CLI runner misreading its own script path as a positional bundle argument.
- TESTBOX-454 Fix `KeyNotFoundException [url]` crashing every CLI run on BoxLang 1.17+.
- TESTBOX-456 Simplify the BoxLang CLI url scope guard to a plain `param`.
- TESTBOX-465 Fix `isLucee()` returning `true` on BoxLang, which broke engine detection helpers and engine-conditional skips.
- TESTBOX-467 Support engines running with full null support enabled.
- TESTBOX-468 Fix custom matcher failure messages not routing through the expectation's internal fail method.

## [7.0.0] - 2026-03-17

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-7.0.0>

## [6.5.0] - 2026-01-25

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.5.0>

## [6.4.0] - 2025-09-18

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.4.0>

## [6.3.2] - 2025-04-29

### Fixed

- Update the `run` runners so they use the calculated location paths.

## [6.3.1] - 2025-04-01

### Fixed

- Fixed a typo in BaseReporter

## [6.3.0] - 2025-02-25

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.3.0>

## [6.2.1] - 2025-02-06

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.2.1>

## [6.2.0] - 2025-01-31

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.2.0>

## [6.1.0] - 2025-01-28

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.1.0>

## [6.0.1] - 2024-12-05

## [6.0.0] - 2024-09-27

- <https://testbox.ortusbooks.com/readme/release-history/whats-new-with-6.0.0>

### New Features

- TESTBOX-391 MockBox converted to script
- TESTBOX-392 BoxLang classes support
- TESTBOX-393 New environment helpers to do skip detections or anything you see fit: isAdobe, isLucee, isBoxLang, isWindows, isMac, isLinux
- TESTBOX-394 new `test(), xtest(), ftest()` alias for more natuarl testing
- TESTBOX-397 debug() get's two new arguments: label and showUDFs
- TESTBOX-398 DisplayName on a bundle now shows up in the reports
- TESTBOX-399 xUnit new annotation for @DisplayName so it can show instead of the function name
- TESTBOX-401 BoxLang CLI mode and Runner
- TESTBOX-402 New matcher: toHaveKeyWithCase()
- TESTBOX-403 Assertions: key() and notKey() now have a CaseSensitive boolean argument

## Improvements

- TESTBOX-289 showUDFs = false option with debug()
- TESTBOX-331 TextReporter doesn't correctly support testBundles URL param
- TESTBOX-395 adding missing focused argument to spec methods
- TESTBOX-396 Generating a repeatable id for specs to track them better in future UIs

## Bugs

- TESTBOX-123 If test spec descriptor contains a comma, it can not be drilled down to run that one spec directly
- TESTBOX-338 describe handler in non-called test classes being executed

## Tasks

- TESTBOX-400 Drop Adobe 2018 support

[unreleased]: https://github.com/Ortus-Solutions/TestBox/compare/v7.1.0...HEAD
[7.1.0]: https://github.com/Ortus-Solutions/TestBox/compare/v7.0.0...v7.1.0
[7.0.0]: https://github.com/Ortus-Solutions/TestBox/compare/v6.5.0...v7.0.0
[6.5.0]: https://github.com/Ortus-Solutions/TestBox/compare/v6.4.0...v6.5.0
[6.4.0]: https://github.com/Ortus-Solutions/TestBox/compare/v6.3.2...v6.4.0
[6.3.2]: https://github.com/Ortus-Solutions/TestBox/compare/v6.3.1...v6.3.2
[6.3.1]: https://github.com/Ortus-Solutions/TestBox/compare/v6.3.0...v6.3.1
[6.3.0]: https://github.com/Ortus-Solutions/TestBox/compare/v6.3.0...v6.3.0
[6.2.1]: https://github.com/Ortus-Solutions/TestBox/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/Ortus-Solutions/TestBox/compare/v6.1.0...v6.2.0
[6.1.0]: https://github.com/Ortus-Solutions/TestBox/compare/v6.0.1...v6.1.0
[6.0.1]: https://github.com/Ortus-Solutions/TestBox/compare/v6.0.0...v6.0.1
[6.0.0]: https://github.com/Ortus-Solutions/TestBox/compare/bc7774b4cc681cd8dfab08b2f3bba26a75f5601b...v6.0.0
