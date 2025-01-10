# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

* * *

## [Unreleased]

## [6.0.1] - 2025-01-10

## [6.0.1] - 2024-12-05

## [6.0.0] - 2024-09-27

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

[Unreleased]: https://github.com/aliaspooryorik/TestBox/compare/v6.0.1...HEAD

[6.0.1]: https://github.com/aliaspooryorik/TestBox/compare/v6.0.1...v6.0.1


[6.0.0]: https://github.com/Ortus-Solutions/TestBox/compare/bc7774b4cc681cd8dfab08b2f3bba26a75f5601b...v6.0.0
