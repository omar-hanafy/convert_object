## 1.0.0-dev.7

- Release test for publish-on-release automation.

## 1.0.0-dev.6

- Release test for tag-driven publishing via PAT tag push (Trusted Publisher OIDC).

## 1.0.0-dev.5

- Maintenance release: publish automation now tags/releases on version bumps for main/dev, with manual publish dispatch readiness.

## 1.0.0-dev.4

- Added full configuration controls on the `Convert` facade (`config`, `configure`, `updateConfig`, `runScopedConfig`) so apps can inspect, replace, or temporarily override defaults per zone.
- Wired every primitive conversion through `ConvertConfig`: numeric/date helpers now honor default formats/locales with smart formatted↔plain fallbacks, boolean parsing respects custom truthy/falsy sets, URI parsing enforces default-scheme/relative policies, custom `TypeRegistry` parsers participate in `Convert.toType`/`tryToType`, and `onException` hooks fire before any `ConversionException` surfaces.
- Introduced a comprehensive JSON-normalization toolkit (`jsonSafe`, `JsonOptions`, `.toJsonMap/.toJsonString/.toJsonList/.toJsonSafe`) with enum/date/duration strategies, binary→base64 encoding, set→list coercion, drop-null & sort-keys toggles, toEncodable hooks, optional cycle detection, and updated exceptions to use the new pretty printers.
- Added a comprehensive test suite covering configuration scoping, registry routing, conversions, and exception behavior.
- Retuned `analysis_options.yaml` for pub-friendly hygiene (package imports, secure URLs, doc coverage) while quieting noisy stylistic rules.

## 1.0.0-dev.3

- Added `ConvertConfig` global configuration with default number/date formats, boolean literals, URI policy, custom type registry, and exception hooks (including scoped overrides).
- Unified string conversion naming: `Convert.string` / `Convert.tryToString`, `convertToString`, and `Converter.toString()` with matching `getString`/`tryGetString` collection helpers.
- Shortened the facade name to `Convert` and refreshed top-level exports, examples, and docs to reflect the new API.
- Updated enum utilities with `EnumParsers.fromString` and refreshed developer README assets for LLM consumption.

## 1.0.0-dev.2

- Added documentation across all public APIs, including facade helpers, utilities, and extensions.
- Tightened analyzer rules to enforce package imports and doc coverage, achieving a clean `flutter analyze` run.

## 1.0.0-dev.1

**First stable release of `convert_object`** — a comprehensive, null‑safe type‑conversion toolkit for Dart & Flutter with a fluent API, static helpers, safe `try*` variants, robust Date/Number/URI handling, collections, enums, and developer‑friendly diagnostics.
