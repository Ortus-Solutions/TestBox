# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

### Added

- Add expectation context support via `expect( value ).withContext( message )` that prepends semantic context to all failure messages including negated matchers and custom matchers.
- Add collection expectation modes: `expectAny()`, `expectSome()`, and `expectNone()` alongside existing `expectAll()` with detailed failure summaries including element index/key and pass count reporting.
- Add grouped assertions via `$assert.all()`, `assertAll()` that run multiple assertion closures and report every failure at once instead of stopping at the first.

### Improvements

- Improve matcher failure messages with optional contextual prefix for distinguishing chained expectations.
- Improve `expectAll()` failure messages to include pass/fail counts and per-element failure details with index/key context.

### Fixed

- Fix custom matcher failure messages not routing through the expectation's internal fail method.

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

[unreleased]: https://github.com/Ortus-Solutions/TestBox/compare/v7.0.0...HEAD
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
