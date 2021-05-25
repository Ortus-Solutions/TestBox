# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

----

## [4.3.1] => 2021-MAY-25

### Fixed

- [TESTBOX-310](https://ortussolutions.atlassian.net/browse/TESTBOX-310) acf regression on caluclating length of arrays with len()

----

## [4.3.0] => 2021-MAY-24

### Bugs

- [TESTBOX-299](https://ortussolutions.atlassian.net/browse/TESTBOX-299) Bug in XML-escaping in JUnit reporters
- [TESTBOX-298](https://ortussolutions.atlassian.net/browse/TESTBOX-298) min reporter is making assumptions that url.directory will exist
- [TESTBOX-297](https://ortussolutions.atlassian.net/browse/TESTBOX-297) code coverage QoQ doesn't account for nulls in sum\(\)
- [TESTBOX-287](https://ortussolutions.atlassian.net/browse/TESTBOX-287) Simple Reporter doesn't show the Test that fails but the assertion in the origin

### Improvements

- [TESTBOX-305](https://ortussolutions.atlassian.net/browse/TESTBOX-305) Show the type of the actual pass into instance type expectations
- [TESTBOX-300](https://ortussolutions.atlassian.net/browse/TESTBOX-300) Improvement: shift test summary to the bottom of MinTextReporter
- [TESTBOX-295](https://ortussolutions.atlassian.net/browse/TESTBOX-295) Update the junit and antjunit reports to NOT include supported locales due to the size of the packet

### New Features

- [TESTBOX-309](https://ortussolutions.atlassian.net/browse/TESTBOX-309) Reworked simple reporter to better visualize fail origins and tag contexts.
- [TESTBOX-308](https://ortussolutions.atlassian.net/browse/TESTBOX-308) Simple reporter now has editor integrations to open failure and error stacks in your editor
- [TESTBOX-307](https://ortussolutions.atlassian.net/browse/TESTBOX-307) New text and min text reporters to improve visualizations
- [TESTBOX-306](https://ortussolutions.atlassian.net/browse/TESTBOX-306) Test failures triggered in beforeAll are counted incorrectly

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
