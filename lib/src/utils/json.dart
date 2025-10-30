import 'dart:convert';

/// Adds JSON decoding helpers to [String].
extension TextJsonX on String {
  /// Tries to decode JSON; on failure, returns the original text.
  Object? tryDecode() {
    final s = trim();
    if (s.isEmpty) return this;
    try {
      return jsonDecode(s);
    } catch (_) {
      return this;
    }
  }

  /// Tries to decode JSON; on failure, returns the original text.
  dynamic decode() => jsonDecode(this);
}
