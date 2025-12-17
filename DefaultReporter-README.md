# TestBox DefaultReporter - Modern Testing IDE

## Overview

The **DefaultReporter** is a modern, sleek HTML reporter for TestBox that provides a Testing IDE experience with Alpine.js reactivity, Bootstrap 5 styling, and beautiful dark/light theming inspired by DocBox.

## Features

### 🎨 Modern UI/UX
- **Dark-First Theme** - Beautiful dark theme with BoxLang-inspired color palette
- **Light Theme Support** - Seamless toggle between dark and light modes
- **Responsive Design** - Works perfectly on desktop, tablet, and mobile
- **Smooth Animations** - Polished transitions and hover effects

### ⚡ SPA-Like Reactivity (Alpine.js)
- **Real-time Filtering** - Instant search and filter without page reloads
- **Expand/Collapse All** - One-click bundle expansion control
- **Status Filtering** - Click to filter by Passed, Failed, Error, or Skipped
- **Live Counters** - Dynamic update of visible bundles and specs

### 🔍 Advanced Filtering
- **Full-Text Search** - Search across bundles, suites, and specs
- **Status-Based Filtering** - Filter by test status
- **Combined Filters** - Search + status filtering works together
- **Real-time Results** - See counts update as you filter

### 🧪 Testing IDE Features
- **Stack Trace Visualization** - Beautiful, readable stack traces
- **Code Snippets** - Inline code preview from failures
- **Editor Integration** - Click to open files in your editor (VS Code, etc.)
- **Detailed Insights** - Expandable failure details, extended info, and debug data
- **Run Controls** - Run individual specs, suites, or entire bundles

### 📊 Enhanced Visualization
- **Bundle Cards** - Clear separation of test bundles
- **Nested Suites** - Visual hierarchy for suite nesting
- **Status Icons** - Color-coded icons for quick status identification
- **Duration Tracking** - Execution time for bundles, suites, and specs
- **Summary Dashboard** - At-a-glance test statistics

### 🎯 Developer Experience
- **Keyboard Shortcuts**:
  - `Ctrl/Cmd + K` - Focus search
  - `Ctrl/Cmd + E` - Expand/collapse all
- **Theme Persistence** - Remembers your theme preference
- **Print-Friendly** - Optimized print styles for reports

## Files Created

### 1. DefaultReporter.cfc
**Location:** `/system/reports/DefaultReporter.cfc`

The main reporter component that extends `BaseReporter` and orchestrates the rendering of test results.

```javascript
component extends="BaseReporter" {
    function getName() {
        return "Default";
    }

    any function runReport(
        required testbox.system.TestResult results,
        required testbox.system.TestBox testbox,
        struct options = {},
        boolean justReturn = false
    ) {
        // Renders the modern testing IDE interface
    }
}
```

### 2. default.cfm
**Location:** `/system/reports/assets/default.cfm`

The main template file that renders the HTML structure with Alpine.js interactivity.

**Key Sections:**
- Top Navigation Bar (theme toggle, run controls)
- Global Stats Card (bundles, suites, specs counts)
- Status Summary (filterable buttons)
- Code Coverage Integration
- Search/Filter Bar
- Bundle Cards (expandable/collapsible)
- Suite Items (nested support)
- Spec Items (with stack traces)
- Debug Panel (debug() output)

**Alpine.js App:**
```javascript
function testBoxApp() {
    return {
        theme: 'dark',
        searchText: '',
        statusFilter: '',
        expandAll: true,
        visibleBundleCount: 0,
        visibleSpecCount: 0,

        init() { /* Setup theme & keyboard shortcuts */ },
        toggleTheme() { /* Toggle dark/light */ },
        isBundleVisible(bundleId) { /* Filter logic */ },
        filterTests() { /* Update counters */ }
    }
}
```

### 3. default.css
**Location:** `/system/reports/assets/css/default.css`

Comprehensive stylesheet with dark/light theme support and BoxLang-inspired colors.

**CSS Custom Properties:**
```css
:root {
    /* BoxLang Brand Colors */
    --boxlang-green: #00D991;
    --boxlang-teal: #00C2AD;
    --boxlang-dark-bg: #0A1F1F;

    /* Status Colors */
    --status-passed: #28a745;
    --status-failed: #ffc107;
    --status-error: #dc3545;
    --status-skipped: #6c757d;
}

[data-theme="dark"] {
    /* Dark theme overrides */
}
```

