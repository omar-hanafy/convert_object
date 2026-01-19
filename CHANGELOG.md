## 1.0.4

- Consolidate 1.0.0 changelog into organized sections for clarity.
- Update example with improved API usage demonstration.
- Fix markdown table formatting in test documentation.

## 1.0.3

- Align Converter fluent shortcuts with Convert optional arguments, including mapKey, listIndex, defaultValue, and formatting flags.
- Add Converter enum helpers and a named Converter.string to expose full string options.
- Add top level convertToEnum and tryConvertToEnum helpers.
- Allow enum extensions to forward debugInfo without losing key or index context.

## 1.0.2

- Add Kotlin-style scope helpers: `also`, `takeIf`, and `takeUnless`.

## 1.0.1

- Add Roman numeral helpers and conversions.
- Align SDK constraint to ^3.10.0 and update dev dependencies.

## 1.0.0

**Initial stable release** - A comprehensive, null-safe type-conversion toolkit for Dart & Flutter.

### Core Features
- Fluent `Convert` facade with static helpers and safe `try*` variants for all conversions.
- Full primitive conversions: int, double, num, bool, String, DateTime, Duration, Uri.
- Collection helpers: `getInt`, `getString`, `getList`, `getMap`, and more with safe defaults.
- Enum utilities with `EnumParsers.fromString` and extension-based parsing.
- `Converter` wrapper for chained, null-safe access into nested maps and lists.

### Configuration
- `ConvertConfig` for global defaults: number/date formats, locales, boolean literals, URI policies.
- Custom `TypeRegistry` for pluggable type parsers via `Convert.toType<T>`.
- Scoped overrides with `ConvertConfig.overrides(...)` and `runScopedConfig`.
- Exception hooks (`onException`) for centralized error handling.

### JSON Toolkit
- `jsonSafe` and `JsonOptions` for normalizing Dart objects to JSON-compatible maps.
- Strategies for enums, dates, durations, and binary data (base64 encoding).
- Options for dropping nulls, sorting keys, and cycle detection.

### Error Handling
- `ConversionException` with preserved stack traces (Sentry-friendly).
- Concise `toString()` and JSON-safe `fullReport()` for diagnostics.

### Extras
- Kotlin-style scope helpers: `also`, `takeIf`, `takeUnless`.
- Roman numeral conversions.
- DateFormat/NumberFormat caching for reduced allocations.
