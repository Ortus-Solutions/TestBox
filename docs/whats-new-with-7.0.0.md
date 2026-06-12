# What's New With TestBox 7.0.0

TestBox 7.0.0 introduces a significant upgrade to the assertions and expectations library, adding grouped assertions, collection expectation modes, rich failure diagnostics, and a suite of new matchers inspired by JUnit 5 and Jasmine.

* * *

## Expectation Context: `withContext()`

Add semantic context to any expectation so failure messages include identifying information. Works with all matchers, negated matchers, and custom matchers.

```javascript
it( "validates a user record", () => {
    expect( user.age )
        .withContext( "user.age" )
        .toBeGT( 0 )

    expect( user.email )
        .withContext( "user.email" )
        .toMatch( "@" )
} )
```

* * *

## Collection Expectation Modes

Three new collection modes complement the existing `expectAll()`.

### `expectAny()`

Passes when at least one element in the collection passes the chained matcher.

```javascript
expectAny( products ).toSatisfy( p => p.onSale )
```

### `expectSome()`

Passes when a bounded number of elements pass. `max = 0` means no upper bound.

```javascript
expectSome( users, min = 2, max = 5 ).toSatisfy( u => u.role == "admin" )
expectSome( items, min = 3 ).toSatisfy( i => i.stock > 0 )
```

### `expectNone()`

Passes when zero elements pass the chained matcher.

```javascript
expectNone( users ).toSatisfy( u => u.banned )
```

### Improved `expectAll()` Failure Messages

All collection modes now produce detailed failure summaries with pass/fail counts and per-element failure context including the element index or struct key.

```javascript
try {
    expectAll( [ 2, 4, 10, 8 ] ).toBeLT( 10 )
} catch ( any e ) {
    // e.message: "expectAll() failed: 1 of 4 element(s) did not pass the [toBeLT] expectation"
    // e.detail:  "Passed: 3 / 4\n\n[3]: The actual [10] is not less than [10]"
}
```

* * *

## Grouped Assertions: `assertAll()`

Run multiple assertion closures and report every failure at once — instead of stopping at the first. Non-assertion exceptions are rethrown immediately.

```javascript
it( "validates a user record completely", () => {
    assertAll( [
        () => expect( user.name ).notToBeEmpty(),
        () => expect( user.email ).toMatch( "@" ),
        () => expect( user.age ).toBeGTE( 18 ),
        () => expect( user.age ).toBeLT( 120 )
    ] )
} )
```

Using the `$assert` style:

```javascript
it( "xUnit style grouped assertions", () => {
    $assert.all(
        executables = [
            () => $assert.isTrue( true ),
            () => $assert.isEqual( 1, 2 ),
            () => $assert.notNull( javacast( "null", "" ) )
        ],
        heading = "Basic checks"
    )
} )
```

* * *

## New Matchers

### `toIncludeAll` / `toIncludeAny` / `toIncludeNone`

Assert that a string or array contains all, any, or none of the given needles with case-insensitive matching.

```javascript
expect( "hello world" ).toIncludeAll( [ "hello", "world" ] )
expect( "hello world" ).toIncludeAny( [ "hello", "foo" ] )
expect( "hello world" ).toIncludeNone( [ "foo", "bar" ] )
```

### `toBeTruthy` / `toBeFalsy`

Assert that a value is truthy (not false, `0`, empty string, or null) or falsy.

```javascript
expect( 42 ).toBeTruthy()
expect( "" ).toBeFalsy()
```

### `toHaveSize`

Alias for `toHaveLength()` — works on strings, arrays, structs, and queries.

```javascript
expect( "abc" ).toHaveSize( 3 )
expect( [ 1, 2 ] ).toHaveSize( 2 )
expect( { a : 1, b : 2 } ).toHaveSize( 2 )
```

### `toBeSameInstanceAs`

Assert two references point to the exact same object instance.

