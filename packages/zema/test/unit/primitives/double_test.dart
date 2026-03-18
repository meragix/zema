import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaDouble', () {
    group('Type validation', () {
      test('accepts valid double', () {
        final schema = z.double();
        final result = schema.safeParse(3.14);

        expect(result.isSuccess, isTrue);
        expect(result.value, equals(3.14));
      });

      test('rejects integer value (not a double in Dart)', () {
        // In Dart, int and double are distinct types at runtime.
        final schema = z.double();
        expect(schema.safeParse(42).isFailure, isTrue);
      });

      test('accepts negative double', () {
        final schema = z.double();
        expect(schema.safeParse(-1.5).isSuccess, isTrue);
      });

      test('accepts zero', () {
        final schema = z.double();
        expect(schema.safeParse(0.0).isSuccess, isTrue);
      });

      test('rejects non-numeric: string', () {
        final schema = z.double();
        final result = schema.safeParse('3.14');

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('invalid_type'));
      });

      test('rejects non-numeric: boolean', () {
        final schema = z.double();
        expect(schema.safeParse(true).isFailure, isTrue);
      });

      test('rejects null', () {
        final schema = z.double();
        expect(schema.safeParse(null).isFailure, isTrue);
      });
    });

    group('Range validation', () {
      test('gte() validates minimum value', () {
        final schema = z.double().gte(0.0);

        expect(schema.safeParse(0.0).isSuccess, isTrue);
        expect(schema.safeParse(0.1).isSuccess, isTrue);
        expect(schema.safeParse(-0.1).isFailure, isTrue);
        expect(schema.safeParse(-0.1).errors.first.code, equals('too_small'));
      });

      test('lte() validates maximum value', () {
        final schema = z.double().lte(1.0);

        expect(schema.safeParse(1.0).isSuccess, isTrue);
        expect(schema.safeParse(0.99).isSuccess, isTrue);
        expect(schema.safeParse(1.01).isFailure, isTrue);
        expect(schema.safeParse(1.01).errors.first.code, equals('too_big'));
      });

      test('gte() and lte() together constrain a range', () {
        final schema = z.double().gte(0.0).lte(1.0);

        expect(schema.safeParse(0.5).isSuccess, isTrue);
        expect(schema.safeParse(0.0).isSuccess, isTrue);
        expect(schema.safeParse(1.0).isSuccess, isTrue);
        expect(schema.safeParse(-0.1).isFailure, isTrue);
        expect(schema.safeParse(1.1).isFailure, isTrue);
      });

      test('gt() rejects value equal to bound (exclusive)', () {
        final schema = z.double().gt(0.0);

        expect(schema.safeParse(0.001).isSuccess, isTrue);
        expect(schema.safeParse(0.0).isFailure, isTrue);
      });

      test('lt() rejects value equal to bound (exclusive)', () {
        final schema = z.double().lt(1.0);

        expect(schema.safeParse(0.999).isSuccess, isTrue);
        expect(schema.safeParse(1.0).isFailure, isTrue);
      });
    });

    group('positive() and negative()', () {
      test('positive() accepts values greater than zero', () {
        final schema = z.double().positive();

        expect(schema.safeParse(0.001).isSuccess, isTrue);
        expect(schema.safeParse(0.0).isFailure, isTrue);
        expect(schema.safeParse(-0.001).isFailure, isTrue);
      });

      test('negative() accepts values less than zero', () {
        final schema = z.double().negative();

        expect(schema.safeParse(-0.001).isSuccess, isTrue);
        expect(schema.safeParse(0.0).isFailure, isTrue);
        expect(schema.safeParse(0.001).isFailure, isTrue);
      });
    });

    group('nonNegative()', () {
      test('accepts zero', () {
        final schema = z.double().nonNegative();
        expect(schema.safeParse(0.0).isSuccess, isTrue);
      });

      test('accepts positive doubles', () {
        final schema = z.double().nonNegative();
        expect(schema.safeParse(0.001).isSuccess, isTrue);
        expect(schema.safeParse(100.0).isSuccess, isTrue);
      });

      test('rejects negative doubles', () {
        final schema = z.double().nonNegative();
        final result = schema.safeParse(-0.001);

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('too_small'));
      });

      test('custom message is used on failure', () {
        final schema = z.double().nonNegative(message: 'Must be >= 0.0');
        final result = schema.safeParse(-1.0);

        expect(result.errors.first.message, equals('Must be >= 0.0'));
      });
    });

    group('finite()', () {
      test('accepts finite values', () {
        final schema = z.double().finite();
        expect(schema.safeParse(3.14).isSuccess, isTrue);
        expect(schema.safeParse(0.0).isSuccess, isTrue);
      });

      test('rejects infinity', () {
        final schema = z.double().finite();

        expect(schema.safeParse(double.infinity).isFailure, isTrue);
        expect(schema.safeParse(double.negativeInfinity).isFailure, isTrue);
      });

      test('rejects NaN', () {
        final schema = z.double().finite();
        expect(schema.safeParse(double.nan).isFailure, isTrue);
      });
    });
  });
}
