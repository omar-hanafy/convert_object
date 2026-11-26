import 'package:intl/intl.dart';

final RegExp _compactDate = RegExp(
  r'^(\d{4})(?:[ _]+|[-./])?(\d{2})(?:[ _]+|[-./])?(\d{2})'
  r'(?:[ _]*(\d{2})(?:[ _]+|:)?(\d{2})(?:(?:[ _]+|:)?(\d{2}))?)?$',
);
final RegExp _epoch = RegExp(r'^[+-]?(\d{9,10}|\d{12,13})$');
final RegExp _clockHour = RegExp(r'(\p{Nd}+):', unicode: true);
final RegExp _ordinalsRe = RegExp(
  r'\b(\d+)(st|nd|rd|th)\b',
  caseSensitive: false,
);
final DateFormat _httpDateFmt = DateFormat(
  "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
  'en_US',
);
const int _kMaxDateFormatCacheSize = 32;
final _dateFormatCache = <(String, String), DateFormat>{};

/// Extension methods for parsing [String] values into [DateTime] instances.
///
/// Provides multiple parsing strategies:
/// * [toDateTime] - ISO 8601 / RFC 3339 parsing with [DateTime.parse].
/// * [toDateFormatted] - Custom pattern parsing via [DateFormat].
/// * [toDateAutoFormat] - Heuristic auto-detection for diverse formats.
///
/// Used internally by `Convert.toDateTime` to implement date conversion.
///
/// See also: `DateOptions` for configuring default parsing behavior.
extension DateParsingTextX on String {
  /// Parses this string into a [DateTime] using standard ISO 8601 or RFC 3339 formats.
  ///
  /// Delegates to [DateTime.parse] after trimming whitespace. Supports timezone
  /// offsets (e.g., `+05:30`, `Z`) and fractional seconds.
  ///
  /// Throws [FormatException] if the input is invalid.
  DateTime toDateTime() => DateTime.parse(trim());

  /// Attempts to parse this string into a [DateTime], returning `null` on failure.
  DateTime? tryToDateTime() {
    try {
      return toDateTime();
    } catch (_) {
      return null;
    }
  }

  /// Parses this string using the supplied [format] and [locale].
  ///
  /// The [format] string should follow the [DateFormat] patterns (e.g., "MM/dd/yyyy").
  /// With [utc] enabled, the supplied clock fields are interpreted in UTC.
  DateTime toDateFormatted(String format, String? locale, {bool utc = false}) {
    final df = _createDateFormat(format, locale);
    final input = trim();
    final dt = utc ? df.parseUtc(input) : df.parse(input);
    return utc ? dt.toUtc() : dt;
  }

  /// Attempts to parse this string using [format] and [locale], returning `null` on failure.
  DateTime? tryToDateFormatted(
    String format,
    String? locale, {
    bool utc = false,
  }) {
    try {
      return toDateFormatted(format, locale, utc: utc);
    } catch (_) {
      return null;
    }
  }

  /// Attempts to parse the date using a variety of known formats.
  ///
  /// Returns a local [DateTime] for calendar-style inputs (e.g. `yyyyMMdd`,
  /// `MM/dd/yyyy`, long month names) unless [utc] is `true`, in which case the
  /// parsed value is converted to UTC.
  ///
  /// ISO strings with an offset or `Z` and HTTP dates with `GMT` return UTC.
  /// Epochs preserve their instant and use the local time zone unless [utc]
  /// is `true`.
  ///
  /// Epochs use 9-10 digits for seconds and 12-13 for milliseconds. An
  /// unsigned, valid `yyyyMMddHHmm` in years 1800-2500 takes precedence over
  /// a 12-digit epoch. Compact dates also accept spaces and underscores.
  ///
  /// Other formats include ISO strings accepted by [DateTime.parse], HTTP
  /// dates in GMT, locale-ordered slashed dates and long month names.
  /// Time-only input uses today's local date. A clock with a day period
  /// such as AM or PM accepts hours from 1 through 12.
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
    final isUS = Intl.canonicalizedLocale(
      effectiveLocale ?? Intl.getCurrentLocale(),
    ).startsWith('en_US');

