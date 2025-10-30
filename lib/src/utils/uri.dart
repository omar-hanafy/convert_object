extension UriParsingX on String {
  bool get isValidPhoneNumber {
    final s = trim();
    final re = RegExp(r'^\+?[0-9\-\s\(\)]{3,}$');
    return re.hasMatch(s);
  }

  bool get isEmailAddress {
    final trimmed = trim();
    if (trimmed != this) return false;
    // Simple email pattern
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(trimmed);
  }

  Uri get toPhoneUri {
    final digits = replaceAll(RegExp(r'[^0-9\+]'), '');
    return Uri(scheme: 'tel', path: digits);
  }

  Uri get toMailUri => Uri(scheme: 'mailto', path: trim());

  Uri get toUri => Uri.parse(this);
}
