import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('Z.coerce.integer', () {
    test('passes through int', () {
      final schema = Z.coerce.integer();
      final result = schema.safeParse(42);

      expect(result.$1, equals(42));
      expect(result.$2, isNull);
    });

    test('coerces string to int', () {
      final schema = Z.coerce.integer();

      expect(schema.safeParse('123').$1, equals(123));
      expect(schema.safeParse('  456  ').$1, equals(456));
      expect(schema.safeParse('-789').$1, equals(-789));
    });

    test('coerces double to int if whole number', () {
      final schema = Z.coerce.integer();

      expect(schema.safeParse(42.0).$1, equals(42));
      expect(schema.safeParse(-10.0).$1, equals(-10));
    });

    test('rejects double with decimal', () {
      final schema = Z.coerce.integer();

      expect(schema.safeParse(3.14).$2, isNotNull);
      expect(schema.safeParse(3.14).$2!.first.code, equals('invalid_coercion'));
    });

    test('rejects invalid string', () {
      final schema = Z.coerce.integer();

      expect(schema.safeParse('not a number').$2, isNotNull);
      expect(schema.safeParse('12.34').$2, isNotNull);
    });

    test('validates range after coercion', () {
      final schema = Z.coerce.integer(min: 0, max: 100);

      expect(schema.safeParse('50').$2, isNull);
      expect(schema.safeParse('-10').$2, isNotNull);
      expect(schema.safeParse('200').$2, isNotNull);
    });
  });

  group('Z.coerce.boolean', () {
    test('passes through boolean', () {
      final schema = Z.coerce.boolean();

      expect(schema.safeParse(true).$1, isTrue);
      expect(schema.safeParse(false).$1, isFalse);
    });

    test('coerces string to boolean', () {
      final schema = Z.coerce.boolean();

      // True values
      expect(schema.safeParse('true').$1, isTrue);
      expect(schema.safeParse('TRUE').$1, isTrue);
      expect(schema.safeParse('  true  ').$1, isTrue);
      expect(schema.safeParse('1').$1, isTrue);
      expect(schema.safeParse('yes').$1, isTrue);
      expect(schema.safeParse('on').$1, isTrue);

      // False values
      expect(schema.safeParse('false').$1, isFalse);
      expect(schema.safeParse('FALSE').$1, isFalse);
      expect(schema.safeParse('0').$1, isFalse);
      expect(schema.safeParse('no').$1, isFalse);
      expect(schema.safeParse('off').$1, isFalse);
    });

    test('coerces int to boolean', () {
      final schema = Z.coerce.boolean();

      expect(schema.safeParse(1).$1, isTrue);
      expect(schema.safeParse(0).$1, isFalse);
    });

    test('rejects invalid values', () {
      final schema = Z.coerce.boolean();

      expect(schema.safeParse('maybe').$2, isNotNull);
      expect(schema.safeParse('2').$2, isNotNull);
      expect(schema.safeParse([]).$2, isNotNull);
    });
  });

  group('Z.coerce.number', () {
    test('passes through double', () {
      final schema = Z.coerce.number();

      expect(schema.safeParse(3.14).$1, equals(3.14));
    });

    test('coerces int to double', () {
      final schema = Z.coerce.number();

      expect(schema.safeParse(42).$1, equals(42.0));
    });

    test('coerces string to double', () {
      final schema = Z.coerce.number();

      expect(schema.safeParse('3.14').$1, equals(3.14));
      expect(schema.safeParse('  42  ').$1, equals(42.0));
      expect(schema.safeParse('-10.5').$1, equals(-10.5));
    });

    test('rejects invalid string', () {
      final schema = Z.coerce.number();

      expect(schema.safeParse('not a number').$2, isNotNull);
      expect(schema.safeParse('12.34.56').$2, isNotNull);
    });

    test('validates range after coercion', () {
      final schema = Z.coerce.number(min: 0, max: 100);

      expect(schema.safeParse('50.5').$2, isNull);
      expect(schema.safeParse('-10').$2, isNotNull);
      expect(schema.safeParse('200').$2, isNotNull);
    });
  });

  group('Z.coerce.string', () {
    test('passes through string', () {
      final schema = Z.coerce.string();

      expect(schema.safeParse('hello').$1, equals('hello'));
    });

    test('coerces number to string', () {
      final schema = Z.coerce.string();

      expect(schema.safeParse(42).$1, equals('42'));
      expect(schema.safeParse(3.14).$1, equals('3.14'));
    });

    test('coerces boolean to string', () {
      final schema = Z.coerce.string();

      expect(schema.safeParse(true).$1, equals('true'));
      expect(schema.safeParse(false).$1, equals('false'));
    });
  });
}
