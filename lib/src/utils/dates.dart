import 'package:intl/intl.dart';

// Reused matchers and formatters to avoid repeated allocations on hot paths.
final RegExp _alphaRe = RegExp(r'[\p{L}]', unicode: true);
final RegExp _digitsOnlyRe = RegExp(r'[^0-9]');
final RegExp _ordinalsRe =
    RegExp(r'\b(\d+)(st|nd|rd|th)\b', caseSensitive: false);
final DateFormat _httpDateFmt =
    DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');

/// Extension methods for parsing `String` values into [DateTime] instances.
extension DateParsingTextX on String {
  /// Parses this string using [DateTime.parse] after trimming.
  DateTime toDateTime() => DateTime.parse(trim());

  /// Attempts to parse this string returning `null` when parsing fails.
  DateTime? tryToDateTime() {
    try {
      return toDateTime();
    } catch (_) {
      return null;
    }
  }

  /// Parses this string using the supplied [format] and [locale].
  DateTime toDateFormatted(String format, String? locale, {bool utc = false}) {
    final df = _createDateFormat(format, locale);
    final input = trim();
    final dt = utc ? df.parseUtc(input) : df.parse(input);
    return utc ? dt.toUtc() : dt;
  }

  /// Attempts to parse this string using the supplied [format] and [locale].
  DateTime? tryToDateFormatted(String format, String? locale,
      {bool utc = false}) {
    try {
      return toDateFormatted(format, locale, utc: utc);
    } catch (_) {
      return null;
    }
  }

