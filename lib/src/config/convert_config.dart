import 'dart:async';

import 'package:convert_object/src/exceptions/conversion_exception.dart';
import 'package:meta/meta.dart';

/// Signature for a callback that is invoked when a conversion fails.
///
/// If `ConvertConfig.onException` is provided, the hook is called with the
/// thrown [ConversionException] just before it is rethrown. Use this to log
/// errors or collect metrics; do not modify control flow.
typedef ExceptionHook = void Function(ConversionException error);

// Default string tokens recognized as boolean `true` by [BoolOptions].
const Set<String> _kDefaultTruthy = {'true', '1', 'yes', 'y', 'on', 'ok', 't'};

// Default string tokens recognized as boolean `false` by [BoolOptions].
const Set<String> _kDefaultFalsy = {'false', '0', 'no', 'n', 'off', 'f'};

// Bitmask flags tracking which fields were explicitly set in `ConvertConfig.overrides`.
// We need to distinguish "explicitly set to null" vs "not provided" during merging.
const int _overrideLocale = 1 << 0;
const int _overrideNumbers = 1 << 1;
const int _overrideDates = 1 << 2;
const int _overrideBools = 1 << 3;
const int _overrideUri = 1 << 4;
const int _overrideRegistry = 1 << 5;
const int _overrideOnException = 1 << 6;

// Checks if a specific override flag is set in the bitmask.
bool _hasOverride(int mask, int flag) => (mask & flag) != 0;

// Value-based set equality check (const sets may not be identical across locations).
bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}

// Checks if options match defaults - used to skip merging unchanged options.

bool _isDefaultNumberOptions(NumberOptions options) =>
    options.defaultFormat == null &&
    options.defaultLocale == null &&
    options.tryFormattedFirst == true;

bool _isDefaultDateOptions(DateOptions options) =>
    options.defaultFormat == null &&
    options.locale == null &&
    options.utc == false &&
    options.autoDetectFormat == false &&
    options.useCurrentLocale == false &&
    options.extraAutoDetectPatterns.isEmpty;

bool _isDefaultBoolOptions(BoolOptions options) =>
    options.numericPositiveIsTrue == true &&
    _setEquals(options.truthy, _kDefaultTruthy) &&
    _setEquals(options.falsy, _kDefaultFalsy);

bool _isDefaultUriOptions(UriOptions options) =>
    options.defaultScheme == null &&
    options.coerceBareDomainsToDefaultScheme == false &&
    options.allowRelative == true;

bool _isDefaultRegistry(TypeRegistry registry) => registry._parsers.isEmpty;

/// Global and scoped configuration bundle for all `convert_object` APIs.
///
/// `ConvertConfig` controls parsing behavior for numbers, dates, booleans,
/// URIs, and custom types. A single global instance is active by default,
/// but you can customize behavior in several ways:
///
/// * [configure] - Replace the global configuration entirely.
/// * [update] - Modify the global configuration incrementally.
/// * [runScoped] - Apply temporary overrides for a call tree (zone-scoped).
///
/// ### Example: Global Configuration
/// ```dart
/// // Set locale globally
/// ConvertConfig.configure(ConvertConfig(locale: 'de_DE'));
///
/// // Update specific options
/// ConvertConfig.update((c) => c.copyWith(
///   dates: c.dates.copyWith(autoDetectFormat: true),
/// ));
/// ```
///
/// ### Example: Scoped Configuration
/// ```dart
/// ConvertConfig.runScoped(
///   ConvertConfig.overrides(locale: 'fr_FR'),
///   () {
///     // All conversions in this block use French locale
///     final date = Convert.toDateTime('15/03/2024', autoDetectFormat: true);
///   },
/// );
/// ```
///
/// See also:
/// * [NumberOptions] for numeric parsing configuration.
/// * [DateOptions] for date/time parsing configuration.
/// * [BoolOptions] for boolean parsing configuration.
/// * [UriOptions] for URI parsing and coercion.
/// * [TypeRegistry] for custom type parsers.
@immutable
class ConvertConfig {
  /// Creates a new configuration bundle.
  const ConvertConfig({
    this.locale,
    this.numbers = const NumberOptions(),
    this.dates = const DateOptions(),
    this.bools = const BoolOptions(),
    this.uri = const UriOptions(),
    this.registry = const TypeRegistry.empty(),
    this.onException,
  }) : _overrideMask = 0;