    // A valid unsigned calendar takes precedence over a 12-digit epoch.
    final compactMatch = _compactDate.firstMatch(raw);
    if (compactMatch != null) {
      final date = _parseCompactDate(compactMatch);
      if (date != null) return utc ? date.toUtc() : date;
    }
    final unix = _tryParseUnix(raw);
    if (unix != null) {
      return utc ? unix : unix.toLocal();
    }
    // A bare yyyyMMdd has already been checked for calendar validity. Other
    // ISO forms, including a basic date followed by a time, use Dart's parser.
    if (compactMatch == null || raw.length != 8) {
      final iso = DateTime.tryParse(raw);
      if (iso != null) return utc ? iso.toUtc() : iso;
    }
    if (compactMatch != null) {
      throw FormatException('Invalid compact calendar date', raw);
    }

    // 2) HTTP-date (RFC 7231 IMF-fixdate)
    final http = _tryParseHttpDate(raw);
    if (http != null) return http;

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
            'dd/MM/yyyy',
          ]
        : const [
            'dd/MM/yyyy HH:mm:ss',
            'dd/MM/yyyy',
            'MM/dd/yyyy HH:mm:ss',
            'MM/dd/yyyy',
          ];

    for (final fmt in slashedCandidates) {
      for (final text in variants) {
        final dt = _tryParseWith(fmt, text, effectiveLocale);
        if (dt != null) return utc ? dt.toUtc() : dt;
      }
    }

    // Long/alpha forms via intl
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

    // Time-only → today (local)
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

// The HTTP formatter needs English locale data even when the input is local.
DateTime? _tryParseHttpDate(String text) {
  try {
    return _httpDateFmt.parseStrict(text, true);
  } catch (_) {
    return null;
  }
}

DateTime? _tryParseUnix(String text) {
  final match = _epoch.firstMatch(text);
  if (match == null) return null;
  final value = int.parse(text);
  final milliseconds = match[1]!.length <= 10
      ? value * Duration.millisecondsPerSecond
      : value;
  return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
}

// Normalizes date strings by replacing underscores with spaces and stripping
// English ordinals (1st, 2nd, 3rd) that would otherwise cause parsing failures.
String _normalize(String s) {
  var out = s.replaceAll('_', ' ');
  out = out.replaceAllMapped(_ordinalsRe, (match) => match[1]!);
  return out.trim();
}

// Attempts to parse a date string with a specific format pattern.
DateTime? _tryParseWith(String pattern, String input, String? locale) {
  try {
    final formatter = _createDateFormat(pattern, locale);
    final date = formatter.parseStrict(input);
    if (pattern.contains('h:mm')) {
      // intl validates the converted 24-hour value. Check the input hour too,
      // since values such as 13 AM and 00 PM survive that conversion.
      final digits = _clockHour.firstMatch(input)![1]!;
      final zero = formatter.localeZeroCodeUnit;
      final hour = digits.codeUnits.fold(
        0,
        (n, digit) => n * 10 + digit - zero,
      );
      if (hour < 1 || hour > 12) return null;
    }
    return date;
  } catch (_) {
    return null;
  }
}

DateTime? _parseCompactDate(RegExpMatch match) {
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final hour = int.parse(match[4] ?? '0');
  final minute = int.parse(match[5] ?? '0');
  final second = int.parse(match[6] ?? '0');

  // A plain eight-digit ISO date supports every four-digit year. The
  // other compact forms use a narrower range to distinguish epochs.
  if (match[0]!.length != 8 && (year < 1800 || year > 2500)) return null;
  if (month < 1 || month > 12 || hour > 23 || minute > 59 || second > 59) {
    return null;
  }
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  if (day < 1 || day > lastDay) return null;
  return DateTime(year, month, day, hour, minute, second);
}

DateFormat _createDateFormat(String pattern, String? locale) {
  // Resolve before looking in the cache. The scoped Intl locale and the set
  // of initialized date symbols can change between calls.
  String? resolved;
  if (locale != null) {
    try {
      resolved = Intl.verifiedLocale(
        locale,
        DateFormat.localeExists,
        onFailure: (_) => null,
      );
    } on Exception {
      // Locale data initialization is optional. Try the current locale.
    }
  }
  resolved ??= Intl.verifiedLocale(null, DateFormat.localeExists)!;

  final key = (pattern, resolved);
  final format = _dateFormatCache.remove(key) ?? DateFormat(pattern, resolved);
  _dateFormatCache[key] = format;
  if (_dateFormatCache.length > _kMaxDateFormatCacheSize) {
    _dateFormatCache.remove(_dateFormatCache.keys.first);
  }
  return format;
}
