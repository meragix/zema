import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaInt', () {
    group('Type validation', () {
      test('accepts valid int', () {
        final schema = z.int();
        final result = schema.safeParse(42);

        expect(result.value, equals(42));
        expect(result.errors, isEmpty);
      });

      test('rejects non-int', () {
        final schema = z.int();

        expect(schema.safeParse('123').errors, isNotEmpty);
        expect(schema.safeParse(3.14).errors, isNotEmpty);
        expect(schema.safeParse(true).errors, isNotEmpty);
      });

      test('accepts negative integers', () {
        final schema = z.int();
        expect(schema.safeParse(-42).errors, isEmpty);
      });

      test('accepts zero', () {
        final schema = z.int();
        expect(schema.safeParse(0).isFailure, isFalse);
      });
    });

    group('Range validation', () {
      test('validates minimum value', () {
        final schema = z.int().gte(0);

        expect(schema.safeParse(0).errors, isEmpty);
        expect(schema.safeParse(10).errors, isEmpty);
        expect(schema.safeParse(-1).errors, isNotEmpty);
        expect(schema.safeParse(-1).errors.first.code, equals('too_small'));
      });

      test('validates maximum value', () {
        final schema = z.int().lte(100);

        expect(schema.safeParse(100).errors, isEmpty);
        expect(schema.safeParse(50).errors, isEmpty);
        expect(schema.safeParse(101).errors, isNotEmpty);
        expect(schema.safeParse(101).errors.first.code, equals('too_big'));
      });

      test('validates range', () {
        final schema = z.int().gte(0).lte(100);

        expect(schema.safeParse(50).errors, isEmpty);
        expect(schema.safeParse(0).errors, isEmpty);
        expect(schema.safeParse(100).errors, isEmpty);
        expect(schema.safeParse(-1).errors, isNotEmpty);
        expect(schema.safeParse(101).errors, isNotEmpty);
      });
    });

    group('Positive/Negative validation', () {
      test('validates positive numbers', () {
        final schema = z.int().positive();

        expect(schema.safeParse(1).errors, isEmpty);
        expect(schema.safeParse(100).errors, isEmpty);
        expect(schema.safeParse(0).errors, isNotEmpty);
        expect(schema.safeParse(-1).errors, isNotEmpty);
      });

      test('validates negative numbers', () {
        final schema = z.int().negative();

        expect(schema.safeParse(-1).errors, isEmpty);
        expect(schema.safeParse(-100).errors, isEmpty);
        expect(schema.safeParse(0).errors, isNotEmpty);
        expect(schema.safeParse(1).errors, isNotEmpty);
      });
    });

    group('Multiple of validation', () {
      test('validates multiples of 5', () {
        final schema = z.int().step(5);

        expect(schema.safeParse(0).isSuccess, isTrue);
        expect(schema.safeParse(5).isSuccess, isTrue);
        expect(schema.safeParse(10).isSuccess, isTrue);
        expect(schema.safeParse(-5).isSuccess, isTrue);
        expect(schema.safeParse(3).isSuccess, isFalse);
        expect(schema.safeParse(7).isSuccess, isFalse);
      });
    });

    group('Multiple error accumulation', () {
      test('collects multiple validation errors', () {
        final schema = z.int().gte(10).lte(20);
        final result = schema.safeParse(5);

        expect(result.errors, isNotEmpty);
        expect(result.errors.length, equals(1));
        expect(result.errors.first.code, equals('too_small'));

        final result2 = schema.safeParse(25);
        expect(result2.errors.first.code, equals('too_big'));
      });
    });
  });
}
