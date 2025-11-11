/// A comprehensive type conversion library for Dart.
///
/// This library provides a fluent API for converting between different types
/// with extensive support for collections, custom converters, and safe conversions.
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
