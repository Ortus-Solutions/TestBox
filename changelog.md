# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [4.2.1] => 2020-NOV-19

### Fixed

* [TESTBOX-294](https://ortussolutions.atlassian.net/browse/TESTBOX-294) - root path in test browser not enforced

----

## [4.2.0] => 2020-NOV-19

### Fixed

* [TESTBOX-281](https://ortussolutions.atlassian.net/browse/TESTBOX-281) - request.testbox:  Component ... has no accessible Member with name [$TESTID]
* [TESTBOX-290](https://ortussolutions.atlassian.net/browse/TESTBOX-290) - Turning on &quot;Prefix serialized JSON with&quot; in ACF causes issues in code coverage report
* [TESTBOX-293](https://ortussolutions.atlassian.net/browse/TESTBOX-293) - Force properties file to have properties extension and escape special chars

### Added

* [TESTBOX-291](https://ortussolutions.atlassian.net/browse/TESTBOX-291) - refactor usage of locks for debug utility in specs

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
