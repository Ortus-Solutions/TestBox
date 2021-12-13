# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [4.5.0] => 2021-DEC-13

### Fixed

* [TESTBOX-336](https://ortussolutions.atlassian.net/browse/TESTBOX-336) When using testSpecs or testSuites via non browser executions decoding is not working
* [TESTBOX-330](https://ortussolutions.atlassian.net/browse/TESTBOX-330) Catch spec errors with no type
* [TESTBOX-328](https://ortussolutions.atlassian.net/browse/TESTBOX-328) Lucee 5.3.8 reMatchNoCase\(\) change breaks expected execptions
* [TESTBOX-327](https://ortussolutions.atlassian.net/browse/TESTBOX-327) Code Coverage in CI only reports on a single file rather than all files
* [TESTBOX-323](https://ortussolutions.atlassian.net/browse/TESTBOX-323) Testbox refuses to update to current release
* [TESTBOX-322](https://ortussolutions.atlassian.net/browse/TESTBOX-322) Junit reports issues with describe containing "/"

### Added

* Migration to github actions
* [TESTBOX-332](https://ortussolutions.atlassian.net/browse/TESTBOX-332) toBe\{Type\} is incomplete
* [TESTBOX-329](https://ortussolutions.atlassian.net/browse/TESTBOX-329) Full Null support

----

## [4.4.0] => 2021-JUN-16

### Fixed

* [TESTBOX-320](https://ortussolutions.atlassian.net/browse/TESTBOX-320) Runner tries to instantiate abstract classes
* [TESTBOX-319](https://ortussolutions.atlassian.net/browse/TESTBOX-319) Fix HTTP Status Headers Being Removed By Reporters when resetting html head
* [TESTBOX-318](https://ortussolutions.atlassian.net/browse/TESTBOX-318) Chaining "not" matchers before regular matchers doesn't work correctly
* [TESTBOX-316](https://ortussolutions.atlassian.net/browse/TESTBOX-316) Coverage output doesn't escape ending script tag
* [TESTBOX-315](https://ortussolutions.atlassian.net/browse/TESTBOX-315) ConsoleReporter fails with missing functions in assets/text
* [TESTBOX-313](https://ortussolutions.atlassian.net/browse/TESTBOX-313) No matching function \[SPACE\] found
* [TESTBOX-311](https://ortussolutions.atlassian.net/browse/TESTBOX-311) CF error variable \[THISBUNDLE\] doesn't exist when running tests

### Changed

* [TESTBOX-317](https://ortussolutions.atlassian.net/browse/TESTBOX-317) Full Null Support Some items of array can be NULL
* [TESTBOX-314](https://ortussolutions.atlassian.net/browse/TESTBOX-314) text and min text whitespace management
* [TESTBOX-301](https://ortussolutions.atlassian.net/browse/TESTBOX-301) notToBeBetween seems to be the same as toBeBetween

----

## [4.3.1] => 2021-MAY-25

### Fixed

* [TESTBOX-310](https://ortussolutions.atlassian.net/browse/TESTBOX-310) acf regression on caluclating length of arrays with len()

----

## [4.3.0] => 2021-MAY-24

### Bugs

* [TESTBOX-299](https://ortussolutions.atlassian.net/browse/TESTBOX-299) Bug in XML-escaping in JUnit reporters
* [TESTBOX-298](https://ortussolutions.atlassian.net/browse/TESTBOX-298) min reporter is making assumptions that url.directory will exist
* [TESTBOX-297](https://ortussolutions.atlassian.net/browse/TESTBOX-297) code coverage QoQ doesn't account for nulls in sum\(\)
* [TESTBOX-287](https://ortussolutions.atlassian.net/browse/TESTBOX-287) Simple Reporter doesn't show the Test that fails but the assertion in the origin

### Improvements

* [TESTBOX-305](https://ortussolutions.atlassian.net/browse/TESTBOX-305) Show the type of the actual pass into instance type expectations
* [TESTBOX-300](https://ortussolutions.atlassian.net/browse/TESTBOX-300) Improvement: shift test summary to the bottom of MinTextReporter
* [TESTBOX-295](https://ortussolutions.atlassian.net/browse/TESTBOX-295) Update the junit and antjunit reports to NOT include supported locales due to the size of the packet

### New Features

* [TESTBOX-309](https://ortussolutions.atlassian.net/browse/TESTBOX-309) Reworked simple reporter to better visualize fail origins and tag contexts.
* [TESTBOX-308](https://ortussolutions.atlassian.net/browse/TESTBOX-308) Simple reporter now has editor integrations to open failure and error stacks in your editor
* [TESTBOX-307](https://ortussolutions.atlassian.net/browse/TESTBOX-307) New text and min text reporters to improve visualizations
* [TESTBOX-306](https://ortussolutions.atlassian.net/browse/TESTBOX-306) Test failures triggered in beforeAll are counted incorrectly

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
