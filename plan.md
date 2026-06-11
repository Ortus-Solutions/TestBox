# TestBox Assertions And Expectations Roadmap

## Rules

- Every feature must include tests.
- Full suite must pass before completion.
- BoxLang-only features must skip cleanly on CFML engines.
- Preserve backward compatibility for existing `$assert`, `expect()`, and `expectAll()` behavior.

## Verification

- [x] Run `box run-script format:check`
- [x] Run `box testbox run`
- [ ] Run BoxLang-specific tests for navigator, set, and range expectations
- [ ] Confirm CFML engines skip BoxLang-only specs cleanly

## Phase 0: Test Harness Baseline

- [x] Identify existing assertion/expectation specs: `BaseAssertionsTest.cfc`, `AssertionsTest.cfc`, `BDDTest.cfc`
- [ ] Add dedicated BoxLang-only specs for Data Navigators
- [ ] Add dedicated BoxLang-only specs for Sets
- [ ] Add dedicated BoxLang-only specs for Ranges

## Phase 1: Expectation Context (COMPLETE)

- [x] Add `Expectation.withContext( message )`
- [x] Include context in matcher failure messages
- [x] Include context in negated matcher failure messages
- [x] Include context in custom matcher failures
- [x] Add tests for passing and failing contextual expectations
- [x] Inject context for dynamic `not*` matchers via `onMissingMethod`

## Phase 2: Collection Expectation Modes (COMPLETE)

- [x] Keep current `expectAll()` behavior unchanged
- [x] Add `expectAny( collection )`
- [x] Add `expectSome( collection, min = 1, max = 0 )`
- [x] Add `expectNone( collection )`
- [x] Support arrays
- [x] Support structs
- [x] Add pass count and index/key details to failure messages
- [x] Add tests for all pass/fail combinations
- [x] Add chainability tests for collection expectations

## Phase 3: Grouped Assertions (COMPLETE)

- [x] Add `$assert.all( executables, heading = "" )`
- [x] Add `assertAll()` facade to `BaseSpec`
- [x] Aggregate assertion failures — catch `TestBox.AssertionFailed`, collect all, rethrow single aggregated
- [x] Unexpected exceptions rethrow immediately (not caught by `all()`)
- [x] Heading prepended to aggregated failure message
- [x] Detail contains numbered list of individual failures
- [x] Add tests: all-pass, multi-fail, single-fail, heading, unexpected exception, facade shortcut

## Phase 4: Low-Risk Matchers

- [ ] Add `$assert.isTruthy()`
- [ ] Add `$assert.isFalsy()`
- [ ] Add `toBeTruthy()`
- [ ] Add `toBeFalsy()`
- [ ] Add `toBeSameInstanceAs()`
- [ ] Add `notToBeSameInstanceAs()`
- [ ] Add `toHaveSize()`
- [ ] Add `toThrowMatching( predicate )`
- [ ] Add `toIncludeAll( needles )`
- [ ] Add `toIncludeAny( needles )`
- [ ] Add `toIncludeNone( needles )`
- [ ] Add tests for all new matchers and negated forms

## Phase 5: Better Failure Diagnostics

- [ ] Add nested mismatch path reporting for arrays
- [ ] Add nested mismatch path reporting for structs
- [ ] Add query row/column mismatch reporting
- [ ] Add lazy assertion messages
- [ ] Improve `expectAll()` failure context
- [ ] Add tests for diagnostics and lazy messages

## Phase 6: BoxLang Data Navigator Expectations

- [ ] Add runtime guard for BoxLang-only navigator features
- [ ] Add `toHavePath( path )`
- [ ] Add `toHavePathValue( path, expected )`
- [ ] Add `toHavePathType( path, type )`
- [ ] Add `toHavePathSatisfying( path, predicate )`
- [ ] Add `path( path )` returning a normal `Expectation`
- [ ] Add `queryPath( path )` returning an expectation over query results
- [ ] Add tests for dot paths, indexes, wildcards, filters, recursive descent, and missing paths

## Phase 7: BoxLang Set Expectations

- [ ] Add `toBeSet()`
- [ ] Add `toEqualSet( expected )`
- [ ] Add `toBeSubsetOf( expected )`
- [ ] Add `toBeSupersetOf( expected )`
- [ ] Add `toBeDisjointFrom( expected )`
- [ ] Add `toHaveUnion( other, expected )`
- [ ] Add `toHaveIntersection( other, expected )`
- [ ] Add `toHaveDifference( other, expected )`
- [ ] Add `toHaveSymmetricDifference( other, expected )`
- [ ] Add tests for default, linked, sorted, case-sensitive, Java Set, and numeric normalization behavior

## Phase 8: BoxLang Range Expectations

- [ ] Add `toBeRange()`
- [ ] Add `toContainValue( value )`
- [ ] Add `toContainRange( range )`
- [ ] Add `toBeInRange( range )`
- [ ] Add `toBeBeforeRange( range )`
- [ ] Add `toBeAfterRange( range )`
- [ ] Add `toBeBounded()`
- [ ] Add `toBeUnbounded()`
- [ ] Add `toBeHalfBounded()`
- [ ] Add `toBeIterable()`
- [ ] Add `toBeAscending()`
- [ ] Add `toBeDescending()`
- [ ] Add `toBeEmpty()`
- [ ] Add `toHaveStep( step )`
- [ ] Add `toClampTo( value, expected )`
- [ ] Add tests for numeric, decimal, character, date, stepped, exclusive, unbounded, half-bounded, typed, and non-iterable ranges

## Phase 9: Data Navigator With Sets And Ranges

- [ ] Add `queryPath().asSet()` support
- [ ] Support set expectations on navigator query results
- [ ] Support range expectations on navigator path values
- [ ] Add tests for path values in ranges
- [ ] Add tests for query results converted to sets

## Phase 10: Partial And Asymmetric Matching

- [ ] Add `toContainSubset( sample )`
- [ ] Add `toIncludeSubset( sample )`
- [ ] Add `toMatchPattern( pattern )`
- [ ] Add matcher helpers for any type, anything, string containing, string matching, array containing, struct containing, allOf, and anyOf
- [ ] Add nested mismatch diagnostics
- [ ] Add tests for partial and asymmetric matching

## Phase 11: Custom Equality And Object Formatters

- [ ] Add `addEqualityTester( closure )`
- [ ] Add `addObjectFormatter( closure )`
- [ ] Wire equality testers into deep equality
- [ ] Wire object formatters into failure messages
- [ ] Ensure test isolation for registered testers and formatters
- [ ] Add tests for custom equality and custom formatting
