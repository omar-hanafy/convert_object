import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../helpers/fixtures.dart';

void main() {
  late ConvertConfig prev;

  setUp(() {
    // Arrange
    prev = Convert.configure(makeTestConfig(locale: 'en_US'));
  });

  tearDown(() {
    // Arrange
    Convert.configure(prev);
  });

  group('Object?.convert', () {
    test('should return null when calling tryToInt on a null receiver', () {
      // Arrange
      final Object? value = null;

      // Act
      final result = value.convert.tryToInt();

      // Assert
      expect(result, isNull);
    });

    test('should read a value from a Map and convert it via fluent chaining',
        () {
      // Arrange
      final map = kNestedMap;

      // Act
      final result = map.convert.fromMap('id').toInt();

      // Assert
      expect(result, isA<int>());
      expect(result, equals(42));
    });

    test(
        'should read nested values from a JSON-string map using fromMap chaining',
        () {
      // Arrange
      const json = kNestedMapJson;

      // Act
      final result = json.convert.fromMap('meta').fromMap('age').toInt();

      // Assert
      expect(result, equals(30));
    });

    test(
        'should decode JSON using .decoded and then navigate like a normal Map',
        () {
      // Arrange
      const json = kNestedMapJson;

      // Act
      final lat = json.convert.decoded
          .fromMap('meta')
          .fromMap('coords')
          .fromMap('lat')
          .toDouble();

      // Assert
      expect(lat, isA<double>());
      expect(lat, equals(30.0444));
    });

    test(
        'should read from a JSON-string list using fromList and convert the value',
        () {
      // Arrange
      const jsonList = kJsonList;

      // Act
      final result = jsonList.convert.fromList(3).toInt();

      // Assert
      expect(result, equals(4));
    });
  });
}