  const ConvertConfig._override({
    this.locale,
    this.numbers = const NumberOptions(),
    this.dates = const DateOptions(),
    this.bools = const BoolOptions(),
    this.uri = const UriOptions(),
    this.registry = const TypeRegistry.empty(),
    this.onException,
    required int overrideMask,
  }) : _overrideMask = overrideMask;

  /// Creates a config intended for scoped overrides.
  ///
  /// Provide only the fields you want to override; unset fields keep the
  /// current effective values when merged in [runScoped].
  factory ConvertConfig.overrides({
    String? locale,
    bool clearLocale = false,
    NumberOptions? numbers,
    DateOptions? dates,
    BoolOptions? bools,
    UriOptions? uri,
    TypeRegistry? registry,
    ExceptionHook? onException,
    bool clearOnException = false,
  }) {
    var mask = 0;
    String? effectiveLocale;
    if (locale != null || clearLocale) {
      mask |= _overrideLocale;
      effectiveLocale = clearLocale ? null : locale;
    }
    if (numbers != null) mask |= _overrideNumbers;
    if (dates != null) mask |= _overrideDates;
    if (bools != null) mask |= _overrideBools;
    if (uri != null) mask |= _overrideUri;
    if (registry != null) mask |= _overrideRegistry;
    if (onException != null || clearOnException) {
      mask |= _overrideOnException;
    }

    return ConvertConfig._override(
      locale: effectiveLocale,
      numbers: numbers ?? const NumberOptions(),
      dates: dates ?? const DateOptions(),
      bools: bools ?? const BoolOptions(),
      uri: uri ?? const UriOptions(),
      registry: registry ?? const TypeRegistry.empty(),
      onException: clearOnException ? null : onException,
      overrideMask: mask,
    );
  }

  /// The default locale identifier (e.g., 'en_US') used for parsing operations
  /// when no specific locale is provided in [numbers] or [dates].
  final String? locale;

  /// Configuration for parsing and formatting numeric values.
  final NumberOptions numbers;

  /// Configuration for date and time parsing and formatting.
  final DateOptions dates;

  /// Configuration for boolean parsing.
  final BoolOptions bools;

  /// Configuration for URI parsing.
  final UriOptions uri;

  /// A registry of custom parsers for handling additional types in `Convert.toType`.
  final TypeRegistry registry;

  /// An optional hook that is invoked whenever a [ConversionException] is thrown.
  ///
  /// Use this to log errors or collect metrics without interrupting the control flow.
  final ExceptionHook? onException;

  // Bitmask tracking which fields were explicitly set via `ConvertConfig.overrides`.
  // Used by [_merge] to distinguish "explicitly set to null" from "not provided".
  final int _overrideMask;

  /// Returns a copy of this config with the provided fields replaced.
  ConvertConfig copyWith({
    String? locale,
    NumberOptions? numbers,
    DateOptions? dates,
    BoolOptions? bools,
    UriOptions? uri,
    TypeRegistry? registry,
    ExceptionHook? onException,
  }) => ConvertConfig(
    locale: locale ?? this.locale,
    numbers: numbers ?? this.numbers,
    dates: dates ?? this.dates,
    bools: bools ?? this.bools,
    uri: uri ?? this.uri,
    registry: registry ?? this.registry,
    onException: onException ?? this.onException,
  );

  static ConvertConfig _global = const ConvertConfig();
  static final Object _zoneKey = Object();

  /// The configuration that is currently in effect (global or zone-overridden).
  static ConvertConfig get effective =>
      (Zone.current[_zoneKey] as ConvertConfig?) ?? _global;

  /// Replaces the global configuration and returns the previous instance.
  static ConvertConfig configure(ConvertConfig config) {
    final previous = _global;
    _global = config;
    return previous;
  }

  /// Updates the global configuration by applying [updater] to the current
  /// instance.
  static void update(ConvertConfig Function(ConvertConfig current) updater) {
    _global = updater(_global);
  }

