/// Global test configuration helpers.
///
/// Usage in a test file:
///
///   import '../_setup/test_config.dart';
///
///   void main() {
///     configureTests(defaultLocale: 'en_US'); // optional
///     // ... your tests ...
///   }
///
/// This file intentionally does **not** define `main()`. You import it and call
/// `configureTests(...)` at the start of your test's `main()` to register
/// global `setUpAll` / `tearDownAll` hooks for that suite only.
/// This avoids hidden global state across unrelated suites.

import 'package:intl/intl.dart';
import 'package:test/test.dart';

typedef VoidCallback = void Function();

class _GlobalConfigState {
  String? originalLocale;
}

final _state = _GlobalConfigState();

/// Registers global setup/teardown for the *current* test suite.
///
/// If [defaultLocale] is provided, the suite will run with that Intl locale and
/// will restore the previous locale afterward. You can also pass optional
/// hooks in [beforeAll] / [afterAll] to run custom code exactly once.
void configureTests({
  String? defaultLocale,
  List<VoidCallback>? beforeAll,
  List<VoidCallback>? afterAll,
}) {
  setUpAll(() {
    // Capture current locale once per suite and optionally set a default.
    _state.originalLocale = Intl.getCurrentLocale();
    if (defaultLocale != null && defaultLocale.isNotEmpty) {
      Intl.defaultLocale = defaultLocale;
    }
    // Suite-level beforeAll hooks.
    for (final cb in beforeAll ?? const <VoidCallback>[]) {
      cb();
    }
  });

  tearDownAll(() {
    // Suite-level afterAll hooks.
    for (final cb in afterAll ?? const <VoidCallback>[]) {
      cb();
    }
    // Restore original locale.
    final prev = _state.originalLocale;
    if (prev != null && prev.isNotEmpty) {
      Intl.defaultLocale = prev;
    }
  });
}
