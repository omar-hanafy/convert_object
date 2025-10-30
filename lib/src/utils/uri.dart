/// Extension methods for validating and converting URI-like strings.
extension UriParsingX on String {
  /// Whether this string resembles a telephone number.
  bool get isValidPhoneNumber {
    final s = trim();
    final re = RegExp(r'^\+?[0-9\-\s\(\)]{3,}$');
    return re.hasMatch(s);
  }

  /// Whether this string is a simple email address.
  bool get isEmailAddress {
    final trimmed = trim();
    if (trimmed != this) return false;
    // Simple email pattern
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(trimmed);
  }

  /// Converts this string into a `tel:` URI.
  Uri get toPhoneUri {
    final digits = replaceAll(RegExp(r'[^0-9\+]'), '');
    return Uri(scheme: 'tel', path: digits);
  }

  /// Converts this string into a `mailto:` URI.
  Uri get toMailUri => Uri(scheme: 'mailto', path: trim());

  /// Parses this string into a [Uri].
  Uri get toUri => Uri.parse(this);
}
