/// Common matchers + helpers for the convert_object test suite.
///
/// These matchers are intentionally lightweight and focused on readable failure
/// output.
library;

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

/// Matches a [ConversionException] and optionally validates common context fields.
Matcher isConversionException({
  String? method,
  String? targetType,
  Pattern? errorContains,
  bool requireContext = true,
}) {
  return predicate(
    (e) {
      if (e is! ConversionException) return false;

      if (requireContext && e.context.isEmpty) return false;

      if (method != null) {
        final m = e.context['method']?.toString();
        if (m != method) return false;
      }

      if (targetType != null) {
        final t = e.context['targetType']?.toString();
        if (t != targetType) return false;
      }

      if (errorContains != null) {
        final msg = e.error?.toString() ?? '';
        if (!msg.contains(errorContains)) return false;
      }

      return true;
    },
    'ConversionException(method: $method, targetType: $targetType, '
    'errorContains: $errorContains)',
  );
}

/// Convenience matcher for `expect(() => ..., throwsA(...))`.
Matcher throwsConversionException({
  String? method,
  String? targetType,
  Pattern? errorContains,
}) {
  return throwsA(
    isConversionException(
      method: method,
      targetType: targetType,
      errorContains: errorContains,
    ),
  );
}

/// Matches a [DateTime] that is UTC.
Matcher get isUtcDateTime => predicate(
      (v) => v is DateTime && v.isUtc,
      'a UTC DateTime',
    );

/// Matches a [DateTime] that represents the same instant as [expected].
/// Compares microseconds since epoch in UTC for deterministic results.
Matcher sameInstantAs(DateTime expected) {
  final expectedMicros = expected.toUtc().microsecondsSinceEpoch;
  return predicate(
    (v) {
      if (v is! DateTime) return false;
      return v.toUtc().microsecondsSinceEpoch == expectedMicros;
    },
    'same instant as ${expected.toUtc().toIso8601String()}',
  );
}

/// Matches a [DateTime] within [tolerance] of [expected], comparing UTC instants.
Matcher withinInstantOf(
  DateTime expected, {
  Duration tolerance = const Duration(seconds: 1),
}) {
  final expectedMicros = expected.toUtc().microsecondsSinceEpoch;
  final tol = tolerance.inMicroseconds;
  return predicate(
    (v) {
      if (v is! DateTime) return false;
      final actualMicros = v.toUtc().microsecondsSinceEpoch;
      return (actualMicros - expectedMicros).abs() <= tol;
    },
    'within ${tolerance.inMilliseconds}ms of '
    '${expected.toUtc().toIso8601String()}',
  );
}

/// Matches a [Uri] by string representation.
Matcher uriEquals(String expected) {
  return predicate(
    (v) => v is Uri && v.toString() == expected,
    'Uri("$expected")',
  );
}

/// Matches a Map containing all provided key/value pairs.
Matcher mapContainsAll(Map<String, Object?> expectedEntries) {
  return predicate(
    (v) {
      if (v is! Map) return false;
      for (final e in expectedEntries.entries) {
        if (!v.containsKey(e.key)) return false;
        if (v[e.key] != e.value) return false;
      }
      return true;
    },
    'map contains all: $expectedEntries',
  );
}