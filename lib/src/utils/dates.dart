import 'dart:collection';

import 'package:intl/intl.dart';

// Reused matchers and formatters to avoid repeated allocations on hot paths.
final RegExp _alphaRe = RegExp(r'[\p{L}]', unicode: true);
final RegExp _digitsOnlyRe = RegExp(r'[^0-9]');
final RegExp _ordinalsRe = RegExp(
  r'\b(\d+)(st|nd|rd|th)\b',
  caseSensitive: false,
);
final DateFormat _httpDateFmt = DateFormat(
  "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
  'en_US',
);
const int _kMaxDateFormatCacheSize = 32;
final LinkedHashMap<String, DateFormat> _dateFormatCache =
    LinkedHashMap<String, DateFormat>();

/// Extension methods for parsing [String] values into [DateTime] instances.
///
/// Provides multiple parsing strategies:
/// * [toDateTime] - Strict ISO 8601 / RFC 3339 parsing.
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
  /// If [utc] is true, the result will be in UTC.
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
  /// Inputs that describe an instant (ISO strings with offsets/`Z`, HTTP-date with `GMT`,
  /// or Unix epochs) preserve their UTC meaning. If [utc] is `false`, the result is
  /// converted back to the local time zone.
  ///
  /// ### Parsing Priority
  /// 1. **Unix Epoch:** 9–10 digits (seconds) or 12–13 digits (milliseconds).
  /// 2. **ISO-8601 / RFC3339:** Standard `DateTime.parse`.
  /// 3. **HTTP Date:** RFC 7231 (e.g., `EEE, dd MMM yyyy HH:mm:ss 'GMT'`).
  /// 4. **Ambiguous Numeric:** Slashed dates (e.g., `MM/dd/yyyy`) resolved by locale.
  /// 5. **Compact Numeric:** `yyyyMMdd` (8 digits), `yyyyMMddHHmm` (12 digits), etc.
  /// 6. **Long Form:** `MMMM d, yyyy`, etc.
  /// 7. **Time Only:** `HH:mm:ss` (defaults to today's date).
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
    final isUS = (effectiveLocale ?? Intl.getCurrentLocale()).startsWith(
      'en_US',
    );

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

    // 4) Compact numeric (yyyyMMdd[HHmm[ss]]) and underscored/space variants
    final compact = _tryParseCompactDate(raw, utc: utc);
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

// Parses RFC 7231 HTTP-date format (used in HTTP headers like Last-Modified).
DateTime? _tryParseHttpDate(String s) {
  try {
    final dt = _httpDateFmt.parseUtc(s);
    return dt.toUtc();
  } catch (_) {
    return null;
  }
}

// Distinguishes 12-digit calendar timestamps (yyyyMMddHHmm) from Unix milliseconds.
// Without this check, dates like "202501191430" would be misinterpreted as epochs.
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

// Parses Unix timestamps: 9-10 digits as seconds, 12-13 digits as milliseconds.
// Returns UTC DateTime; caller converts to local if needed.
DateTime? _tryParseUnix(String s) {
  final trimmed = s.trim();
  if (!RegExp(r'^[+-]?\d+$').hasMatch(trimmed)) return null;

  final negative = trimmed.startsWith('-');
  final body = (negative || trimmed.startsWith('+'))
      ? trimmed.substring(1)
      : trimmed;
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

// Normalizes date strings by replacing underscores with spaces and stripping
// English ordinals (1st, 2nd, 3rd) that would otherwise cause parsing failures.
String _normalize(String s) {
  var out = s.replaceAll('_', ' ');
  out = out.replaceAll(_ordinalsRe, r'$1');
  return out.trim();
}

// Attempts to parse a date string with a specific format pattern.
DateTime? _tryParseWith(String fmt, String s, String? locale) {
  try {
    final f = _createDateFormat(fmt, locale);
    return f.parse(s);
  } catch (_) {
    return null;
  }
}

// Parses compact numeric date formats (yyyyMMdd, yyyyMMddHHmm, yyyyMMddHHmmss).
// We parse manually instead of using intl because intl is too lenient with these patterns.
DateTime? _tryParseCompactDate(String input, {bool utc = false}) {
  if (_alphaRe.hasMatch(input)) return null;

  final digitsOnly = input.replaceAll(_digitsOnlyRe, '');
  if (digitsOnly.isEmpty) return null;

  // 8 -> parse yyyyMMdd manually (intl parsing is lenient for this pattern).
  if (digitsOnly.length == 8) {
    try {
      final year = int.parse(digitsOnly.substring(0, 4));
      final month = int.parse(digitsOnly.substring(4, 6));
      final day = int.parse(digitsOnly.substring(6, 8));

      if (year < 1800 || year > 2500) return null;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;

      final local = DateTime(year, month, day);
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

// Creates a DateFormat with LRU caching. Falls back through locale variants
// (full -> language only -> default) to handle unsupported locales gracefully.
DateFormat _createDateFormat(String pattern, String? locale) {
  final key = '$pattern|${locale ?? ''}';
  final cached = _dateFormatCache.remove(key);
  if (cached != null) {
    _dateFormatCache[key] = cached;
    return cached;
  }

  final attempts = <String?>[
    locale,
    if (locale != null && locale.contains('_')) locale.split('_').first,
    null,
  ];
  DateFormat? created;
  for (final candidate in attempts) {
    try {
      created = candidate == null
          ? DateFormat(pattern)
          : DateFormat(pattern, candidate);
      break;
    } catch (_) {
      continue;
    }
  }
  created ??= DateFormat(pattern);
  _dateFormatCache[key] = created;
  if (_dateFormatCache.length > _kMaxDateFormatCacheSize) {
    _dateFormatCache.remove(_dateFormatCache.keys.first);
  }
  return created;
}
