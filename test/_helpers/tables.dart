/// Table-driven test helpers.
///
/// Usage:
///   ```dart
///   tableTest<String, String>(
///     'toText basics',
///     [
///       Case('string passthrough', 'x', 'x'),
///       Case('number -> text',  5,   '5'),
///     ],
///     (input) => ConvertObject.toText(input),
///   );
///   ```
/// For async functions, use `tableTestAsync`.
///
/// You can also supply a custom equality via [equals] (e.g., deep/approx).
library;

import 'package:test/test.dart';

class Case<I, O> {
  const Case(this.name, this.input, this.expected);
  final String name;
  final I input;
  final O expected;
}

void tableTest<I, O>(
  String groupName,
  List<Case<I, O>> cases,
  O Function(I) run, {
  bool Function(O a, O b)? equals,
}) {
  group(groupName, () {
    for (final c in cases) {
      test(c.name, () {
        final out = run(c.input);
        if (equals != null) {
          expect(equals(out, c.expected), isTrue,
              reason: 'Expected: ${c.expected}\nActual:   $out');
        } else {
          expect(out, equalsDynamic(c.expected));
        }
      });
    }
  });
}

/// Async variant of [tableTest] where [run] returns a `Future<O>`.
void tableTestAsync<I, O>(
  String groupName,
  List<Case<I, O>> cases,
  Future<O> Function(I) run, {
  bool Function(O a, O b)? equals,
  Timeout? timeout,
}) {
  group(groupName, () {
    for (final c in cases) {
      test(c.name, () async {
        final out = await run(c.input);
        if (equals != null) {
          expect(equals(out, c.expected), isTrue,
              reason: 'Expected: ${c.expected}\nActual:   $out');
        } else {
          expect(out, equalsDynamic(c.expected));
        }
      }, timeout: timeout);
    }
  });
}

/// A lenient equals that falls back to regular `equals` but treats
/// collections/maps in a human-friendly way.
Matcher equalsDynamic(Object? expected) {
  if (expected is Iterable) return equals(expected);
  if (expected is Map) return equals(expected);
  return equals(expected);
}
