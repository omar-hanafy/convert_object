---
name: upgrade-convert-object
description: Use when bumping the convert_object Dart package version in a project or auditing an upgrade's impact - moving from a 1.0.0-dev beta to stable 1.x, from 1.0.x to 1.1.x, reviewing behavior changes like the alternativeKeys first-non-null fallback, tryGetRaw availability, runScopedConfig override semantics, ConversionException stack traces/toString changes, or answering "is it safe to upgrade convert_object".
---

# Upgrade convert_object across versions

Version-aware audit. Determine the CURRENT resolved version first, apply only
the hops that cross it, and verify with the project's own tests.

## Step 1: Detect versions

```bash
grep -n "convert_object" pubspec.yaml          # declared constraint
grep -A2 "  convert_object:" pubspec.lock      # resolved version
```

Also note whether convert_object arrives transitively via
`dart_helper_utils >= 6` - if so, upgrade DHU instead and the same hop
checklists apply to the re-exported API.

If the resolved version is already the target: report "no migration needed"
and stop (do not invent work).

## Hop A: 1.0.0-dev.x (beta) -> any stable 1.x

Behavioral changes to audit (each with how to find affected code):

1. Stack traces preserved: `ConversionException` now rethrows with the
   ORIGINAL trace. Impact: error-reporter groupings change (Sentry issues may
   re-key). Nothing to change in code; warn the user.
2. `toString()` became concise; full context moved to `fullReport()`.
   Find: `grep -rn "on ConversionException" lib/ test/` and check any logging
   that expected verbose text.
3. `tryToType<T>()` returns null for unsupported types instead of throwing.
   Find: `grep -rn "tryToType\|tryConvertToType\|tryTo<" lib/` - remove now
   dead try/catch around it.
4. `Converter.tryTo`/`toOr` only catch `ConversionException`; other thrown
   errors now SURFACE. Find: `grep -rn "\.tryTo<\|\.toOr" lib/` and check
   custom `withConverter` closures that throw non-conversion errors.
5. `runScopedConfig` no longer treats default-valued option objects as
   overrides - scoped overrides must use `ConvertConfig.overrides(...)`
   (with `clearLocale`/`clearOnException` for explicit clears).
   Find: `grep -rn "runScopedConfig\|runScoped(" lib/ test/`.
6. Core converters no longer log internally - wire
   `ConvertConfig.onException` if the app relied on implicit logs.

## Hop B: >= 1.0.0 and < 1.1.0 -> 1.1.x

1. BEHAVIOR CHANGE: `alternativeKeys` (every typed map getter) now selects
   the first NON-NULL value across primary + alternative keys. Previously the
   first key that merely EXISTED won, so a present-but-null alternative key
   short-circuited to null/default.
   - Find: `grep -rn "alternativeKeys" lib/ test/`
   - Audit question per site: "does this code rely on getting null/default
     when an earlier key exists with a null value, even though a later key
     has data?" If yes (rare), replace with explicit `containsKey` logic.
   - Most sites silently IMPROVE (more fallbacks found) - still note them in
     the report.
2. New API available: `Map?.tryGetRaw(key, alternativeKeys: ...)` for
   polymorphic fields - suggest replacing hand-rolled
   `map[k] ?? map[alt]` chains where conversion was deliberately avoided.
3. Constraint: bump pubspec to `convert_object: ^1.1.0` (SDK needs
   `^3.10.0`).

## Patch releases (1.1.0 -> 1.1.x)

Tooling/docs only unless the CHANGELOG says otherwise - read it:
https://pub.dev/packages/convert_object/changelog. No code audit needed when
only patch digits change.

## Step 2: Execute

1. Update the pubspec constraint; `dart pub get` (or `dart pub upgrade convert_object`).
2. Work through ONLY the hops crossed, in order (A then B when coming from a
   dev build).
3. `dart analyze` and run the full test suite; compare failures against the
   pre-upgrade baseline (record it first).

## Failure handling

- Solver conflict: check the SDK constraint (`^3.10.0` for 1.1.x) and
  `dart_helper_utils` pins (`>= 6.0.2` requires `convert_object ^1.1.0`).
- New test failures around map fallbacks after the upgrade point directly at
  Hop B item 1 - inspect those call sites before touching anything else.
- If behavior does not match this checklist, trust the package CHANGELOG.md
  for the exact installed version over memory.

## Future versions

If the installed or target version is NEWER than 1.1.x, this skill may
predate it: read the package CHANGELOG for entries above 1.1.0 and treat any
"behavior change" bullet the way Hop B is handled here.
