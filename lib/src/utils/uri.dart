/// Extension methods for validating and converting URI-like strings.
///
/// Used internally by `Convert.toUri` for smart URI coercion. These methods
/// detect phone numbers and email addresses and wrap them in appropriate
/// URI schemes (`tel:`, `mailto:`).
///
/// See also: [UriOptions] for configuring URI parsing behavior.
extension UriParsingX on String {
  /// Returns `true` if this string resembles a telephone number.
  ///
  /// Matches strings containing digits, optional leading `+`, and common
  /// separators (hyphens, spaces, parentheses). Requires at least 3 characters.
  bool get isValidPhoneNumber {
    final s = trim();
    final re = RegExp(r'^\+?[0-9\-\s\(\)]{3,}$');
    return re.hasMatch(s);
  }

  /// Returns `true` if this string appears to be an email address.
  ///
  /// Uses a simple pattern: `local@domain.tld`. Does not validate leading/trailing
  /// whitespace - returns `false` if the string needs trimming.
  bool get isEmailAddress {
    final trimmed = trim();
    if (trimmed != this) return false;
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(trimmed);
  }

  /// Converts this phone number string into a `tel:` URI.
  ///
  /// Non-digit characters (except `+`) are stripped. For example,
  /// `'+1 (555) 123-4567'` becomes `tel:+15551234567`.
  Uri get toPhoneUri {
    final digits = replaceAll(RegExp(r'[^0-9\+]'), '');
    return Uri(scheme: 'tel', path: digits);
  }

  /// Converts this email string into a `mailto:` URI.
  ///
  /// The email address is trimmed and used as the path component.
  Uri get toMailUri => Uri(scheme: 'mailto', path: trim());

  /// Parses this string into a [Uri] using [Uri.parse].
  ///
  /// Throws [FormatException] if the string is not a valid URI.
  Uri get toUri => Uri.parse(this);
}
