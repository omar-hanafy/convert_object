import 'dart:async';

import 'package:convert_object/src/exceptions/conversion_exception.dart';
import 'package:meta/meta.dart';

/// Signature for a callback that is invoked when a conversion fails.
///
/// If [ConvertConfig.onException] is provided, the hook is called with the
/// thrown [ConversionException] just before it is rethrown. Use this to log
/// errors or collect metrics; do not modify control flow.
typedef ExceptionHook = void Function(ConversionException error);

const Set<String> _kDefaultTruthy = {'true', '1', 'yes', 'y', 'on', 'ok', 't'};
const Set<String> _kDefaultFalsy = {'false', '0', 'no', 'n', 'off', 'f'};

const int _overrideLocale = 1 << 0;
const int _overrideNumbers = 1 << 1;
const int _overrideDates = 1 << 2;
const int _overrideBools = 1 << 3;
const int _overrideUri = 1 << 4;
const int _overrideRegistry = 1 << 5;
const int _overrideOnException = 1 << 6;

bool _hasOverride(int mask, int flag) => (mask & flag) != 0;

bool _setEquals(Set<String> a, Set<String> b) {
  if (a.length != b.length) return false;
  for (final value in a) {
    if (!b.contains(value)) return false;
  }
  return true;
}

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

/// Global and scoped configuration used by the `convert_object` APIs.
@immutable

///
/// A single global instance is used by default. You can:
///  * replace it via [configure],
///  * update it immutably via [update], or
///  * apply temporary overrides for a call tree via [runScoped].
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

  /// Default locale used by number/date parsing when no explicit locale is
  /// supplied at call sites or per-option.
  final String? locale;

  /// Numeric parsing/formatting behavior.
  final NumberOptions numbers;

  /// Date/time parsing behavior.
  final DateOptions dates;

  /// Boolean parsing behavior.
  final BoolOptions bools;

  /// URI parsing behavior.
  final UriOptions uri;

  /// Custom parsers that can handle additional types in `Convert.toType`.
  final TypeRegistry registry;

  /// Optional hook invoked whenever a [ConversionException] is thrown.
  final ExceptionHook? onException;

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
  }) =>
      ConvertConfig(
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

  ConvertConfig _merge(ConvertConfig overrides) {
    final onExceptionHook =
        _hasOverride(overrides._overrideMask, _overrideOnException)
            ? overrides.onException
            : overrides.onException ?? onException;

    final shouldMergeNumbers =
        _hasOverride(overrides._overrideMask, _overrideNumbers) ||
            !_isDefaultNumberOptions(overrides.numbers);
    final mergedNumbers =
        shouldMergeNumbers ? numbers.merge(overrides.numbers) : numbers;

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
    final mergedRegistry =
        shouldMergeRegistry ? registry.merge(overrides.registry) : registry;

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

  /// Default `NumberFormat` pattern to try when parsing formatted numbers.
  final String? defaultFormat;

  /// Default locale passed to `NumberFormat` when [defaultFormat] is used.
  final String? defaultLocale;

  /// If `true`, attempt formatted parsing before lenient plain parsing.
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
  }) =>
      NumberOptions(
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

  /// Default `intl` pattern to parse calendar-style inputs.
  final String? defaultFormat;

  /// Preferred locale used by date parsing when a format requires it.
  final String? locale;

  /// If `true`, treat parsed values as UTC and return UTC `DateTime`s.
  final bool utc;

  /// If `true`, attempt a series of known formats automatically.
  final bool autoDetectFormat;

  /// If `true`, fall back to the current process locale when needed.
  final bool useCurrentLocale;

  /// Additional patterns that [autoDetectFormat] should try first.
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
  }) =>
      DateOptions(
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

  /// Case-insensitive string tokens that should be treated as `true`.
  final Set<String> truthy;

  /// Case-insensitive string tokens that should be treated as `false`.
  final Set<String> falsy;

  /// If `true`, numeric values > 0 are considered `true` (else != 0).
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
  }) =>
      BoolOptions(
        truthy: truthy ?? this.truthy,
        falsy: falsy ?? this.falsy,
        numericPositiveIsTrue:
            numericPositiveIsTrue ?? this.numericPositiveIsTrue,
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

  /// Default scheme to apply to bare domains when coercion is enabled.
  final String? defaultScheme;

  /// If `true`, add [defaultScheme] to inputs like `example.com`.
  final bool coerceBareDomainsToDefaultScheme;

  /// If `false`, reject relative URIs.
  final bool allowRelative;

  /// Returns a new [UriOptions] that prefers [other]'s settings.
  UriOptions merge(UriOptions other) => UriOptions(
        defaultScheme: other.defaultScheme ?? defaultScheme,
        coerceBareDomainsToDefaultScheme:
            other.coerceBareDomainsToDefaultScheme,
        allowRelative: other.allowRelative,
      );

  /// Returns a copy with selected fields replaced.
  UriOptions copyWith({
    String? defaultScheme,
    bool? coerceBareDomainsToDefaultScheme,
    bool? allowRelative,
  }) =>
      UriOptions(
        defaultScheme: defaultScheme ?? this.defaultScheme,
        coerceBareDomainsToDefaultScheme: coerceBareDomainsToDefaultScheme ??
            this.coerceBareDomainsToDefaultScheme,
        allowRelative: allowRelative ?? this.allowRelative,
      );
}

/// Registry of custom parsers used by `Convert.toType` / `Convert.tryToType`.
@immutable
class TypeRegistry {
  /// Creates an empty registry (no custom parsers).
  const TypeRegistry.empty() : this._const(const {});

  const TypeRegistry._const(this._parsers);

  final Map<Type, dynamic Function(Object?)> _parsers;

  /// Returns a new registry registering [parser] for type [T].
  TypeRegistry register<T>(T Function(Object?) parser) {
    final next = Map<Type, dynamic Function(Object?)>.from(_parsers);
    next[T] = parser;
    return TypeRegistry._const(next);
  }

  /// Combines this registry with [other], with [other] taking precedence.
  TypeRegistry merge(TypeRegistry other) {
    if (other._parsers.isEmpty) return this;
    final next = Map<Type, dynamic Function(Object?)>.from(_parsers)
      ..addAll(other._parsers);
    return TypeRegistry._const(next);
  }

  /// Attempts to parse [value] into [T] using a registered parser, returning
  /// `null` when no parser exists or the parser returns `null`.
  T? tryParse<T>(Object? value) {
    final parser = _parsers[T] as T Function(Object?)?;
    return parser == null ? null : parser(value);
  }
}
