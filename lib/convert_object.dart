/// A comprehensive type conversion library for Dart that handles the messy
/// realities of dynamic data from APIs, databases, and user input.
///
/// This library provides a fluent API for converting between primitive types,
/// collections, enums, and dates - with extensive support for locale-aware
/// formatting, custom converters, and graceful error handling.
///
/// ### Core Entry Points
///
/// * [Convert] - Static facade for all conversion methods (e.g., `Convert.toInt()`).
/// * [Converter] - Fluent wrapper for chained conversions (e.g., `value.convert.toInt()`).
/// * Top-level functions - Convenience aliases like [convertToInt], [tryConvertToString].
///
/// ### Configuration
///
/// Use [ConvertConfig] to customize parsing behavior globally or per-scope:
/// * [NumberOptions] - Locale-aware number formatting.
/// * [DateOptions] - Date parsing with auto-detection and custom patterns.
/// * [BoolOptions] - Configurable truthy/falsy string tokens.
/// * [UriOptions] - URI coercion and validation policies.
/// * [TypeRegistry] - Register custom parsers for application-specific types.
///
/// ### Error Handling
///
/// All `toX` methods throw [ConversionException] on failure with rich context.
/// Use `tryToX` variants for null-returning, exception-free alternatives.
///
/// See also:
/// * [ConversionResult] for monadic success/failure handling.
/// * [EnumParsers] for resilient enum parsing callbacks.
library;

export 'src/config/convert_config.dart'
    show
        BoolOptions,
        ConvertConfig,
        DateOptions,
        NumberOptions,
        TypeRegistry,
        UriOptions;
export 'src/core/convert_object.dart' show Convert, ElementConverter;
export 'src/core/converter.dart' show Converter, DynamicConverter;
export 'src/core/enum_parsers.dart' show EnumParsers, EnumValuesParsing;
export 'src/exceptions/conversion_exception.dart' show ConversionException;
export 'src/extensions/iterable_extensions.dart';
export 'src/extensions/let_extensions.dart';
export 'src/extensions/map_extensions.dart';
export 'src/extensions/object_convert_extension.dart';
export 'src/result/conversion_result.dart' show ConversionResult;
export 'src/top_level_functions.dart';
export 'src/utils/bools.dart';
export 'src/utils/dates.dart';
export 'src/utils/json.dart';
export 'src/utils/map_pretty.dart';
export 'src/utils/numbers.dart';
export 'src/utils/uri.dart';