  /// Runs [body] with [overrides] merged on top of the [effective] config.
  ///
  /// Only fields explicitly set in [overrides] are applied; nested option
  /// objects are merged where appropriate.
  static T runScoped<T>(ConvertConfig overrides, T Function() body) {
    final base = effective;
    final merged = base._merge(overrides);
    return runZoned(body, zoneValues: {_zoneKey: merged});
  }

  // Merges [overrides] on top of this config. Checks both the override bitmask
  // and whether values differ from defaults to handle explicit nulls correctly.
  ConvertConfig _merge(ConvertConfig overrides) {
    final onExceptionHook =
        _hasOverride(overrides._overrideMask, _overrideOnException)
        ? overrides.onException
        : overrides.onException ?? onException;

    final shouldMergeNumbers =
        _hasOverride(overrides._overrideMask, _overrideNumbers) ||
        !_isDefaultNumberOptions(overrides.numbers);
    final mergedNumbers = shouldMergeNumbers
        ? numbers.merge(overrides.numbers)
        : numbers;

    final shouldMergeDates =
        _hasOverride(overrides._overrideMask, _overrideDates) ||
        !_isDefaultDateOptions(overrides.dates);
    final mergedDates = shouldMergeDates ? dates.merge(overrides.dates) : dates;

    final shouldMergeBools =
        _hasOverride(overrides._overrideMask, _overrideBools) ||
        !_isDefaultBoolOptions(overrides.bools);
    final mergedBools = shouldMergeBools ? bools.merge(overrides.bools) : bools;

    final shouldMergeUri =
        _hasOverride(overrides._overrideMask, _overrideUri) ||
        !_isDefaultUriOptions(overrides.uri);
    final mergedUri = shouldMergeUri ? uri.merge(overrides.uri) : uri;

    final shouldMergeRegistry =
        _hasOverride(overrides._overrideMask, _overrideRegistry) ||
        !_isDefaultRegistry(overrides.registry);
    final mergedRegistry = shouldMergeRegistry
        ? registry.merge(overrides.registry)
        : registry;

    return ConvertConfig(
      locale: _hasOverride(overrides._overrideMask, _overrideLocale)
          ? overrides.locale
          : overrides.locale ?? locale,
      numbers: mergedNumbers,
      dates: mergedDates,
      bools: mergedBools,
      uri: mergedUri,
      registry: mergedRegistry,
      onException: onExceptionHook,
    );
  }
}

/// Options that control numeric parsing.
@immutable
class NumberOptions {
  /// Creates a new [NumberOptions].
  const NumberOptions({
    this.defaultFormat,
    this.defaultLocale,
    this.tryFormattedFirst = true,
  });

  /// The default [NumberFormat] pattern to use when parsing formatted numbers
  /// if no explicit format is provided.
  ///
  /// Example: `#,##0.00` for currency-like inputs.
  final String? defaultFormat;

  /// The locale identifier to use when [defaultFormat] is applied.
  ///
  /// If `null`, defaults to `ConvertConfig.locale`.
  final String? defaultLocale;

  /// Controls the priority of formatted parsing versus standard parsing.
  ///
  /// If `true`, the parser attempts to use [defaultFormat] first. If that fails,
  /// it falls back to standard `num.parse`.
  /// If `false`, standard `num.parse` is attempted first.
  final bool tryFormattedFirst;

  /// Returns a new [NumberOptions] that prefers [other]'s non-null settings.
  NumberOptions merge(NumberOptions other) => NumberOptions(
    defaultFormat: other.defaultFormat ?? defaultFormat,
    defaultLocale: other.defaultLocale ?? defaultLocale,
    tryFormattedFirst: other.tryFormattedFirst,
  );

  /// Returns a copy with selected fields replaced.
  NumberOptions copyWith({
    String? defaultFormat,
    String? defaultLocale,
    bool? tryFormattedFirst,
  }) => NumberOptions(
    defaultFormat: defaultFormat ?? this.defaultFormat,
    defaultLocale: defaultLocale ?? this.defaultLocale,
    tryFormattedFirst: tryFormattedFirst ?? this.tryFormattedFirst,
  );
}

