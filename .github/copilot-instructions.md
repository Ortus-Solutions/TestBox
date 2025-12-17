# Copilot Instructions for TestBox

## Project Overview

TestBox is the leading BDD/TDD testing framework for BoxLang and CFML applications. It supports both BDD (Behavior-Driven Development) and xUnit testing styles, providing a comprehensive testing ecosystem with built-in mocking capabilities (MockBox), multiple reporters, and CLI/web test runners. BoxLang is now the primary focus while maintaining full CFML compatibility.

## Architecture & Core Components

### Core Testing Engine
- **TestBox.cfc** (`system/TestBox.cfc`): Main orchestrator handling test execution, bundle discovery, and result aggregation
- **BaseSpec.cfc** (`system/BaseSpec.cfc`): Base class for all test specs - provides both BDD DSL (`describe()`, `it()`, `beforeEach()`) and xUnit methods (`setup()`, `test*()`, `tearDown()`)
- **Expectation.cfc** (`system/Expectation.cfc`): BDD assertion engine with fluent matcher API (`expect().toBe()`, `expect().notToBeEmpty()`)
- **CollectionExpectation.cfc** (`system/CollectionExpectation.cfc`): Collection-based expectations via `expectAll()` for testing arrays and collections
- **MockBox.cfc** (`system/MockBox.cfc`): Standalone mocking framework for creating spies, stubs, and mocks (fully converted to script in v6.0+)

### Multi-Language Support Pattern
- **BoxLang Primary**: `.bx` files supported with dedicated `BoxLangRunner.bx` CLI runner
- **CFML Compatibility**: `.cfc` files with traditional CFML runners (`BDDRunner.cfc`, `UnitRunner.cfc`)
- **File Discovery**: Default bundle pattern `*Spec*.cfc|*Test*.cfc|*Spec*.bx|*Test*.bx`

### Code Formatting Standards
- **Spacing Requirements**: All code must include spacing on all markers for improved readability (`.cfformat.json`)
- **Key Rules**: Padding in brackets `( condition )`, function calls `func( arg )`, structs `{ key : value }`, arrays `[ item, item ]`
- **Operators**: Binary operators require padding `a + b`, `x == y`
- **Alignment**: Consecutive assignments, properties, and parameters are aligned
- **Indentation**: 4-space tabs, max 115 columns, double quotes for strings

### Reporter Architecture
- **Interface-Driven**: All reporters implement `IReporter.cfc` interface
- **Multi-Format Output**: HTML, JSON, XML, Console, TAP, JUnit, ANT-JUnit formats
- **Context-Aware**: CLI mode defaults to `text` reporter, web mode defaults to `simple` reporter

## Critical Developer Workflows

### Test Bundle Structure Pattern
```javascript
// BDD Style - All test specs must extend BaseSpec
component extends="testbox.system.BaseSpec" {
    function run() {
        describe("Feature Name", function() {
            beforeEach(function() { /* setup */ });
            it("should do something", function() {
                expect(actual).toBe(expected);
            });
        });
    }
}

// xUnit Style - Traditional unit testing approach
component extends="testbox.system.BaseSpec" {
    function setup() {
        // Global setup before each test
    }

    function testSomething() {
        var actual = someFunction();
        $assert.isEqual(expected, actual);
    }

    function tearDown() {
        // Cleanup after each test
    }
}
```

### CLI Testing via BoxLang Runner
```bash
# Primary CLI execution method (root-level runner scripts)
./run                                       # Run default tests.specs
./run my.bundle                             # Run specific bundle
./run --directory=my.tests                  # Specific directory
./run --bundles=my.bundle                   # Specific bundles
./run --reporter=json                       # Custom reporter
./run.bat                                   # Windows equivalent

# All options:
# --bundles: Test bundles to run (comma-separated), defaults to `*`
# --bundles-pattern: Pattern to match test bundles, defaults to `"*Spec*.cfc|*Test*.cfc|*Spec*.bx|*Test*.bx"`
# --directory: Directories to look for tests (dot-notation), defaults to `tests.specs`
# --reporter: Reporter to use (text, json, xml, etc.)
# --labels: Labels to run, defaults to `*`
# --excludes: Labels to exclude
# --recurse: Recurse into subdirectories, defaults to `true`
# --filter-bundles: Filter by bundle names
# --filter-suites: Filter by suite names
# --filter-specs: Filter by test/spec names
# --eager-failure: Fail fast, defaults to `false`
# --verbose: Stream test status as they run
```

### Web Testing Setup
- **HTMLRunner.cfm**: Web-based test execution endpoint
- **Application.cfc**: Sets up TestBox mappings and routes
- **URL Parameters**: `?method=runRemote&bundles=...&reporter=...`

### Build & Development Commands
```bash
# Format code (BoxLang + CFML)
box run-script format

# Multi-engine testing  
box run-script start:lucee      # Lucee 5
box run-script start:adobe      # Adobe CF 2025
box run-script start:boxlang    # BoxLang server

# View logs
box run-script log:lucee
box run-script log:adobe
box run-script log:boxlang

# Release process
box run-script release
```

## Key Implementation Patterns

