# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [4.1.0] => 2020-MAY-27

### Fixed

* [TESTBOX-283] - Fix type on test results for bundlestats
* [TESTBOX-286] - `DebugBuffer` was being removed instead of resetting to empty for `getMemento`
* [TESTBOX-281] - `request.testbox`  Component ... has no accessible Member with name [$TESTID]

### Added

* [TESTBOX-282] - Added cfml engine and version as part of the test results as properties
* [TESTBOX-284] - Update all reporters so they can just build and return the report with no content type or context repsonse resets
* [TESTBOX-285] - make `buildReporter` public in the testbox core