```javascript
var obj = { name : "test" }
expect( obj ).toBeSameInstanceAs( obj )
```

### `toThrowMatching`

Assert a function throws an exception that matches a predicate closure.

```javascript
expect( () => {
    throw( type = "FooException" )
} ).toThrowMatching( e => e.type == "FooException" )
```

* * *

## New Assertion BIFs

For xUnit-style testing, the following new `$assert` methods are available:

| Method | Description |
| --- | --- |
| `$assert.isTruthy( actual, message )` | Value is truthy |
| `$assert.isFalsy( actual, message )` | Value is falsy |
| `$assert.includesAll( target, needles, message )` | Target contains every needle |
| `$assert.includesAny( target, needles, message )` | Target contains at least one needle |
| `$assert.includesNone( target, needles, message )` | Target contains no needle |
| `$assert.all( executables, heading )` | Run all assertions, report every failure |

```javascript
$assert.isTruthy( "hello" )
$assert.isFalsy( 0 )
$assert.includesAll( "hello world", [ "hello", "world" ] )
$assert.includesAny( [ "a", "b" ], [ "b", "z" ] )
$assert.includesNone( "hello", [ "x", "y" ] )
```

* * *

## Set Expectations

TestBox now provides a comprehensive suite of set-related matchers for working with BoxLang `Set` objects. These matchers leverage the global `setOf()` function to create sets and provide powerful assertions for set operations.

### Creating Sets with `setOf()`

```javascript
var set1 = setOf( 1, 2, 3 )
var set2 = setOf( 3, 4, 5 )
var set3 = setOf( 1, 2, 3, 4, 5 )
var emptySet = setOf()
```

### `toBeASet()` / `notToBeASet()`

Assert that a value is (or is not) a Set object.

```javascript
expect( set1 ).toBeASet()
expect( [ 1, 2, 3 ] ).notToBeASet()
```

### `toEqualSet()` / `notToEqualSet()`

Assert that two sets contain the same elements, regardless of order.

```javascript
expect( setOf( 1, 2, 3 ) ).toEqualSet( setOf( 3, 2, 1 ) )
expect( setOf( 'a', 'b' ) ).toEqualSet( setOf( 'b', 'a' ) )
expect( setOf( 1, 'a', true ) ).toEqualSet( setOf( true, 'a', 1 ) )
```

### `toBeSubsetOf()` / `notToBeSubsetOf()`

Assert that all elements of the actual set are contained in the expected set.

```javascript
expect( setOf( 1, 2 ) ).toBeSubsetOf( setOf( 1, 2, 3, 4, 5 ) )
expect( setOf( 1, 2, 3, 4, 5 ) ).notToBeSubsetOf( setOf( 1, 2 ) )
```

### `toBeSupersetOf()` / `notToBeSupersetOf()`

Assert that the actual set contains all elements of the expected set.

```javascript
expect( setOf( 1, 2, 3, 4, 5 ) ).toBeSupersetOf( setOf( 1, 2, 3 ) )
expect( setOf( 1, 2, 3 ) ).notToBeSupersetOf( setOf( 1, 2, 3, 4, 5 ) )
```

### `toBeDisjointFrom()`

Assert that two sets share no common elements.

```javascript
expect( setOf( 1, 2 ) ).toBeDisjointFrom( setOf( 3, 4 ) )
```

### `toHaveUnion()` / `notToHaveUnion()`

Assert that the union of two sets equals an expected set.

```javascript
expect( setOf( 1, 2 ) ).toHaveUnion( setOf( 3, 4 ), setOf( 1, 2, 3, 4 ) )
```

### `toHaveIntersection()` / `notToHaveIntersection()`

Assert that the intersection of two sets equals an expected set.

```javascript
expect( setOf( 1, 2, 3 ) ).toHaveIntersection( setOf( 3, 4, 5 ), setOf( 3 ) )
```

### `toHaveDifference()` / `notToHaveDifference()`

