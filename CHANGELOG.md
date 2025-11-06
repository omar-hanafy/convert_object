## 1.0.0-dev.3

- Unified string conversion naming: `Convert.toStringValue` / `Convert.tryToStringValue`, `convertToString`, and `Converter.toStringValue()` with matching `getString`/`tryGetString` collection helpers.
- Shortened the facade name to `Convert` and refreshed top-level exports, examples, and docs to reflect the new API.
- Updated enum utilities with `EnumParsers.fromString` and refreshed developer README assets for LLM consumption.

## 1.0.0-dev.2

- Added documentation across all public APIs, including facade helpers, utilities, and extensions.
- Tightened analyzer rules to enforce package imports and doc coverage, achieving a clean `flutter analyze` run.

## 1.0.0-dev.1

**First stable release of `convert_object`** — a comprehensive, null‑safe type‑conversion toolkit for Dart & Flutter with a fluent API, static helpers, safe `try*` variants, robust Date/Number/URI handling, collections, enums, and developer‑friendly diagnostics.