  /// Auto-detect date parser with stable, round-trip behavior for numeric/locale forms.
  ///
  /// Returns a local [DateTime] for calendar-style inputs (e.g. `yyyyMMdd`,
  /// `MM/dd/yyyy`, long month names) unless [utc] is `true`, in which case the
  /// parsed value is converted to UTC. Inputs that describe an instant (ISO
  /// strings with offsets/`Z`, HTTP-date with `GMT`, or Unix epochs) preserve
  /// their UTC meaning; if [utc] is `false` the result is converted back to the
  /// local time zone to match common expectations.
  ///
  /// Priority:
  ///  0) Unix epoch (9–10 digits = sec, 12–13 digits = ms) with 12-digit guard for yyyyMMddHHmm
  ///  1) ISO-8601 / RFC3339 via DateTime.parse
  ///  2) HTTP-date (IMF-fixdate, GMT) → UTC
  ///  3) Slashed ambiguous numeric (MM/dd[/HH:mm:ss] vs dd/MM[/...]) by locale using intl
  ///  4) Compact numeric calendar (yyyyMMdd[HHmm[ss]]) including underscore/space variants
  ///     - 8 digits use intl('yyyyMMdd')
  ///     - 12/14 digits parsed manually
  ///  5) Long name formats via intl
  ///  6) Time-only → today (local)
  DateTime toDateAutoFormat({
    String? locale,
    bool useCurrentLocale = false,
    bool utc = false,
  }) {
    final raw = trim();
    if (raw.isEmpty) {
      throw const FormatException('Invalid or unsupported date format', '');
    }

    // Effective locale for ambiguous decisions.
    final effectiveLocale =
        locale ?? (useCurrentLocale ? Intl.getCurrentLocale() : null);
    final isUS =
        (effectiveLocale ?? Intl.getCurrentLocale()).startsWith('en_US');

    // 0) Unix epoch first (handles pure digits), with 12-digit disambiguation.
    final unix = _tryParseUnix(raw);
    if (unix != null) {
      // _tryParseUnix returns a UTC DateTime.
      return utc ? unix.toUtc() : unix.toLocal();
    }

    // 1) ISO/RFC3339
    try {
      final iso = DateTime.parse(raw);
      return utc ? iso.toUtc() : iso;
    } catch (_) {}

    // 2) HTTP-date (RFC 7231 IMF-fixdate)
    final http = _tryParseHttpDate(raw);
    if (http != null) return utc ? http.toUtc() : http;

    // Normalize variants we might want to try
    final variants = <String>{
      raw,
      _normalize(raw),
      raw.replaceAll('_', ' '),
    }.where((s) => s.isNotEmpty).toList();

    // 3) Slashed ambiguous numeric using intl (ensures formatter/parser symmetry)
    //    Try the preferred interpretation first, then the alternative.
    final slashedCandidates = isUS
        ? const [
            'MM/dd/yyyy HH:mm:ss',
            'MM/dd/yyyy',
            'dd/MM/yyyy HH:mm:ss',
            'dd/MM/yyyy'
          ]
        : const [
            'dd/MM/yyyy HH:mm:ss',
            'dd/MM/yyyy',
            'MM/dd/yyyy HH:mm:ss',
            'MM/dd/yyyy'
          ];

    for (final fmt in slashedCandidates) {
      for (final text in variants) {
        final dt = _tryParseWith(fmt, text, effectiveLocale);
        if (dt != null) return utc ? dt.toUtc() : dt;
      }
    }

    // 4) Compact numeric (yyyyMMdd[HHmm[ss]]) and underscored/space variants
    final compact = _tryParseCompactDate(
      raw,
      utc: utc,
      localeForDateOnly: effectiveLocale,
    );
    if (compact != null) return compact;

    // 5) Long/alpha forms via intl
    const intlPatterns = <String>[
      "EEEE, MMMM d, yyyy 'at' h:mm a",
      'EEEE, MMMM d, yyyy',
      'MMMM d, yyyy h:mm a',
      'MMMM d, yyyy',
      'd MMMM yyyy HH:mm:ss',
      'd MMMM yyyy',
      // Safety net
      'yyyy-MM-dd HH:mm:ss',
    ];

    for (final fmt in intlPatterns) {
      for (final text in variants) {
        final dt = _tryParseWith(fmt, text, effectiveLocale);
        if (dt != null) return utc ? dt.toUtc() : dt;
      }
    }

    // 6) Time-only → today (local)
    for (final fmt in ['HH:mm:ss', 'HH:mm', 'hh:mm:ss a', 'hh:mm a']) {
      for (final text in variants) {
        final t = _tryParseWith(fmt, text, effectiveLocale);
        if (t != null) {
          final now = DateTime.now();
          final today = DateTime(
            now.year,
            now.month,
            now.day,
            t.hour,
            t.minute,
            t.second,
            t.millisecond,
            t.microsecond,
          );
          return utc ? today.toUtc() : today;
        }
      }
    }

    throw FormatException('Invalid or unsupported date format', raw);
  }

  /// Attempts [toDateAutoFormat] while swallowing parsing errors.
  DateTime? tryToDateAutoFormat({
    String? locale,
    bool useCurrentLocale = false,
    bool utc = false,
  }) {
    try {
      return toDateAutoFormat(
        locale: locale,
        useCurrentLocale: useCurrentLocale,
        utc: utc,
      );
    } catch (_) {
      return null;
    }
  }
}

// --- Helpers ---------------------------------------------------------------

DateTime? _tryParseHttpDate(String s) {
  try {
    final dt = _httpDateFmt.parseUtc(s);
    return dt.toUtc();
  } catch (_) {
    return null;
  }
}

/// Decide whether a 12-digit string is plausibly a calendar timestamp
/// in the form yyyyMMddHHmm (year 1800..2500 etc.).
bool _looksLikeYYYYMMDDHHMM(String digits12) {
  if (digits12.length != 12) return false;
  final y = int.tryParse(digits12.substring(0, 4));
  final mo = int.tryParse(digits12.substring(4, 6));
  final d = int.tryParse(digits12.substring(6, 8));
  final hh = int.tryParse(digits12.substring(8, 10));
  final mm = int.tryParse(digits12.substring(10, 12));
  if (y == null || mo == null || d == null || hh == null || mm == null) {
    return false;
  }
  if (y < 1800 || y > 2500) return false;
  if (mo < 1 || mo > 12) return false;
  if (d < 1 || d > 31) return false;
  if (hh < 0 || hh > 23) return false;
  if (mm < 0 || mm > 59) return false;
  return true;
}

