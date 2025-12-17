# Assertion Class Improvements for JUnit Developers

Based on review of `system/Assertion.cfc` compared to JUnit 5 standards.

## High Priority - Missing Core Assertions

### 1. **assertAll() - Multiple Assertions**
Execute all assertions and report ALL failures, not just the first one.

```javascript
function assertAll( required array assertions, message = "" ){
    var failures = [];
    
    for( var assertion in arguments.assertions ){
        try {
            assertion();
        } catch( TestBox.AssertionFailed e ){
            failures.append( e );
        }
    }
    
    if( failures.len() ){
        var failureMessage = "Multiple assertions failed (#failures.len()#):" & chr(10);
        failures.each( function(e, index){
            failureMessage &= "#index#. #e.message#" & chr(10);
        });
        fail( failureMessage );
    }
    
    return this;
}

// Usage:
$assert.assertAll([
    () => $assert.isEqual("John", user.firstName),
    () => $assert.isEqual("Doe", user.lastName),
    () => $assert.isTrue(user.isActive)
]);
```

### 2. **assertTimeout() - Time-bounded Execution**
Assert that code completes within a specified duration.

```javascript
function assertTimeout(
    required numeric timeoutMs,
    required any target,
    message = ""
){
    var startTime = getTickCount();
    var result = "";
    
    try {
        result = arguments.target();
    } catch( any e ){
        rethrow;
    }
    
    var duration = getTickCount() - startTime;
    
    if( duration > arguments.timeoutMs ){
        arguments.message = len( arguments.message ) 
            ? arguments.message 
            : "Execution exceeded timeout of #arguments.timeoutMs#ms (took #duration#ms)";
        fail( arguments.message );
    }
    
    return this;
}

// Usage:
$assert.assertTimeout( 1000, () => {
    return mySlowOperation();
});
```

### 3. **assertBlank() / assertNotBlank()**
Specifically for whitespace-only string checking.

```javascript
function isBlank( required string actual, message = "" ){
    arguments.message = len( arguments.message ) 
        ? arguments.message 
        : "Expected string to be blank but was [#arguments.actual#]";
    
    if( !len( trim( arguments.actual ) ) ){
        return this;
    }
    
    fail( arguments.message );
}

function isNotBlank( required string actual, message = "" ){
    arguments.message = len( arguments.message ) 
        ? arguments.message 
        : "Expected string to NOT be blank";
    
    if( len( trim( arguments.actual ) ) ){
        return this;
    }
    
    fail( arguments.message );
}
```

### 4. **File/Directory Existence**
Common in integration tests.

```javascript
function fileExists( required string path, message = "" ){
    arguments.message = len( arguments.message )
        ? arguments.message
        : "File does not exist: #arguments.path#";
    
    if( fileExists( arguments.path ) ){
        return this;
    }
    
    fail( arguments.message );
}

function directoryExists( required string path, message = "" ){
    arguments.message = len( arguments.message )
        ? arguments.message
        : "Directory does not exist: #arguments.path#";
    
    if( directoryExists( arguments.path ) ){
        return this;
    }
    
    fail( arguments.message );
}
```

## Medium Priority - Enhanced Functionality

### 5. **throwsExactly() - Exact Exception Type**
Unlike `throws()` which accepts subclasses, this requires exact match.

```javascript
function throwsExactly(
    required any target,
    required string exactType,
    regex   = ".*",
    message = ""
){
    try {
        arguments.target();
        fail( "Expected exception of type [#arguments.exactType#] to be thrown" );
    } catch( any e ){
        if( e.type NEQ arguments.exactType ){
            arguments.message = len( arguments.message )
                ? arguments.message
                : "Expected exact type [#arguments.exactType#] but got [#e.type#]";
            fail( arguments.message );
        }
        
        // Check regex if provided
        if( arguments.regex NEQ ".*" && !arrayLen( reMatchNoCase( arguments.regex, e.message ) ) ){
            fail( "Exception message [#e.message#] did not match regex [#arguments.regex#]" );
        }
    }
    
    return this;
}
```

### 6. **containsAll() / containsAny() for Arrays**