/// Options that control date/time parsing.
@immutable
class DateOptions {
  /// Creates a new [DateOptions].
  const DateOptions({
    this.defaultFormat,
    this.locale,
    this.utc = false,
    this.autoDetectFormat = false,
    this.useCurrentLocale = false,
    this.extraAutoDetectPatterns = const [],
  });

  /// The default [DateFormat] pattern to use for parsing calendar-style inputs.
  ///
  /// Used when [autoDetectFormat] is `false` or as a fallback.
  final String? defaultFormat;

  /// The locale identifier to use for date parsing when a format is applied.
  ///
  /// If `null`, defaults to `ConvertConfig.locale`.
  final String? locale;

  /// Determines whether parsed dates should be converted to UTC.
  ///
  /// If `true`, the resulting [DateTime] will be in UTC.
  final bool utc;

  /// Enables heuristic parsing to attempt multiple known date formats.
  ///
  /// If `true`, the parser tries various standard patterns (ISO, HTTP, etc.)
  /// before failing.
  final bool autoDetectFormat;

  /// Determines whether to use [Intl.getCurrentLocale()] as a fallback.
  ///
  /// If `true` and no specific locale is provided, the system locale is used.
  final bool useCurrentLocale;

  /// A list of additional date patterns to attempt when [autoDetectFormat] is enabled.
  ///
  /// These patterns are tried before the built-in heuristic patterns.
  final List<String> extraAutoDetectPatterns;

  /// Returns a new [DateOptions] that prefers [other]'s non-null settings.
  DateOptions merge(DateOptions other) => DateOptions(
    defaultFormat: other.defaultFormat ?? defaultFormat,
    locale: other.locale ?? locale,
    utc: other.utc,
    autoDetectFormat: other.autoDetectFormat,
    useCurrentLocale: other.useCurrentLocale,
    extraAutoDetectPatterns: other.extraAutoDetectPatterns.isNotEmpty
        ? other.extraAutoDetectPatterns
        : extraAutoDetectPatterns,
  );

  /// Returns a copy with selected fields replaced.
  DateOptions copyWith({
    String? defaultFormat,
    String? locale,
    bool? utc,
    bool? autoDetectFormat,
    bool? useCurrentLocale,
    List<String>? extraAutoDetectPatterns,
  }) => DateOptions(
    defaultFormat: defaultFormat ?? this.defaultFormat,
    locale: locale ?? this.locale,
    utc: utc ?? this.utc,
    autoDetectFormat: autoDetectFormat ?? this.autoDetectFormat,
    useCurrentLocale: useCurrentLocale ?? this.useCurrentLocale,
    extraAutoDetectPatterns:
        extraAutoDetectPatterns ?? this.extraAutoDetectPatterns,
  );
}

/// Options that control boolean parsing.
@immutable
class BoolOptions {
  /// Creates a new [BoolOptions].
  const BoolOptions({
    this.truthy = const {'true', '1', 'yes', 'y', 'on', 'ok', 't'},
    this.falsy = const {'false', '0', 'no', 'n', 'off', 'f'},
    this.numericPositiveIsTrue = true,
  });

  /// A set of case-insensitive string tokens that resolve to `true`.
  ///
  /// Defaults include 'true', '1', 'yes', 'y', 'on', 'ok', 't'.
  final Set<String> truthy;

  /// A set of case-insensitive string tokens that resolve to `false`.
  ///
  /// Defaults include 'false', '0', 'no', 'n', 'off', 'f'.
  final Set<String> falsy;

  /// Determines how numeric values are converted to booleans.
  ///
  /// If `true`, only values > 0 are considered `true`.
  /// If `false`, any non-zero value is considered `true`.
  final bool numericPositiveIsTrue;

  /// Returns a new [BoolOptions] that prefers [other]'s settings.
  BoolOptions merge(BoolOptions other) => BoolOptions(
    truthy: other.truthy.isNotEmpty ? other.truthy : truthy,
    falsy: other.falsy.isNotEmpty ? other.falsy : falsy,
    numericPositiveIsTrue: other.numericPositiveIsTrue,
  );