DateTime? _tryParseUnix(String s) {
  final trimmed = s.trim();
  if (!RegExp(r'^[+-]?\d+$').hasMatch(trimmed)) return null;

  final negative = trimmed.startsWith('-');
  final body =
      (negative || trimmed.startsWith('+')) ? trimmed.substring(1) : trimmed;
  final len = body.length;

  try {
    if (len == 9 || len == 10) {
      // seconds
      final secs = int.parse(trimmed);
      return DateTime.fromMillisecondsSinceEpoch(secs * 1000, isUtc: true);
    }
    if (len == 12 || len == 13) {
      // milliseconds (12 or 13 digits)
      if (len == 12 && _looksLikeYYYYMMDDHHMM(body)) {
        // Let compact calendar parser handle yyyyMMddHHmm
        return null;
      }
      final ms = int.parse(trimmed);
      return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    }
  } catch (_) {
    return null;
  }
  return null;
}

String _normalize(String s) {
  var out = s.replaceAll('_', ' ');
  // Remove English ordinals: 1st, 2nd, 3rd, 4th, ...
  out = out.replaceAll(_ordinalsRe, r'$1');
  return out.trim();
}

DateTime? _tryParseWith(String fmt, String s, String? locale) {
  try {
    final f = _createDateFormat(fmt, locale);
    return f.parse(s);
  } catch (_) {
    return null;
  }
}

/// Parses compact calendar forms by stripping non-digits and reading:
/// - 8  digits: yyyyMMdd  (parsed with intl to mirror formatter semantics)
/// - 12 digits: yyyyMMddHHmm (manual)
/// - 14 digits: yyyyMMddHHmmss (manual)
///
/// Returns local DateTime (or UTC if [utc] is true).
DateTime? _tryParseCompactDate(
  String input, {
  bool utc = false,
  String? localeForDateOnly,
}) {
  if (_alphaRe.hasMatch(input)) return null;

  final digitsOnly = input.replaceAll(_digitsOnlyRe, '');
  if (digitsOnly.isEmpty) return null;

  // 8 -> use intl('yyyyMMdd') to match how the test formats dates.
  if (digitsOnly.length == 8) {
    try {
      final df = _createDateFormat('yyyyMMdd', localeForDateOnly);
      final local = df.parse(digitsOnly);
      return utc ? local.toUtc() : local;
    } catch (_) {
      return null;
    }
  }

  if (digitsOnly.length != 12 && digitsOnly.length != 14) {
    return null;
  }

  try {
    final year = int.parse(digitsOnly.substring(0, 4));
    final month = int.parse(digitsOnly.substring(4, 6));
    final day = int.parse(digitsOnly.substring(6, 8));
    final hour = int.parse(digitsOnly.substring(8, 10));
    final minute = int.parse(digitsOnly.substring(10, 12));
    var second = 0;

    if (digitsOnly.length == 14) {
      second = int.parse(digitsOnly.substring(12, 14));
    }

    if (year < 1800 || year > 2500) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    if (hour < 0 || hour > 23) return null;
    if (minute < 0 || minute > 59) return null;
    if (digitsOnly.length == 14 && (second < 0 || second > 59)) return null;

    final local = DateTime(year, month, day, hour, minute, second);
    return utc ? local.toUtc() : local;
  } catch (_) {
    return null;
  }
}

DateFormat _createDateFormat(String pattern, String? locale) {
  final attempts = <String?>[
    locale,
    if (locale != null && locale.contains('_')) locale.split('_').first,
    null,
  ];
  for (final candidate in attempts) {
    try {
      return candidate == null
          ? DateFormat(pattern)
          : DateFormat(pattern, candidate);
    } catch (_) {
      continue;
    }
  }
  return DateFormat(pattern);
}
