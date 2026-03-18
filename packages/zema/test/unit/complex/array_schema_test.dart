import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaArray', () {
    group('Type validation', () {
      test('accepts valid list', () {
        final schema = z.array(z.int());
        final result = schema.safeParse([1, 2, 3]);

        expect(result.isSuccess, isTrue);
        expect(result.value, equals([1, 2, 3]));
      });

      test('rejects non-list: string', () {
        final schema = z.array(z.int());
        final result = schema.safeParse('not a list');

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('invalid_type'));
      });

      test('rejects non-list: map', () {
        final schema = z.array(z.int());
        expect(schema.safeParse({'a': 1}).isFailure, isTrue);
      });

      test('rejects non-list: null', () {
        final schema = z.array(z.int());
        expect(schema.safeParse(null).isFailure, isTrue);
      });

      test('accepts empty list', () {
        final schema = z.array(z.int());
        expect(schema.safeParse(<int>[]).isSuccess, isTrue);
      });
    });

    group('Element validation', () {
      test('validates each element', () {
        final schema = z.array(z.string().email());
        final result = schema.safeParse([
          'test1@example.com',
          'test2@example.com',
        ]);

        expect(result.isSuccess, isTrue);
      });

      test('fails when any element is invalid', () {
        final schema = z.array(z.string().email());
        final result = schema.safeParse(['valid@example.com', 'invalid']);

        expect(result.isFailure, isTrue);
      });

      test('collects all element errors in a single pass', () {
        final schema = z.array(z.string().email());
        final result = schema.safeParse([
          'valid@example.com',
          'invalid1',
          'valid2@example.com',
          'invalid2',
        ]);

        expect(result.isFailure, isTrue);
        expect(result.errors.length, equals(2));
      });

      test('error path contains integer index of failing element', () {
        final schema = z.array(z.string().email());
        final result = schema.safeParse(['valid@example.com', 'bad']);

        expect(result.errors.first.path.first, equals(1));
      });
    });

    group('Length constraints', () {
      test('min() rejects list shorter than minimum', () {
        final schema = z.array(z.int()).min(2);

        expect(schema.safeParse([1, 2]).isSuccess, isTrue);
        expect(schema.safeParse([1]).isFailure, isTrue);
        expect(schema.safeParse([1]).errors.first.code, equals('too_small'));
      });

      test('min() skips element validation when length check fails', () {
        // element schema would fail on strings, but length check fires first
        final schema = z.array(z.int()).min(3);
        final result = schema.safeParse([1]);

        expect(result.errors.length, equals(1));
        expect(result.errors.first.code, equals('too_small'));
      });

      test('max() rejects list longer than maximum', () {
        final schema = z.array(z.int()).max(3);

        expect(schema.safeParse([1, 2, 3]).isSuccess, isTrue);
        expect(schema.safeParse([1, 2, 3, 4]).isFailure, isTrue);
        expect(
          schema.safeParse([1, 2, 3, 4]).errors.first.code,
          equals('too_big'),
        );
      });

      test('length() requires exactly n elements', () {
        final schema = z.array(z.int()).length(3);

        expect(schema.safeParse([1, 2, 3]).isSuccess, isTrue);
        expect(schema.safeParse([1, 2]).isFailure, isTrue);
        expect(schema.safeParse([1, 2, 3, 4]).isFailure, isTrue);
      });

      test('nonEmpty() rejects empty list', () {
        final schema = z.array(z.int()).nonEmpty();

        expect(schema.safeParse([1]).isSuccess, isTrue);
        expect(schema.safeParse(<int>[]).isFailure, isTrue);
        expect(
          schema.safeParse(<int>[]).errors.first.code,
          equals('too_small'),
        );
      });
    });

    group('Array of objects', () {
      test('validates each object element', () {
        final schema = z.array(
          z.object({'name': z.string(), 'age': z.int()}),
        );

        final result = schema.safeParse([
          {'name': 'Alice', 'age': 30},
          {'name': 'Bob', 'age': 25},
        ]);

        expect(result.isSuccess, isTrue);
        expect(result.value.length, equals(2));
      });

      test('collects errors from nested object with index in path', () {
        final schema = z.array(z.object({'email': z.string().email()}));

        final result = schema.safeParse([
          {'email': 'valid@example.com'},
          {'email': 'invalid'},
        ]);

        expect(result.isFailure, isTrue);
        // path is built bottom-up: [childSegment, parentIndex]
        expect(result.errors.first.path.first, equals('email'));
        expect(result.errors.first.path.last, equals(1));
      });
    });
  });
}