```javascript
function containsAll( 
    required array target, 
    required array expected,
    message = ""
){
    var missing = expected.filter( (item) => !target.contains(item) );
    
    if( missing.len() ){
        arguments.message = len( arguments.message )
            ? arguments.message
            : "Array is missing elements: #missing.toString()#";
        fail( arguments.message );
    }
    
    return this;
}

function containsAny(
    required array target,
    required array expected, 
    message = ""
){
    var found = expected.filter( (item) => target.contains(item) );
    
    if( !found.len() ){
        arguments.message = len( arguments.message )
            ? arguments.message
            : "Array contains none of the expected elements: #expected.toString()#";
        fail( arguments.message );
    }
    
    return this;
}
```

### 7. **hasSize() - Size/Length Alias**
More intuitive name than `lengthOf()` for collection testing.

```javascript
function hasSize( required any target, required numeric expectedSize, message = "" ){
    return lengthOf( 
        target = arguments.target, 
        length = arguments.expectedSize, 
        message = arguments.message 
    );
}
```

### 8. **isBetweenInclusive() / isBetweenExclusive()**
Current `between()` is ambiguous about inclusivity.

```javascript
// Current between() should be renamed or clarified
function isBetweenInclusive(
    required any actual,
    required any min,
    required any max,
    message = ""
){
    // For dates: actual >= min && actual <= max
    // For numbers: actual >= min && actual <= max
}

function isBetweenExclusive(
    required any actual,
    required any min,
    required any max,
    message = ""
){
    // For dates: actual > min && actual < max  
    // For numbers: actual > min && actual < max
}
```

## Low Priority - Nice to Have

### 9. **Fluent Comparison Chains**
```javascript
function isGreaterThan( required any actual, required any expected, message = "" ){
    return isGT( argumentCollection = arguments );
}

function isLessThan( required any actual, required any expected, message = "" ){
    return isLT( argumentCollection = arguments );
}

function isGreaterThanOrEqualTo( required any actual, required any expected, message = "" ){
    return isGTE( argumentCollection = arguments );
}

function isLessThanOrEqualTo( required any actual, required any expected, message = "" ){
    return isLTE( argumentCollection = arguments );
}
```

### 10. **Array Order Matters**
```javascript
function isEqualInOrder(
    required array expected,
    required array actual,
    message = ""
){
    // Unlike isEqual() which might not care about order in some contexts
    // This explicitly validates element-by-element in sequence
}
```

## Documentation Improvements

### Method Naming Clarity
Some methods could have clearer names or aliases for JUnit developers:

| Current Method | JUnit Equivalent | Suggested Alias |
|---------------|------------------|-----------------|
| `null()` | `assertNull()` | Already good, maybe add `isNull()` |
| `notNull()` | `assertNotNull()` | Already good, maybe add `isNotNull()` |
| `typeOf()` | `assertInstanceOf()` (sort of) | Consider `hasType()` |
| `lengthOf()` | `assertArrayEquals().length` | Add `hasSize()` |
| `isEmpty()` | `assertTrue(x.isEmpty())` | Good as-is |
| `isGT/isLT` | Custom matchers | Add `isGreaterThan()` aliases |

## Summary

**Must Have:**
1. `assertAll()` - Critical for better test feedback
2. `assertTimeout()` - Common need in async/performance tests
3. `isBlank()` / `isNotBlank()` - Very common string checks
4. `fileExists()` / `directoryExists()` - Integration testing

**Should Have:**
5. `throwsExactly()` - Better exception testing
6. `containsAll()` / `containsAny()` - Better array assertions
7. `hasSize()` - More intuitive naming
8. Better `between()` variants with clear inclusivity

**Nice to Have:**
9. Fluent method name aliases
10. Explicit order-sensitive array equality

## Additional Notes

### Strengths Already Present
- ✅ `isSameInstance()` / `isNotSameInstance()` - Good reference equality
- ✅ `throws()` with regex - More flexible than basic JUnit
- ✅ String start/end checking with case variants
- ✅ Deep key checking for nested structures
- ✅ Comprehensive includes/contains checking
- ✅ Good fluent chaining with `return this`

### Consider for Future
- Hamcrest-style matcher integration
- Custom assertion messages via lambdas/closures
- Better diff output for complex object comparisons
- Performance benchmark assertions