Assert that the set difference (actual - expected) equals an expected result.

```javascript
expect( setOf( 1, 2, 3 ) ).toHaveDifference( setOf( 3, 4, 5 ), setOf( 1, 2 ) )
```

### `toHaveSymmetricDifference()` / `notToHaveSymmetricDifference()`

Assert that the symmetric difference (elements in either set but not both) equals an expected result.

```javascript
expect( setOf( 1, 2, 3 ) ).toHaveSymmetricDifference( setOf( 3, 4, 5 ), setOf( 1, 2, 4, 5 ) )
```

### Real-World Example: Menu Selection

```javascript
it( "validates menu selection", () => {
    var fruits = setOf( 'apple', 'banana', 'cherry' )
    var selected = setOf( 'apple', 'banana' )

    expect( selected ).toBeSubsetOf( fruits )
    expect( selected ).toHaveIntersection( fruits, setOf( 'apple', 'banana' ) )
} )
```

* * *

## Summary

| Feature | Type | Example |
| --- | --- | --- |
| `withContext()` | Expectation | `expect( v ).withContext( "label" ).toBe( x )` |
| `expectAny()` | Collection | `expectAny( arr ).toBeGT( 2 )` |
| `expectSome()` | Collection | `expectSome( arr, 2, 5 ).toBeGT( 2 )` |
| `expectNone()` | Collection | `expectNone( arr ).toBeEmpty()` |
| `assertAll()` | Grouped | `assertAll( closures, "heading" )` |
| `toBeTruthy()` | Matcher | `expect( v ).toBeTruthy()` |
| `toBeFalsy()` | Matcher | `expect( v ).toBeFalsy()` |
| `toBeSameInstanceAs()` | Matcher | `expect( a ).toBeSameInstanceAs( b )` |
| `toHaveSize()` | Matcher | `expect( v ).toHaveSize( 3 )` |
| `toThrowMatching()` | Matcher | `expect( fn ).toThrowMatching( p )` |
| `toIncludeAll()` | Matcher | `expect( v ).toIncludeAll( needles )` |
| `toIncludeAny()` | Matcher | `expect( v ).toIncludeAny( needles )` |
| `toIncludeNone()` | Matcher | `expect( v ).toIncludeNone( needles )` |
| `toBeASet()` / `nottoBeASet()` | Set | `expect( setOf( 1, 2 ) ).toBeASet()` |
| `toEqualSet()` / `notToEqualSet()` | Set | `expect( setOf( 1, 2 ) ).toEqualSet( setOf( 2, 1 ) )` |
| `toBeSubsetOf()` / `notToBeSubsetOf()` | Set | `expect( setOf( 1 ) ).toBeSubsetOf( setOf( 1, 2 ) )` |
| `toBeSupersetOf()` / `notToBeSupersetOf()` | Set | `expect( setOf( 1, 2 ) ).toBeSupersetOf( setOf( 1 ) )` |
| `toBeDisjointFrom()` | Set | `expect( setOf( 1 ) ).toBeDisjointFrom( setOf( 2 ) )` |
| `toHaveUnion()` / `notToHaveUnion()` | Set | `expect( setOf( 1 ) ).toHaveUnion( setOf( 2 ), setOf( 1, 2 ) )` |
| `toHaveIntersection()` / `notToHaveIntersection()` | Set | `expect( setOf( 1, 2 ) ).toHaveIntersection( setOf( 2, 3 ), setOf( 2 ) )` |
| `toHaveDifference()` / `notToHaveDifference()` | Set | `expect( setOf( 1, 2 ) ).toHaveDifference( setOf( 2 ), setOf( 1 ) )` |
| `toHaveSymmetricDifference()` / `notToHaveSymmetricDifference()` | Set | `expect( setOf( 1, 2 ) ).toHaveSymmetricDifference( setOf( 2, 3 ), setOf( 1, 3 ) )` |