**Key Style Components:**
- Top Navigation
- Stats Card & Boxes
- Status Summary Buttons
- Filter Bar
- Bundle Cards
- Suite Items
- Spec Items
- Stack Traces & Code Snippets
- Debug Panel
- Responsive Design (mobile-first)
- Print Styles

## Usage

### Basic Usage

Update your `runner.cfm`:

```cfml
<cfparam name="url.reporter" default="default">
```

Or specify via URL:
```
/tests/runner.cfm?reporter=default
```

### Filtering Tests

**By Status:**
Click the status buttons (Passed, Failed, Errors, Skipped) to filter.

**By Search:**
Type in the search box to filter bundles/specs by name.

**Combined:**
Use both search and status filtering together.

### Running Tests

- **Run All**: Click "Run All" button in top nav
- **Run Bundle**: Click play icon on bundle header
- **Run Suite**: Click play icon on suite header
- **Run Spec**: Click play icon on spec item

### Viewing Failures

1. Failed/Error specs show preview automatically
2. Click the code icon to expand full stack trace
3. Click file:line links to open in your editor

### Debug Output

Debug data (from `debug()` calls) appears in collapsible Debug Panel at bottom of each bundle.

## Theme Customization

The reporter uses CSS custom properties for easy customization:

```css
:root {
    --primary-color: #00D991;    /* Your primary color */
    --bg-primary: #ffffff;       /* Main background */
    --text-primary: #212529;     /* Main text color */
}
```

Dark theme automatically inherits and adjusts these values.

## Configuration Options

The reporter respects all standard TestBox URL parameters:

- `reporter=default` - Use this reporter
- `directory=tests.specs` - Test directory
- `bundles=my.bundle` - Specific bundles
- `testSuites=MySuite` - Specific suites
- `testSpecs=mySpec` - Specific specs
- `labels=unit,integration` - Filter by labels
- `excludes=slow` - Exclude labels
- `editor=vscode` - Editor for file links
- `coverageEnabled=true` - Enable code coverage

## Browser Support

- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Mobile browsers (iOS Safari, Chrome Mobile)

## Dependencies

### External CDN Resources

- **Bootstrap 5.3.2** - Modern UI framework
- **Font Awesome 6.5.1** - Icon library
- **Alpine.js 3.13.3** - Reactive JavaScript framework

All dependencies are loaded from CDN for zero installation overhead.

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + K` | Focus search input |
| `Ctrl/Cmd + E` | Toggle expand/collapse all |

## Performance

- **Lazy Rendering**: Only visible items are fully rendered
- **Efficient Filtering**: Alpine.js handles reactivity
- **Optimized Animations**: CSS transitions, no JavaScript animations
- **Collapsible Sections**: Reduce DOM complexity

## Accessibility

- **Keyboard Navigation**: Full keyboard support
- **ARIA Labels**: Proper labeling for screen readers
- **Color Contrast**: WCAG AA compliant colors
- **Focus Indicators**: Clear focus states

## Migration from SimpleReporter

The DefaultReporter is a drop-in replacement for SimpleReporter:

```cfml
<!-- Before -->
<cfparam name="url.reporter" default="simple">

<!-- After -->
<cfparam name="url.reporter" default="default">
```

All features from SimpleReporter are preserved and enhanced.

## Future Enhancements

Potential additions:

- **Diff View**: Side-by-side comparison for assertions
- **Test History**: Track test runs over time
- **Performance Graphs**: Visualize execution times
- **Export Options**: PDF, JSON, XML export
- **Test Recording**: Record and replay test sessions
- **AI Insights**: Automatic failure analysis

## Contributing

The reporter is built with modern web standards and best practices:

- **Alpine.js** for reactivity (lightweight Vue alternative)
- **Bootstrap 5** for UI components
- **CSS Custom Properties** for theming
- **Mobile-First** responsive design
- **Print-Optimized** for documentation

## Credits

- **Theme Design**: Inspired by DocBox API documentation
- **Color Palette**: BoxLang brand colors
- **Icons**: Font Awesome 6
- **Framework**: TestBox by Ortus Solutions

---

**Built with ❤️ for the CFML/BoxLang community**

*TestBox - Professional BDD/TDD Testing Framework*
