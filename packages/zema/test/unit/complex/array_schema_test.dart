import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('ZemaArray', () {
    group('Basic validation', () {
      test('validates valid array', () {
        final schema = z.array(z.int);
        final result = schema.safeParse([1, 2, 3]);

        expect(result.$2, isNull);
        expect(result.$1, equals([1, 2, 3]));
      });

      test('rejects non-array', () {
        final schema = z.array(z.int);

        expect(schema.safeParse('not an array').$2, isNotNull);
        expect(schema.safeParse({'a': 1}).$2, isNotNull);
        expect(schema.safeParse(null).$2, isNotNull);
      });

      test('accepts empty array', () {
        final schema = z.array(z.int);
        expect(schema.safeParse([]).$2, isNull);
      });
    });

    group('Element validation', () {
      test('validates each element', () {
        final schema = z.array(z.string.email());

        final result = schema.safeParse([
          'test1@example.com',
          'test2@example.com',
        ]);

        expect(result.$2, isNull);
      });

      test('collects ALL element errors', () {
        final schema = z.array(z.string.email());

        final result = schema.safeParse([
          'valid@example.com',
          'invalid1',
          'valid2@example.com',
          'invalid2',
        ]);

        expect(result.$2, isNotNull);
        expect(result.$2!.length, equals(2));

        final paths = result.$2!.map((e) => e.path.join('.')).toList();
        expect(paths, contains('[1]'));
        expect(paths, contains('[3]'));
      });
    });

    group('Length validation', () {
      test('validates minimum length', () {
        final schema = z.array(z.int).min(2);

        expect(schema.safeParse([1, 2]).$2, isNull);
        expect(schema.safeParse([1]).$2, isNotNull);
        expect(schema.safeParse([1]).$2!.first.code, equals('too_small'));
      });

      test('validates maximum length', () {
        final schema = z.array(z.int).max(3);

        expect(schema.safeParse([1, 2, 3]).$2, isNull);
        expect(schema.safeParse([1, 2, 3, 4]).$2, isNotNull);
        expect(
            schema.safeParse([1, 2, 3, 4]).$2!.first.code, equals('too_big'));
      });

      test('validates exact length', () {
        final schema = z.array(z.int).length(3);

        expect(schema.safeParse([1, 2, 3]).$2, isNull);
        expect(schema.safeParse([1, 2]).$2, isNotNull);
        expect(schema.safeParse([1, 2, 3, 4]).$2, isNotNull);
      });

      test('validates nonempty', () {
        final schema = z.array(z.int).nonempty();

        expect(schema.safeParse([1]).$2, isNull);
        expect(schema.safeParse([]).$2, isNotNull);
      });
    });

    group('Complex element types', () {
      test('validates array of objects', () {
        final schema = z.array(z.object({
          'name': z.string,
          'age': z.int,
        }));

        final result = schema.safeParse([
          {'name': 'Alice', 'age': 30},
          {'name': 'Bob', 'age': 25},
        ]);

        expect(result.$2, isNull);
      });

      test('collects errors from nested objects', () {
        final schema = z.array(z.object({
          'email': z.string.email(),
        }));

        final result = schema.safeParse([
          {'email': 'valid@example.com'},
          {'email': 'invalid'},
        ]);

        expect(result.$2, isNotNull);
        expect(result.$2!.first.path, equals(['[1]', 'email']));
      });
    });
  });
}
