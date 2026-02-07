import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaInt', () {
    group('Type validation', () {
      test('accepts valid int', () {
        final schema = z.int;
        final result = schema.safeParse(42);

        expect(result.$1, equals(42));
        expect(result.$2, isNull);
      });

      test('rejects non-int', () {
        final schema = z.int;

        expect(schema.safeParse('123').$2, isNotNull);
        expect(schema.safeParse(3.14).$2, isNotNull);
        expect(schema.safeParse(true).$2, isNotNull);
      });

      test('accepts negative integers', () {
        final schema = z.int;
        expect(schema.safeParse(-42).$2, isNull);
      });

      test('accepts zero', () {
        final schema = z.int;
        expect(schema.safeParse(0).$2, isNull);
      });
    });

    group('Range validation', () {
      test('validates minimum value', () {
        final schema = z.int.gte(0);

        expect(schema.safeParse(0).$2, isNull);
        expect(schema.safeParse(10).$2, isNull);
        expect(schema.safeParse(-1).$2, isNotNull);
        expect(schema.safeParse(-1).$2!.first.code, equals('too_small'));
      });

      test('validates maximum value', () {
        final schema = z.int.lte(100);

        expect(schema.safeParse(100).$2, isNull);
        expect(schema.safeParse(50).$2, isNull);
        expect(schema.safeParse(101).$2, isNotNull);
        expect(schema.safeParse(101).$2!.first.code, equals('too_big'));
      });

      test('validates range', () {
        final schema = z.int.gte(0).lte(100);

        expect(schema.safeParse(50).$2, isNull);
        expect(schema.safeParse(0).$2, isNull);
        expect(schema.safeParse(100).$2, isNull);
        expect(schema.safeParse(-1).$2, isNotNull);
        expect(schema.safeParse(101).$2, isNotNull);
      });
    });

    group('Positive/Negative validation', () {
      test('validates positive numbers', () {
        final schema = z.int.positive();

        expect(schema.safeParse(1).$2, isNull);
        expect(schema.safeParse(100).$2, isNull);
        expect(schema.safeParse(0).$2, isNotNull);
        expect(schema.safeParse(-1).$2, isNotNull);
      });

      test('validates negative numbers', () {
        final schema = z.int.negative();

        expect(schema.safeParse(-1).$2, isNull);
        expect(schema.safeParse(-100).$2, isNull);
        expect(schema.safeParse(0).$2, isNotNull);
        expect(schema.safeParse(1).$2, isNotNull);
      });
    });

    group('Multiple of validation', () {
      test('validates multiples', () {
        final schema = z.int.step(5);

        expect(schema.safeParse(0).$2, isNull);
        expect(schema.safeParse(5).$2, isNull);
        expect(schema.safeParse(10).$2, isNull);
        expect(schema.safeParse(-5).$2, isNull);
        expect(schema.safeParse(3).$2, isNotNull);
        expect(schema.safeParse(7).$2, isNotNull);
      });
    });

    group('Multiple error accumulation', () {
      test('collects multiple validation errors', () {
        final schema = z.int.gte(10).lte(20);
        final result = schema.safeParse(5);

        expect(result.$2, isNotNull);
        expect(result.$2!.length, equals(1));
        expect(result.$2!.first.code, equals('too_small'));

        final result2 = schema.safeParse(25);
        expect(result2.$2!.first.code, equals('too_big'));
      });
    });
  });
}
