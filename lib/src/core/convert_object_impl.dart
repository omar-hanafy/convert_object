import 'dart:async';

import 'package:convert_object/src/config/convert_config.dart';
import 'package:convert_object/src/exceptions/conversion_exception.dart';
import 'package:convert_object/src/utils/dates.dart';
import 'package:convert_object/src/utils/json.dart';
import 'package:convert_object/src/utils/numbers.dart';
import 'package:convert_object/src/utils/uri.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

/// Signature for transforming a value pulled from a collection during
/// conversion.
typedef ElementConverter<T> = T Function(Object? element);

extension _NullableStringX on String? {
  bool get isNotBlank => this != null && this!.trim().isNotEmpty;
}

/// Implements the heavy lifting for the public `Convert` API.
///
/// The methods mirror the public facade but expose additional hooks used in
/// tests and error reporting.
abstract class ConvertObjectImpl {
  static final Expando<bool> _hooked = Expando<bool>(
    'convert_object_on_exception_called',
  );

  // Shared only for the synchronous construction of a collection. Failures
  // that escape that operation are handled at its public boundary.
  static Map<ConversionException, ExceptionHook>? _collectionHooks;

  static void _notify(ConversionException ex, ExceptionHook hook) {
    if (_hooked[ex] == true) return;
    _hooked[ex] = true;
    try {
      hook(ex);
    } catch (_) {}
  }

  static Never _fail(ConversionException ex) {
    final hook = ConvertConfig.effective.onException;
    if (hook != null) {
      final pending = _collectionHooks;
      if (pending == null) {
        _notify(ex, hook);
      } else {
        pending.putIfAbsent(ex, () => Zone.current.bindUnaryCallback(hook));
      }
    }
    Error.throwWithStackTrace(ex, ex.stackTrace);
  }

  /// Aggregates metadata describing a conversion attempt for diagnostics.
  static Map<String, dynamic> buildContext({
    required String method,
    dynamic object,
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool? autoDetectFormat,
    bool? useCurrentLocale,
    bool? utc,
    dynamic defaultValue,
    dynamic converter,
    Type? targetType,
    Map<String, dynamic>? debugInfo,
  }) {
    final args = <String, dynamic>{
      'method': method,
      'object': object,
      'objectType': object?.runtimeType.toString(),
    };
    if (targetType != null) args['targetType'] = targetType.toString();
    if (mapKey != null) args['mapKey'] = mapKey;
    if (listIndex != null) args['listIndex'] = listIndex;
    if (format != null) args['format'] = format;
    if (locale != null) args['locale'] = locale;
    if (autoDetectFormat != null) args['autoDetectFormat'] = autoDetectFormat;
    if (useCurrentLocale != null) args['useCurrentLocale'] = useCurrentLocale;
    if (utc != null) args['utc'] = utc;
    if (defaultValue != null) args['defaultValue'] = defaultValue;
    if (converter != null) args['converter'] = converter.runtimeType.toString();
    if (debugInfo != null && debugInfo.isNotEmpty) args.addAll(debugInfo);
    return args;
  }

