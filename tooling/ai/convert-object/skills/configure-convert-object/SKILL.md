---
name: configure-convert-object
description: Use when changing app-wide or scoped parsing behavior of the convert_object Dart package - ConvertConfig, default locales or number/date formats, custom truthy/falsy boolean tokens (BoolOptions), URI scheme policies (UriOptions), registering custom types with TypeRegistry so Convert.toType<T> handles them, scoped overrides via runScopedConfig/ConvertConfig.overrides, or wiring the onException hook for logging/telemetry (Sentry, Crashlytics).
---

# Configure convert_object behavior

Nearly everything about parsing is runtime-configurable through
`ConvertConfig`. Do NOT write app-level wrapper parsers for things the config
already controls (bool tokens, locales, formats, custom types) - that is a
known failure mode.

## Effective config precedence

Per-call arguments > zone-scoped overrides (`runScopedConfig`) > global config
(`Convert.configure`/`updateConfig`) > built-in defaults.

Flag-like date options OR together: a call inherits `autoDetectFormat`,
`useCurrentLocale`, `utc` from `DateOptions` even when the call passes `false`
(passing `true` at the call site cannot be turned off by config, and vice
versa). Set flags at exactly one layer to stay predictable.

## Global configuration

```dart
// Replace (returns previous config - useful for tests):
final previous = Convert.configure(ConvertConfig(
  locale: 'de_DE',
  bools: const BoolOptions(
    truthy: {'true', '1', 'yes', 'oui', 'ja'},
    falsy: {'false', '0', 'no', 'non', 'nein'},
    // numericPositiveIsTrue: true (default) -> only n > 0 is true;
    // false -> any non-zero n is true
  ),
  dates: const DateOptions(autoDetectFormat: true, utc: true),
  numbers: const NumberOptions(defaultFormat: '#,##0.00', defaultLocale: 'de_DE'),
  uri: const UriOptions(defaultScheme: 'https', coerceBareDomainsToDefaultScheme: true),
));

// Incremental update (preferred inside app init):
Convert.updateConfig((c) => c.copyWith(
  dates: c.dates.copyWith(autoDetectFormat: true),
));
```

Defaults worth knowing: truthy `{'true','1','yes','y','on','ok','t'}`, falsy
`{'false','0','no','n','off','f'}` (case-insensitive, trimmed);
`NumberOptions.tryFormattedFirst: true`; `UriOptions.allowRelative: true`.

## Scoped configuration: use ConvertConfig.overrides

`runScopedConfig` merges overrides onto the current effective config inside a
Dart zone (async-safe within the callback's zone).

```dart
final total = Convert.runScopedConfig(
  ConvertConfig.overrides(locale: 'fr_FR'),
  () => Convert.toDouble('1 234,56', format: '#,##0.##'),
);
```

Critical: build scoped overrides with `ConvertConfig.overrides(...)`, NOT the
plain `ConvertConfig(...)` constructor. Only `overrides` records which fields
you explicitly set (including explicit clears via `clearLocale: true` /
`clearOnException: true`); a plain config passed to `runScopedConfig` only
applies fields that differ from defaults, so "reset to default" intents are
silently ignored.

## TypeRegistry: custom types for toType<T>

```dart
class Money {
  const Money(this.cents);
  final int cents;
  static Money parse(Object? o) => Money(Convert.toInt(o));
}

Convert.updateConfig((c) => c.copyWith(
  registry: c.registry.register<Money>(Money.parse),
));

final m = Convert.toType<Money>('42');        // Money(42)
final list = Convert.toList<Money>(raw);      // element routing uses toType
```

Rules:

- `register<T>` returns a NEW registry (immutable); always reassign via
  `copyWith`/`merge`. Registering the same `T` again replaces the parser.
- Parsers signal failure by THROWING (wrapped into `ConversionException`).
  A parser returning `null` is treated as "no answer" and falls through to
  built-ins/casting - do not use null returns for failures.
- If the input is already `T` the registry is skipped entirely.
- Registry only affects `toType`/`tryToType` (and collection element routing).
  It does not change `toInt`-style primitive methods.

## onException hook (telemetry)

```dart
Convert.updateConfig((c) => c.copyWith(
  onException: (e) => log.warning(e.toString(), e.error, e.stackTrace),
));
```

Firing semantics (verify assumptions against these before promising behavior):

- Fires only when a `ConversionException` is actually THROWN: strict `toX`
  without a rescuing `defaultValue`.
- Does NOT fire for `tryToX`/`tryGetX` (they never throw) nor when
  `defaultValue` rescued the call.
- Fires at most once per exception instance, even across rethrows; hook errors
  are swallowed. Do not put control flow in the hook.

## Where to configure

- Flutter/Dart app: once at startup (before first conversion), e.g. in `main()`.
- Tests: snapshot-restore to avoid leaks:

```dart
late ConvertConfig prev;
setUp(() => prev = Convert.configure(const ConvertConfig()));
tearDown(() => Convert.configure(prev));
```

- Libraries: never mutate global config from a library; use `runScopedConfig`
  around your own call trees instead.

## Verification

Run `dart analyze` plus a focused test proving the configured behavior (e.g.
`Convert.toBool('oui')` is true after BoolOptions change; a scoped block does
not leak: assert behavior returns to default after `runScopedConfig`).

## Failure handling

- Config seems ignored inside `Future`/`Stream` callbacks: confirm the async
  work is created INSIDE the `runScopedConfig` body (zone values follow the
  zone where the callback was created).
- Scoped override "not applied": you used plain `ConvertConfig(...)` instead of
  `ConvertConfig.overrides(...)`.
- `toType<Money>` throwing "Unsupported type": the registry with the parser is
  not in the EFFECTIVE config (global replaced later, or scope ended).
