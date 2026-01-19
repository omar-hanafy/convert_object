import 'dart:convert';

/// Adds JSON decoding helpers to [String].
///
/// Used internally by conversion methods to automatically parse JSON strings
/// when working with collection types. For example, `'[1,2,3]'` passed to
/// `Convert.toList` is decoded before element conversion.
extension TextJsonX on String {
  /// Attempts to decode this string as JSON, returning the original string on failure.
  ///
  /// Useful for lenient parsing where the input might or might not be JSON.
  /// Empty strings (after trimming) return the original value unchanged.
  ///
  /// Returns [Map], [List], or primitive types on success; returns `this` on failure.
  Object? tryDecode() {
    final s = trim();
    if (s.isEmpty) return this;
    try {
      return jsonDecode(s);
    } catch (_) {
      return this;
    }
  }

  /// Decodes this string as JSON, throwing [FormatException] if parsing fails.
  ///
  /// Use [tryDecode] for lenient parsing that does not throw.
  dynamic decode() => jsonDecode(this);
}
