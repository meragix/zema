import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('z.coerce().integer', () {
    test('passes through int', () {
      final schema = z.coerce().integer();
      final result = schema.safeParse(42);

      expect(result.value, equals(42));
      expect(result.isFailure, isFalse);
    });

    test('coerces string to int', () {
      final schema = z.coerce().integer();

      expect(schema.safeParse('123').value, equals(123));
      expect(schema.safeParse('  456  ').value, equals(456));
      expect(schema.safeParse('-789').value, equals(-789));
    });

    test('coerces double to int if whole number', () {
      final schema = z.coerce().integer();

      expect(schema.safeParse(42.0).value, equals(42));
      expect(schema.safeParse(-10.0).value, equals(-10));
    });

    test('rejects double with decimal', () {
      final schema = z.coerce().integer();

      expect(schema.safeParse(3.14).isFailure, isTrue);
      expect(
          schema.safeParse(3.14).errors.first.code, equals('invalid_coercion'));
    });

    test('rejects invalid string', () {
      final schema = z.coerce().integer();

      expect(schema.safeParse('not a number').isSuccess, isFalse);
      expect(schema.safeParse('12.34').isSuccess, isFalse);
    });

    test('validates range after coercion', () {
      final schema = z.coerce().integer(min: 0, max: 100);

      expect(schema.safeParse('50').isSuccess, isTrue);
      expect(schema.safeParse('-10').isSuccess, isFalse);
      expect(schema.safeParse('200').isSuccess, isFalse);
    });
  });

  group('z.coerce().boolean', () {
    test('passes through boolean', () {
      final schema = z.coerce().boolean();

      expect(schema.safeParse(true).value, isTrue);
      expect(schema.safeParse(false).value, isFalse);
    });

    test('coerces string to boolean', () {
      final schema = z.coerce().boolean();

      // True values
      expect(schema.safeParse('true').value, isTrue);
      expect(schema.safeParse('TRUE').value, isTrue);
      expect(schema.safeParse('  true  ').value, isTrue);
      expect(schema.safeParse('1').value, isTrue);
      expect(schema.safeParse('yes').value, isTrue);
      expect(schema.safeParse('on').value, isTrue);

      // False values
      expect(schema.safeParse('false').value, isFalse);
      expect(schema.safeParse('FALSE').value, isFalse);
      expect(schema.safeParse('0').value, isFalse);
      expect(schema.safeParse('no').value, isFalse);
      expect(schema.safeParse('off').value, isFalse);
    });

    test('coerces int to boolean', () {
      final schema = z.coerce().boolean();

      expect(schema.safeParse(1).value, isTrue);
      expect(schema.safeParse(0).value, isFalse);
    });

    test('rejects invalid values', () {
      final schema = z.coerce().boolean();

      expect(schema.safeParse('maybe').isSuccess, isFalse);
      expect(schema.safeParse('2').isSuccess, isFalse);
      expect(schema.safeParse(['']).isSuccess, isFalse);
    });
  });

  group('z.coerce().number', () {
    test('passes through double', () {
      final schema = z.coerce().float();

      expect(schema.safeParse(3.14).value, equals(3.14));
    });

    test('coerces int to double', () {
      final schema = z.coerce().float();

      expect(schema.safeParse(42).value, equals(42.0));
    });

    test('coerces string to double', () {
      final schema = z.coerce().float();

      expect(schema.safeParse('3.14').value, equals(3.14));
      expect(schema.safeParse('  42  ').value, equals(42.0));
      expect(schema.safeParse('-10.5').value, equals(-10.5));
    });

    test('rejects invalid string', () {
      final schema = z.coerce().float();

      expect(schema.safeParse('not a number').isSuccess, isFalse);
      expect(schema.safeParse('12.34.56').isSuccess, isFalse);
    });

    test('validates range after coercion', () {
      final schema = z.coerce().float(min: 0, max: 100);

      expect(schema.safeParse('50.5').isSuccess, isTrue);
      expect(schema.safeParse('-10').isSuccess, isFalse);
      expect(schema.safeParse('200').isSuccess, isFalse);
    });
  });

  group('z.coerce().string', () {
    test('passes through string', () {
      final schema = z.coerce().string();

      expect(schema.safeParse('hello').value, equals('hello'));
    });

    test('coerces number to string', () {
      final schema = z.coerce().string();

      expect(schema.safeParse(42).value, equals('42'));
      expect(schema.safeParse(3.14).value, equals('3.14'));
    });

    test('coerces boolean to string', () {
      final schema = z.coerce().string();

      expect(schema.safeParse(true).value, equals('true'));
      expect(schema.safeParse(false).value, equals('false'));
    });
  });
}
