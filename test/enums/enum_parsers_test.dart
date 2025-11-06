import 'package:convert_object/convert_object.dart';
import 'package:test/test.dart';

import '../_setup/test_config.dart';

enum Pet { cat, dog, fish }

void main() {
  configureTests(defaultLocale: 'en_US');

  group('EnumParsers', () {
    test('byName parses exact name', () {
      final parse = EnumParsers.byName(Pet.values);
      expect(parse('dog'), Pet.dog);
      expect(parse('cat'), Pet.cat);
    });

    test('byName throws on invalid', () {
      final parse = EnumParsers.byName(Pet.values);
      expect(() => parse('unknown'), throwsA(isA<StateError>()));
    });

    test('byNameCaseInsensitive parses regardless of case', () {
      final parse = EnumParsers.byNameCaseInsensitive(Pet.values);
      expect(parse('DoG'), Pet.dog);
      expect(parse(' FISH '), Pet.fish);
    });

    test('byNameCaseInsensitive throws ArgumentError on invalid', () {
      final parse = EnumParsers.byNameCaseInsensitive(Pet.values);
      expect(() => parse('???'), throwsA(isA<ArgumentError>()));
    });

    test('byNameOrFallback returns fallback on invalid', () {
      final parse = EnumParsers.byNameOrFallback(Pet.values, Pet.cat);
      expect(parse('dog'), Pet.dog);
      expect(parse('not-a-pet'), Pet.cat);
    });

    test('byIndex parses numeric input (string or number)', () {
      final parse = EnumParsers.byIndex(Pet.values);
      expect(parse('0'), Pet.cat);
      expect(parse(1), Pet.dog);
      expect(parse(2.0), Pet.fish); // via toInt under the hood
    });

    test('byIndex throws on out-of-range', () {
      final parse = EnumParsers.byIndex(Pet.values);
      expect(() => parse(-1), throwsA(isA<ArgumentError>()));
      expect(() => parse(99), throwsA(isA<ArgumentError>()));
    });

    test('fromString delegates to user-provided factory', () {
      // Example aliased inputs
      Pet fromAlias(String s) {
        switch (s.trim().toLowerCase()) {
          case 'c':
          case 'kitty':
            return Pet.cat;
          case 'd':
          case 'puppy':
            return Pet.dog;
          case 'f':
            return Pet.fish;
          default:
            throw ArgumentError('No mapping for $s');
        }
      }

      final parse = EnumParsers.fromString(fromAlias);
      expect(parse('kitty'), Pet.cat);
      expect(parse('D'), Pet.dog);
      expect(() => parse('???'), throwsA(isA<ArgumentError>()));
    });
  });

  group('EnumValuesParsing extension helpers', () {
    test('parser (byName) works', () {
      final parse = Pet.values.parser;
      expect(parse('fish'), Pet.fish);
    });

    test('parserWithFallback works', () {
      final parse = Pet.values.parserWithFallback(Pet.cat);
      expect(parse('DOG'), Pet.cat,
          reason: 'byName without CI should throw; fallback used');
    });

    test('parserCaseInsensitive works', () {
      final parse = Pet.values.parserCaseInsensitive;
      expect(parse('DoG'), Pet.dog);
    });

    test('parserByIndex works', () {
      final parse = Pet.values.parserByIndex;
      expect(parse(2), Pet.fish);
    });
  });
}