  /// Returns a copy with selected fields replaced.
  BoolOptions copyWith({
    Set<String>? truthy,
    Set<String>? falsy,
    bool? numericPositiveIsTrue,
  }) => BoolOptions(
    truthy: truthy ?? this.truthy,
    falsy: falsy ?? this.falsy,
    numericPositiveIsTrue: numericPositiveIsTrue ?? this.numericPositiveIsTrue,
  );
}

/// Options that control URI parsing and coercion.
@immutable
class UriOptions {
  /// Creates a new [UriOptions].
  const UriOptions({
    this.defaultScheme,
    this.coerceBareDomainsToDefaultScheme = false,
    this.allowRelative = true,
  });

  /// The scheme to prepend to bare domains if [coerceBareDomainsToDefaultScheme] is enabled.
  ///
  /// Example: 'https'.
  final String? defaultScheme;

  /// Enables strict coercion of bare domains to [defaultScheme].
  ///
  /// If `true`, inputs like `example.com` become `https://example.com` (assuming defaultScheme is 'https').
  final bool coerceBareDomainsToDefaultScheme;

  /// Determines whether relative URIs are accepted.
  ///
  /// If `false`, parsing throws a [FormatException] for relative inputs.
  final bool allowRelative;

  /// Returns a new [UriOptions] that prefers [other]'s settings.
  UriOptions merge(UriOptions other) => UriOptions(
    defaultScheme: other.defaultScheme ?? defaultScheme,
    coerceBareDomainsToDefaultScheme: other.coerceBareDomainsToDefaultScheme,
    allowRelative: other.allowRelative,
  );

  /// Returns a copy with selected fields replaced.
  UriOptions copyWith({
    String? defaultScheme,
    bool? coerceBareDomainsToDefaultScheme,
    bool? allowRelative,
  }) => UriOptions(
    defaultScheme: defaultScheme ?? this.defaultScheme,
    coerceBareDomainsToDefaultScheme:
        coerceBareDomainsToDefaultScheme ??
        this.coerceBareDomainsToDefaultScheme,
    allowRelative: allowRelative ?? this.allowRelative,
  );
}

/// Registry of custom parsers for application-specific types.
///
/// Use [TypeRegistry] to extend `Convert.toType` and `Convert.tryToType` with
/// support for your own domain models. Each registered parser receives the raw
/// input and should return an instance of the target type.
///
/// ### Example
/// ```dart
/// class Money {
///   final int cents;
///   Money(this.cents);
///   factory Money.parse(Object? o) => Money(Convert.toInt(o));
/// }
///
/// final config = ConvertConfig(
///   registry: const TypeRegistry.empty().register<Money>(Money.parse),
/// );
///
/// ConvertConfig.configure(config);
/// final money = Convert.toType<Money>('42'); // Money(42)
/// ```
///
/// Parsers should throw to signal failure. The exception is wrapped in
/// [ConversionException] with full context.
@immutable
class TypeRegistry {
  /// Creates an empty registry with no custom parsers.
  const TypeRegistry.empty() : this._const(const {});

  const TypeRegistry._const(this._parsers);

  final Map<Type, dynamic Function(Object?)> _parsers;

  /// Returns a new registry with [parser] registered for type [T].
  ///
  /// The parser is invoked by `Convert.toType` when [T] is requested.
  /// Existing parsers in this registry are preserved; the new parser
  /// is added (or replaces an existing parser for the same type).
  TypeRegistry register<T>(T Function(Object?) parser) {
    final next = Map<Type, dynamic Function(Object?)>.from(_parsers);
    next[T] = parser;
    return TypeRegistry._const(next);
  }

  /// Merges this registry with [other], returning a new registry.
  ///
  /// Parsers in [other] take precedence over parsers in this registry for the same type.
  TypeRegistry merge(TypeRegistry other) {
    if (other._parsers.isEmpty) return this;
    final next = Map<Type, dynamic Function(Object?)>.from(_parsers)
      ..addAll(other._parsers);
    return TypeRegistry._const(next);
  }

  /// Attempts to parse [value] into [T] using a registered custom parser.
  ///
  /// Returns `null` if no parser is registered for [T] or if the parser itself returns `null`.
  T? tryParse<T>(Object? value) {
    final parser = _parsers[T] as T Function(Object?)?;
    return parser == null ? null : parser(value);
  }
}
