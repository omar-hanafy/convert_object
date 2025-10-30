/// Custom matchers used across tests.
///
/// Import in your tests:
///
///   import '../_helpers/matchers.dart';
///
/// Examples:
///
///   expect(() => ConvertObject.toText(null), throwsConversionException());
///   expect(
///     () => ConvertObject.toText({'a':1}, mapKey: 'b'),
///     throwsConversionException(contextIncludes: {'method': 'toText'}),
///   );
///
///   expect(uri, equalsUri(Uri.parse('mailto:hello@example.com')));
///
///   expect(dt, sameInstantAs(expectedUtc));
///   expect(dt, closeToDateTime(expectedLocal, const Duration(seconds: 1)));
///
///   expect(result, isSuccessResult());
///   expect(result, isFailureResult());

import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

/// Matches a [ConversionException] with optional message/context assertions.
Matcher throwsConversionException({
  String? messageContains,
  Map<String, dynamic>? contextIncludes,
  String? errorType, // matches e.errorType
}) {
  return throwsA(
    predicate((e) {
      if (e is! ConversionException) return false;

      if (messageContains != null &&
          !e.toString().toLowerCase().contains(messageContains.toLowerCase())) {
        return false;
      }

      if (errorType != null && e.errorType != errorType) {
        return false;
      }

      if (contextIncludes != null) {
        for (final entry in contextIncludes.entries) {
          if (!e.context.containsKey(entry.key)) return false;
          final actual = e.context[entry.key];
          // Allow string/stringable comparison convenience.
          final expected = entry.value;
          if (expected is String && actual is! String) {
            if (actual?.toString() != expected) return false;
          } else if (actual != expected) {
            return false;
          }
        }
      }
      return true;
    }, 'ConversionException matching expected criteria'),
  );
}

/// Compares two URIs by value.
Matcher equalsUri(Uri expected) => predicate(
    (actual) => actual is Uri && actual == expected, 'equals $expected');

/// DateTime matcher that compares instants in time (ignores time zone).
Matcher sameInstantAs(DateTime expected) => predicate(
      (actual) =>
          actual is DateTime &&
          actual.toUtc().millisecondsSinceEpoch ==
              expected.toUtc().millisecondsSinceEpoch,
      'represents the same instant as $expected',
    );

/// DateTime matcher that allows a [tolerance].
Matcher closeToDateTime(DateTime expected, Duration tolerance) => predicate(
      (actual) {
        if (actual is! DateTime) return false;
        final diff = (actual.toUtc().difference(expected.toUtc())).abs();
        return diff <= tolerance;
      },
      'within ±$tolerance of $expected',
    );

/// Matches a successful [ConversionResult].
Matcher isSuccessResult<T>() => predicate(
      (actual) => actual is ConversionResult<T> && actual.isSuccess,
      'ConversionResult.isSuccess == true',
    );

/// Matches a failed [ConversionResult].
Matcher isFailureResult<T>() => predicate(
      (actual) => actual is ConversionResult<T> && actual.isFailure,
      'ConversionResult.isFailure == true',
    );