  @optionalTypeArgs
  static T? _convertObject<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool decodeInput = false,
    bool swallowConverterErrors = true,
    T Function(dynamic)? converter,
  }) {
    if (object == null) return null;
    // decode input if requested
    if (decodeInput && object is String) {
      final decoded = object.tryDecode();
      if (!identical(decoded, object)) {
        return _convertObject<T>(
          decoded,
          mapKey: mapKey,
          listIndex: listIndex,
          decodeInput: decodeInput,
          swallowConverterErrors: swallowConverterErrors,
          converter: converter,
        );
      }
    }

    // List index
    if (listIndex != null && object is List) {
      Object? elem;
      try {
        elem = (listIndex >= 0 && listIndex < object.length)
            ? object[listIndex]
            : null;
      } catch (_) {
        return null;
      }
      return _convertObject<T>(
        elem,
        mapKey: mapKey,
        decodeInput: decodeInput,
        swallowConverterErrors: swallowConverterErrors,
        converter: converter,
      );
    }

    // Map key
    if (mapKey != null && object is Map) {
      Object? value;
      try {
        value = object[mapKey];
      } catch (_) {
        return null;
      }
      return _convertObject<T>(
        value,
        decodeInput: decodeInput,
        converter: converter,
        listIndex: listIndex,
        swallowConverterErrors: swallowConverterErrors,
      );
    }

    if (object is T) return object;
    try {
      return object as T;
    } catch (_) {}

    try {
      return converter?.call(object);
    } catch (e, s) {
      if (!swallowConverterErrors) {
        Error.throwWithStackTrace(e, s);
      }
      return null;
    }
  }

  // Primitives ---------------------------------------------------------

  /// Internal implementation for `Convert.toString`.
  static String string(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    String? data;
    try {
      data = _convertObject<String>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter: converter ?? ((o) => o.toString()),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'string',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'string',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      return _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToString`.
  static String? tryToString(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? defaultValue,
    ElementConverter<String>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<String>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: converter ?? ((o) => o.toString()),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toNum`.
  static num toNum(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    num? defaultValue,
    ElementConverter<num>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final numbersCfg = config.numbers;
    final effFormat = format.isNotBlank ? format : numbersCfg.defaultFormat;
    final effLocale = locale ?? numbersCfg.defaultLocale ?? config.locale;
    final tryFormattedFirst = numbersCfg.tryFormattedFirst;
    num? data;
    try {
      data = _convertObject<num>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter:
            converter ??
            ((o) {
              final text = '$o';
              if (effFormat != null && tryFormattedFirst) {
                final formatted = text.tryToNumFormatted(effFormat, effLocale);
                if (formatted != null) return formatted;
              }
              try {
                final plain = text.toNum();
                if (effFormat != null && !tryFormattedFirst) {
                  final formatted = text.tryToNumFormatted(
                    effFormat,
                    effLocale,
                  );
                  return formatted ?? plain;
                }
                return plain;
              } catch (_) {
                if (effFormat != null) {
                  return text.toNumFormatted(effFormat, effLocale);
                }
                rethrow;
              }
            }),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toNum',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toNum',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      return _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToNum`.
  static num? tryToNum(
    dynamic object, {
    dynamic mapKey,
    String? format,
    String? locale,
    int? listIndex,
    num? defaultValue,
    ElementConverter<num>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final numbersCfg = config.numbers;
    final effFormat = format.isNotBlank ? format : numbersCfg.defaultFormat;
    final effLocale = locale ?? numbersCfg.defaultLocale ?? config.locale;
    final tryFormattedFirst = numbersCfg.tryFormattedFirst;
    return _convertObject<num?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter:
              converter ??
              ((o) {
                final text = '$o';
                if (effFormat != null && tryFormattedFirst) {
                  final formatted = text.tryToNumFormatted(
                    effFormat,
                    effLocale,
                  );
                  if (formatted != null) return formatted;
                }
                final plain = text.tryToNum();
                if (plain != null) {
                  if (effFormat != null && !tryFormattedFirst) {
                    final formatted = text.tryToNumFormatted(
                      effFormat,
                      effLocale,
                    );
                    return formatted ?? plain;
                  }
                  return plain;
                }
                if (effFormat != null) {
                  return text.tryToNumFormatted(effFormat, effLocale);
                }
                return null;
              }),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toInt`.
  static int toInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    int? defaultValue,
    ElementConverter<int>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final numbersCfg = config.numbers;
    final effFormat = format.isNotBlank ? format : numbersCfg.defaultFormat;
    final effLocale = locale ?? numbersCfg.defaultLocale ?? config.locale;
    final tryFormattedFirst = numbersCfg.tryFormattedFirst;
    int? data;
    try {
      data = _convertObject<int>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter:
            converter ??
            ((o) {
              if (o is num) {
                return o.toInt();
              }
              final text = '$o';
              if (effFormat != null && tryFormattedFirst) {
                final formatted = text.tryToIntFormatted(effFormat, effLocale);
                if (formatted != null) return formatted;
              }
              try {
                final plain = text.toInt();
                if (effFormat != null && !tryFormattedFirst) {
                  final formatted = text.tryToIntFormatted(
                    effFormat,
                    effLocale,
                  );
                  return formatted ?? plain;
                }
                return plain;
              } catch (_) {
                if (effFormat != null) {
                  return text.toIntFormatted(effFormat, effLocale);
                }
                rethrow;
              }
            }),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toInt',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toInt',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToInt`.
  static int? tryToInt(
    dynamic object, {
    dynamic mapKey,
    String? format,
    String? locale,
    int? listIndex,
    int? defaultValue,
    ElementConverter<int>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final numbersCfg = config.numbers;
    final effFormat = format.isNotBlank ? format : numbersCfg.defaultFormat;
    final effLocale = locale ?? numbersCfg.defaultLocale ?? config.locale;
    final tryFormattedFirst = numbersCfg.tryFormattedFirst;
    return _convertObject<int?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter:
              converter ??
              ((o) {
                if (o is num) {
                  return o.toInt();
                }
                final text = '$o';
                if (effFormat != null && tryFormattedFirst) {
                  final formatted = text.tryToIntFormatted(
                    effFormat,
                    effLocale,
                  );
                  if (formatted != null) return formatted;
                }
                final plain = text.tryToInt();
                if (plain != null) {
                  if (effFormat != null && !tryFormattedFirst) {
                    final formatted = text.tryToIntFormatted(
                      effFormat,
                      effLocale,
                    );
                    return formatted ?? plain;
                  }
                  return plain;
                }
                if (effFormat != null) {
                  return text.tryToIntFormatted(effFormat, effLocale);
                }
                return null;
              }),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toBigInt`.
  static BigInt toBigInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    BigInt? data;
    try {
      data = _convertObject<BigInt>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter:
            converter ??
            ((o) {
              if (o is BigInt) return o;
              if (o is num) return BigInt.from(o);
              return BigInt.parse('$o');
            }),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toBigInt',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toBigInt',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToBigInt`.
  static BigInt? tryToBigInt(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    BigInt? defaultValue,
    ElementConverter<BigInt>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<BigInt?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter:
              converter ??
              ((o) {
                if (o is BigInt) return o;
                if (o is num) return BigInt.from(o);
                return BigInt.tryParse('$o');
              }),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toDouble`.
  static double toDouble(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final numbersCfg = config.numbers;
    final effFormat = format.isNotBlank ? format : numbersCfg.defaultFormat;
    final effLocale = locale ?? numbersCfg.defaultLocale ?? config.locale;
    final tryFormattedFirst = numbersCfg.tryFormattedFirst;
    double? data;
    try {
      data = _convertObject<double>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter:
            converter ??
            ((o) {
              if (o is num) {
                return o.toDouble();
              }
              final text = '$o';
              if (effFormat != null && tryFormattedFirst) {
                final formatted = text.tryToDoubleFormatted(
                  effFormat,
                  effLocale,
                );
                if (formatted != null) return formatted;
              }
              try {
                final plain = text.toDouble();
                if (effFormat != null && !tryFormattedFirst) {
                  final formatted = text.tryToDoubleFormatted(
                    effFormat,
                    effLocale,
                  );
                  return formatted ?? plain;
                }
                return plain;
              } catch (_) {
                if (effFormat != null) {
                  return text.toDoubleFormatted(effFormat, effLocale);
                }
                rethrow;
              }
            }),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toDouble',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toDouble',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToDouble`.
  static double? tryToDouble(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    double? defaultValue,
    ElementConverter<double>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final numbersCfg = config.numbers;
    final effFormat = format.isNotBlank ? format : numbersCfg.defaultFormat;
    final effLocale = locale ?? numbersCfg.defaultLocale ?? config.locale;
    final tryFormattedFirst = numbersCfg.tryFormattedFirst;
    return _convertObject<double?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter:
              converter ??
              ((o) {
                if (o is num) {
                  return o.toDouble();
                }
                final text = '$o';
                if (effFormat != null && tryFormattedFirst) {
                  final formatted = text.tryToDoubleFormatted(
                    effFormat,
                    effLocale,
                  );
                  if (formatted != null) return formatted;
                }
                final plain = text.tryToDouble();
                if (plain != null) {
                  if (effFormat != null && !tryFormattedFirst) {
                    final formatted = text.tryToDoubleFormatted(
                      effFormat,
                      effLocale,
                    );
                    return formatted ?? plain;
                  }
                  return plain;
                }
                if (effFormat != null) {
                  return text.tryToDoubleFormatted(effFormat, effLocale);
                }
                return null;
              }),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toBool`.
  static bool toBool(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    final data = _convertObject<bool?>(
      object,
      mapKey: mapKey,
      listIndex: listIndex,
      converter: converter ?? ((o) => _parseBool(o, config.bools)),
    );
    return data ?? defaultValue ?? false;
  }

  /// Internal implementation for `Convert.tryToBool`.
  static bool? tryToBool(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    bool? defaultValue,
    ElementConverter<bool>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final config = ConvertConfig.effective;
    return _convertObject<bool?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: converter ?? ((o) => _parseBool(o, config.bools)),
        ) ??
        defaultValue;
  }

  static ElementConverter<DateTime> _dateTimeParser({
    required String? format,
    required String? locale,
    required bool autoDetectFormat,
    required bool useCurrentLocale,
    required bool utc,
    required ElementConverter<DateTime>? converter,
  }) {
    final config = ConvertConfig.effective;
    final options = config.dates;
    final pattern = format ?? options.defaultFormat;
    final dateLocale = locale ?? options.locale ?? config.locale;
    final autoDetect = autoDetectFormat || options.autoDetectFormat;
    final useIntlLocale = useCurrentLocale || options.useCurrentLocale;
    final asUtc = utc || options.utc;
    final extraPatterns = options.extraAutoDetectPatterns;

    if (converter != null) return converter;
    return (value) {
      if (value is num) {
        final timestamp = value.toInt();
        // Comparing signed bounds avoids overflowing abs() for the minimum int.
        const threshold = 100000000000;
        final milliseconds = timestamp > -threshold && timestamp < threshold
            ? timestamp * Duration.millisecondsPerSecond
            : timestamp;
        return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: asUtc);
      }
      // Extra patterns can include literal whitespace at either end.
      final text = '$value';
      if (pattern != null) {
        return text.toDateFormatted(pattern, dateLocale, utc: asUtc);
      }
      if (autoDetect) {
        if (extraPatterns.isNotEmpty) {
          // Match literal whitespace first, then allow padding around the input.
          final inputs = {text, text.trimRight(), text.trimLeft(), text.trim()};
          for (final input in inputs) {
            for (final extraPattern in extraPatterns) {
              try {
                return DateFormat(
                  extraPattern,
                  dateLocale,
                ).parseStrict(input, asUtc);
              } catch (_) {
                continue;
              }
            }
          }
        }
        return text.toDateAutoFormat(
          locale: dateLocale,
          useCurrentLocale: useIntlLocale,
          utc: asUtc,
        );
      }
      final parsed = text.toDateTime();
      return asUtc ? parsed.toUtc() : parsed;
    };
  }

  /// Internal implementation for `Convert.toDateTime`.
  static DateTime toDateTime(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    // Configuration failures belong to the caller's route. Only conversion
    // of the selected value uses the date-specific error and default below.
    final parse = _dateTimeParser(
      format: format,
      locale: locale,
      autoDetectFormat: autoDetectFormat,
      useCurrentLocale: useCurrentLocale,
      utc: utc,
      converter: converter,
    );
    DateTime? data;
    try {
      data = _convertObject<DateTime>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter: parse,
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toDateTime',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          autoDetectFormat: autoDetectFormat,
          useCurrentLocale: useCurrentLocale,
          utc: utc,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toDateTime',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          format: format,
          locale: locale,
          autoDetectFormat: autoDetectFormat,
          useCurrentLocale: useCurrentLocale,
          utc: utc,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToDateTime`.
  static DateTime? tryToDateTime(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    String? format,
    String? locale,
    bool autoDetectFormat = false,
    bool useCurrentLocale = false,
    bool utc = false,
    DateTime? defaultValue,
    ElementConverter<DateTime>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<DateTime?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: _dateTimeParser(
            format: format,
            locale: locale,
            autoDetectFormat: autoDetectFormat,
            useCurrentLocale: useCurrentLocale,
            utc: utc,
            converter: converter,
          ),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toUri`.
  static Uri toUri(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final policy = ConvertConfig.effective.uri;
    Uri? data;
    try {
      data = _convertObject<Uri>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter:
            converter ??
            ((o) {
              final s = o.toString();
              if (s.isValidPhoneNumber) return s.toPhoneUri;
              if (s.isEmailAddress) return s.toMailUri;
              return _parseUriWithPolicy(s, policy);
            }),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toUri',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toUri',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: converter,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToUri`.
  static Uri? tryToUri(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Uri? defaultValue,
    ElementConverter<Uri>? converter,
    Map<String, dynamic>? debugInfo,
  }) {
    final policy = ConvertConfig.effective.uri;
    return _convertObject<Uri?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter:
              converter ??
              ((o) {
                final s = o.toString();
                if (s.isValidPhoneNumber) return s.toPhoneUri;
                if (s.isEmailAddress) return s.toMailUri;
                return _parseUriWithPolicy(s, policy);
              }),
        ) ??
        defaultValue;
  }

  // Enums -------------------------------------------------------------

  /// Internal implementation for `Convert.toEnum`.
  @optionalTypeArgs
  static T toEnum<T extends Enum>(
    dynamic object, {
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) {
    T? data;
    try {
      data = _convertObject<T>(
        object,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter: parser,
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toEnum<$T>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: parser,
          targetType: T,
          debugInfo: {
            ...?debugInfo,
            'reason': 'enum parse failed',
            'enumType': T.toString(),
          },
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toEnum<$T>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: parser,
          targetType: T,
          debugInfo: {
            ...?debugInfo,
            'reason': 'enum parse failed',
            'enumType': T.toString(),
          },
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToEnum`.
  @optionalTypeArgs
  static T? tryToEnum<T extends Enum>(
    dynamic object, {
    required T Function(dynamic) parser,
    dynamic mapKey,
    int? listIndex,
    T? defaultValue,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<T?>(
          object,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: parser,
        ) ??
        defaultValue;
  }

  // Collections --------------------------------------------------------

  static R _withCollectionHooks<R>(R Function() convert) {
    final outer = _collectionHooks;
    final pending = Map<ConversionException, ExceptionHook>.identity();
    _collectionHooks = pending;
    try {
      return convert();
    } on ConversionException catch (e) {
      pending.remove(e);
      rethrow;
    } finally {
      _collectionHooks = outer;
      pending.forEach(_notify);
    }
  }

  static Map<K, V> _mapEntries<K, V>(
    Object? value,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
  ) => _withCollectionHooks(() {
    final map = value as Map<Object?, Object?>;
    if (map.isEmpty) return <K, V>{};
    return map.map(
      (key, value) => MapEntry(
        keyConverter == null ? key as K : keyConverter(key),
        valueConverter == null ? value as V : valueConverter(value),
      ),
    );
  });

  static void _addElements<T>(
    Iterable<Object?> values,
    void Function(T) add,
    ElementConverter<T>? converter,
    Map<String, dynamic> Function(int?)? elementContext,
  ) {
    var index = 0;
    Iterator<Object?>? iterator;
    try {
      iterator = values.iterator;
      while (iterator.moveNext()) {
        final value = iterator.current;
        add(converter == null ? toType<T>(value) : converter(value));
        index++;
      }
    } catch (e, s) {
      if (elementContext == null) rethrow;
      if (e is ConversionException) _collectionHooks?.remove(e);
      final trace = e is ConversionException ? e.stackTrace : s;
      final ex = ConversionException(
        error: e is ConversionException ? e.error : e,
        context: elementContext(iterator == null ? null : index),
        stackTrace: trace,
      );
      Error.throwWithStackTrace(ex, trace);
    }
  }

  static Set<T> _setFrom<T>(
    Object? value,
    ElementConverter<T>? converter, {
    Map<String, dynamic> Function(int?)? elementContext,
  }) => _withCollectionHooks(() {
    if (value is T) {
      if (value is Iterable<Object?> && value.isEmpty) return <T>{};
      return <T>{value};
    }
    final values = value is Map<Object?, Object?>
        ? value.values
        : value as Iterable<Object?>;
    final result = <T>{};
    _addElements<T>(values, result.add, converter, elementContext);
    return result;
  });

  static List<T>? _listFrom<T>(
    Object? value,
    ElementConverter<T>? converter, {
    bool convertScalar = false,
    Map<String, dynamic> Function(int?)? elementContext,
  }) => _withCollectionHooks(() {
    if (value is T) {
      if (value is Iterable<Object?> && value.isEmpty) return <T>[];
      return <T>[value];
    }
    final values = value is Map<Object?, Object?> ? value.values : value;
    if (values is Iterable<Object?>) {
      final result = <T>[];
      _addElements<T>(values, result.add, converter, elementContext);
      return result;
    }
    return convertScalar ? <T>[toType<T>(value)] : null;
  });

  /// Internal implementation for `Convert.toMap`.
  @optionalTypeArgs
  static Map<K, V> toMap<K, V>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
    Map<String, dynamic>? debugInfo,
  }) {
    Map<K, V>? data;
    try {
      data = _convertObject<Map<K, V>>(
        object,
        decodeInput: true,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter: (o) => _mapEntries<K, V>(o, keyConverter, valueConverter),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toMap<$K, $V>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: keyConverter != null || valueConverter != null
              ? 'custom'
              : null,
          targetType: Map<K, V>,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toMap<$K, $V>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: keyConverter != null || valueConverter != null
              ? 'custom'
              : null,
          targetType: Map<K, V>,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToMap`.
  @optionalTypeArgs
  static Map<K, V>? tryToMap<K, V>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Map<K, V>? defaultValue,
    ElementConverter<K>? keyConverter,
    ElementConverter<V>? valueConverter,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<Map<K, V>?>(
          object,
          decodeInput: true,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: (o) => _mapEntries<K, V>(o, keyConverter, valueConverter),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toSet`.
  @optionalTypeArgs
  static Set<T> toSet<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
    Map<String, dynamic>? debugInfo,
  }) {
    Set<T>? data;
    try {
      data = _convertObject<Set<T>>(
        object,
        decodeInput: true,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter: (o) => _setFrom<T>(
          o,
          elementConverter,
          elementContext: (index) => buildContext(
            method: 'toSet<$T>',
            object: object,
            mapKey: mapKey,
            listIndex: listIndex,
            defaultValue: defaultValue,
            converter: elementConverter,
            targetType: Set<T>,
            debugInfo: {...?debugInfo, 'elementIndex': ?index},
          ),
        ),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toSet<$T>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: elementConverter,
          targetType: Set<T>,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toSet<$T>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: elementConverter,
          targetType: Set<T>,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToSet`.
  @optionalTypeArgs
  static Set<T>? tryToSet<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    Set<T>? defaultValue,
    ElementConverter<T>? elementConverter,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<Set<T>?>(
          object,
          decodeInput: true,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: (o) => _setFrom<T>(o, elementConverter),
        ) ??
        defaultValue;
  }

  /// Internal implementation for `Convert.toList`.
  @optionalTypeArgs
  static List<T> toList<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
    Map<String, dynamic>? debugInfo,
  }) {
    List<T>? data;
    try {
      data = _convertObject<List<T>?>(
        object,
        decodeInput: true,
        mapKey: mapKey,
        listIndex: listIndex,
        swallowConverterErrors: false,
        converter: (o) => _listFrom<T>(
          o,
          elementConverter,
          convertScalar: true,
          elementContext: (index) => buildContext(
            method: 'toList<$T>',
            object: object,
            mapKey: mapKey,
            listIndex: listIndex,
            defaultValue: defaultValue,
            converter: elementConverter,
            targetType: List<T>,
            debugInfo: {...?debugInfo, 'elementIndex': ?index},
          ),
        ),
      );
    } on ConversionException catch (e) {
      if (defaultValue != null) return defaultValue;
      return _fail(e);
    } catch (e, s) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException(
        error: e,
        context: buildContext(
          method: 'toList<$T>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: elementConverter,
          targetType: List<T>,
          debugInfo: debugInfo,
        ),
        stackTrace: s,
      );
      return _fail(ex);
    }
    if (data == null) {
      if (defaultValue != null) return defaultValue;
      final ex = ConversionException.nullObject(
        context: buildContext(
          method: 'toList<$T>',
          object: object,
          mapKey: mapKey,
          listIndex: listIndex,
          defaultValue: defaultValue,
          converter: elementConverter,
          targetType: List<T>,
          debugInfo: debugInfo,
        ),
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    return data;
  }

  /// Internal implementation for `Convert.tryToList`.
  @optionalTypeArgs
  static List<T>? tryToList<T>(
    dynamic object, {
    dynamic mapKey,
    int? listIndex,
    List<T>? defaultValue,
    ElementConverter<T>? elementConverter,
    Map<String, dynamic>? debugInfo,
  }) {
    return _convertObject<List<T>?>(
          object,
          decodeInput: true,
          mapKey: mapKey,
          listIndex: listIndex,
          converter: (o) => _listFrom<T>(o, elementConverter),
        ) ??
        defaultValue;
  }

  // Top-level generic routing ----------------------------------------

  /// Internal implementation for `Convert.toType`.
  @optionalTypeArgs
  static T toType<T>(dynamic object) {
    if (object is T) return object;
    if (object == null) {
      final ex = ConversionException.nullObject(
        context: {
          'method': 'toType<$T>',
          'object': object,
          'objectType': 'null',
          'targetType': '$T',
        },
        stackTrace: StackTrace.current,
      );
      _fail(ex);
    }
    final config = ConvertConfig.effective;
    final custom = config.registry.tryParse<T>(object);
    if (custom != null) {
      return custom;
    }
    try {
      if (T == bool) return ConvertObjectImpl.toBool(object) as T;
      if (T == int) return ConvertObjectImpl.toInt(object) as T;
      if (T == double) return ConvertObjectImpl.toDouble(object) as T;
      if (T == num) return ConvertObjectImpl.toNum(object) as T;
      if (T == BigInt) return ConvertObjectImpl.toBigInt(object) as T;
      if (T == String) return ConvertObjectImpl.string(object) as T;
      if (T == DateTime) return ConvertObjectImpl.toDateTime(object) as T;
      if (T == Uri) return ConvertObjectImpl.toUri(object) as T;
    } on ConversionException catch (e) {
      return _fail(e);
    } catch (e, s) {
      final ex = ConversionException(
        error: e,
        context: {
          'method': 'toType<$T>',
          'object': object,
          'objectType': object.runtimeType.toString(),
          'targetType': '$T',
        },
        stackTrace: s,
      );
      _fail(ex);
    }
    try {
      return object as T;
    } catch (_) {}
    final ex = ConversionException(
      error:
          'Unsupported type detected. Please ensure that the type you are attempting to convert to is either a primitive type or a valid data type: $T.',
      context: {
        'method': 'toType<$T>',
        'object': object,
        'objectType': object.runtimeType.toString(),
        'targetType': '$T',
      },
      stackTrace: StackTrace.current,
    );
    return _fail(ex);
  }

  /// Internal implementation for `Convert.tryToType`.
  @optionalTypeArgs
  static T? tryToType<T>(dynamic object) {
    if (object is T) return object;
    if (object == null) return null;
    final config = ConvertConfig.effective;
    final custom = config.registry.tryParse<T>(object);
    if (custom != null) {
      return custom;
    }
    try {
      if (T == bool) return ConvertObjectImpl.tryToBool(object) as T?;
      if (T == int) return ConvertObjectImpl.tryToInt(object) as T?;
      if (T == BigInt) return ConvertObjectImpl.tryToBigInt(object) as T?;
      if (T == double) return ConvertObjectImpl.tryToDouble(object) as T?;
      if (T == num) return ConvertObjectImpl.tryToNum(object) as T?;
      if (T == String) {
        return ConvertObjectImpl.tryToString(object) as T?;
      }
      if (T == DateTime) return ConvertObjectImpl.tryToDateTime(object) as T?;
      if (T == Uri) return ConvertObjectImpl.tryToUri(object) as T?;
    } on ConversionException {
      return null;
    }
    try {
      return object as T;
    } catch (_) {}
    return null;
  }

  static bool? _parseBool(Object? value, BoolOptions options) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) {
      return options.numericPositiveIsTrue ? value > 0 : value != 0;
    }
    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) return null;
    final numeric = num.tryParse(text);
    if (numeric != null) {
      return options.numericPositiveIsTrue ? numeric > 0 : numeric != 0;
    }
    if (options.truthy.contains(text)) return true;
    if (options.falsy.contains(text)) return false;
    return null;
  }

  static Uri _parseUriWithPolicy(String input, UriOptions policy) {
    final raw = input.trim();
    if (raw.isEmpty) {
      throw const FormatException('Failed to parse URI: empty input', '');
    }
    Uri candidate;
    final parsed = Uri.parse(raw);
    if (parsed.scheme.isEmpty) {
      final looksLikeDomain = raw.contains('.') && !raw.contains(' ');
      if (looksLikeDomain &&
          policy.coerceBareDomainsToDefaultScheme &&
          policy.defaultScheme != null) {
        candidate = Uri.parse('${policy.defaultScheme}://$raw');
      } else {
        candidate = parsed;
      }
    } else {
      candidate = parsed;
    }
    final scheme = candidate.scheme.toLowerCase();
    if (!policy.allowRelative &&
        (scheme.isEmpty ||
            ((scheme == 'http' || scheme == 'https') &&
                candidate.host.isEmpty))) {
      throw FormatException(
        'Failed to parse URI: invalid or relative URI for current policy',
        raw,
      );
    }
    if ((scheme == 'http' || scheme == 'https') && candidate.host.isEmpty) {
      throw FormatException(
        'Failed to parse URI: missing host for scheme "$scheme"',
        raw,
      );
    }
    if ((scheme == 'mailto' || scheme == 'tel') &&
        candidate.path.trim().isEmpty) {
      throw FormatException(
        'Failed to parse URI: missing path for scheme "$scheme"',
        raw,
      );
    }
    return candidate;
  }
}