### Dual Testing Approach
- **BDD Style**: Uses `describe()`, `it()`, `beforeEach()`, `afterEach()` for behavior specification
- **xUnit Style**: Uses `setup()`, `test*()`, `tearDown()` methods for traditional unit testing
- **Assertion Methods**: BDD uses `expect()` fluent API, xUnit uses `$assert` object methods
- **Mixed Usage**: Both styles can coexist within the same test bundle

### BDD DSL Implementation
- **Suite Nesting**: `describe()` blocks create nested test suites stored in `this.$suites` array
- **Execution Context**: `this.$suiteContext` tracks current suite being defined
- **Lifecycle Hooks**: `beforeEach()`, `afterEach()`, `beforeAll()`, `afterAll()` stored per suite

### xUnit Pattern Implementation
- **Method Discovery**: Test methods automatically discovered by `test*` prefix convention
- **Lifecycle Methods**: `setup()` and `tearDown()` called before/after each test method
- **Global Hooks**: `beforeTests()` and `afterTests()` for bundle-level setup/cleanup
- **Assertion Object**: `$assert` provides traditional assertion methods (`isEqual()`, `isTrue()`, `isNull()`)

### MockBox Integration Pattern
```javascript
// MockBox is integrated into BaseSpec - comprehensive mocking framework
var mockService = createMock( "path.to.Service" );
mockService.$( "methodName" ).$results( "mockValue" );
mockService.$( "methodName", "arg1" ).$args( "arg1" ).$results( "specificResult" );

// Advanced mocking capabilities
var spy = createSpy( targetObject, "methodName" );
var stub = createStub().$( "getData" ).$results( mockData );
var emptyMock = createEmptyMock( "com.interfaces.IService" );

// Verification patterns
expect( mockService.$callLog().getData ).toHaveLength( 1 );
expect( mockService.$times( 2, "methodName" ) ).toBeTrue();
```

### Collection Expectations
```javascript
// Test collections with expectAll() - returns CollectionExpectation instance
expectAll( [ user1, user2, user3 ] ).toHaveKey( "name" );
expectAll( arrayOfResults ).toBe( true );
expectAll( [ obj1, obj2 ] ).toBeInstanceOf( "MyClass" );
```

### Expectation Chaining Architecture
- **Fluent API**: `expect(actual).toBe(expected).toHaveLength(3)`
- **Negation Pattern**: Dynamic `not` prefix (`expect().notToBe()`)
- **Custom Matchers**: Register via `registerMatcher(name, closure)`

### Coverage Service Integration
- **CoverageService.cfc**: Built-in code coverage analysis
- **Configuration**: Via `options.coverage` struct in TestBox constructor
- **Integration**: Automatic coverage collection during test execution

### Dependency Management
- **cbstreams**: Functional programming utilities for data manipulation and stream processing
- **cbMockData**: Full-featured data mocking library providing realistic test data generation (names, addresses, numbers, dates, lorem text)
- **globber**: File pattern matching and discovery utilities for test bundle location
- **MockBox**: Integrated mocking framework (spies, stubs, mocks) with verification capabilities
- **Installation**: Dependencies auto-installed to `system/modules/` via CommandBox package manager

## Testing Conventions

### File Organization
- **Test Location**: `tests/specs/` directory by convention
- **Naming**: `*Test.cfc`, `*Spec.cfc`, `*Test.bx`, `*Spec.bx` patterns
- **Suite Structure**: Mirror source code directory structure in test folders

### Label-Based Filtering
```javascript
// Suite labeling for selective execution
describe("Feature", { labels: "slow,integration" }, function() {
    it("test case", { labels: "unit" }, function() { /* */ });
});

// CLI filtering: --labels=unit --excludes=slow
```

### Focused Testing
- **fdescribe()** / **fit()**: Focus execution on specific suites/specs
- **xdescribe()** / **xit()**: Skip suites/specs during development

## Integration Points

### ColdBox Framework Integration
- **Enhanced BaseSpec**: ColdBox provides extended base spec with framework-specific helpers
- **Application Testing**: Built-in request/response simulation for integration tests
- **Service Mocking**: Deep integration with WireBox for dependency injection testing

### CommandBox Integration
- **TestBox CLI**: `testbox-cli` package provides `testbox run` commands
- **File Watching**: Automatic test re-execution on file changes
- **CI/CD Integration**: JUnit/TAP/JSON output formats for build systems

### Standalone Usage
- **Framework Agnostic**: Can test any BoxLang/CFML application
- **Mapping Requirements**: Requires `/testbox` mapping to system directory
- **Web Server**: Can run via any CFML web server (Lucee, Adobe CF, CommandBox)

## Development Commands

```bash
# Core development workflow
box install                    # Install dependencies
box run-script format         # Format all code (.cfformat.json rules)
box run-script format:check   # Check formatting without changes
box run-script format:watch   # Auto-format on file changes
box run-script start:lucee    # Start development server
./run                         # Run tests via BoxLang CLI

# Multi-engine testing
box run-script start:adobe    # Adobe CF 2025
box run-script start:boxlang  # BoxLang server
box run-script log:lucee      # View server logs
box run-script log:adobe      # View Adobe CF logs
box run-script log:boxlang    # View BoxLang logs
```