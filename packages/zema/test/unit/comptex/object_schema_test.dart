import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('ZObject', () {
    group('Basic validation', () {
      test('validates valid object', () {
        final schema = Z.object({
          'name': Z.string,
          'age': Z.int,
        });

        final result = schema.safeParse({
          'name': 'Alice',
          'age': 30,
        });

        expect(result.$2, isNull);
        expect(result.$1, isA<Map>());
        expect(result.$1!['name'], equals('Alice'));
        expect(result.$1!['age'], equals(30));
      });

      test('rejects non-object', () {
        final schema = Z.object({'name': Z.string});

        expect(schema.safeParse('not an object').$2, isNotNull);
        expect(schema.safeParse([1, 2, 3]).$2, isNotNull);
        expect(schema.safeParse(null).$2, isNotNull);
      });
    });

    group('Field validation', () {
      test('validates each field', () {
        final schema = Z.object({
          'name': Z.string.min(2),
          'email': Z.string.email(),
          'age': Z.int.positive(),
        });

        final result = schema.safeParse({
          'name': 'Bob',
          'email': 'bob@example.com',
          'age': 25,
        });

        expect(result.$2, isNull);
      });

      test('allows missing optional fields', () {
        final schema = Z.object({
          'name': Z.string,
          'nickname': Z.string.optional(),
        });

        final result = schema.safeParse({'name': 'Alice'});
        expect(result.$2, isNull);
      });
    });

    group('Error accumulation', () {
      test('collects ALL field errors', () {
        final schema = Z.object({
          'name': Z.string.min(5),
          'email': Z.string.email(),
          'age': Z.int.gte(18),
        });

        final result = schema.safeParse({
          'name': 'Bob', // Too short
          'email': 'invalid', // Not an email
          'age': 10, // Too young
        });

        expect(result.$2, isNotNull);
        expect(result.$2!.length, equals(3));

        final paths = result.$2!.map((e) => e.path.join('.')).toList();
        expect(paths, contains('name'));
        expect(paths, contains('email'));
        expect(paths, contains('age'));
      });

      test('error paths are correct', () {
        final schema = Z.object({'email': Z.string.email()});

        final result = schema.safeParse({'email': 'invalid'});

        expect(result.$2!.first.path, equals(['email']));
      });
    });

    group('Nested objects', () {
      test('validates nested objects', () {
        final schema = Z.object({
          'user': Z.object({
            'name': Z.string,
            'email': Z.string.email(),
          }),
        });

        final result = schema.safeParse({
          'user': {
            'name': 'Alice',
            'email': 'alice@example.com',
          },
        });

        expect(result.$2, isNull);
      });

      test('collects nested errors with correct paths', () {
        final schema = Z.object({
          'user': Z.object({
            'name': Z.string.min(5),
            'email': Z.string.email(),
          }),
        });

        final result = schema.safeParse({
          'user': {
            'name': 'Bob',
            'email': 'invalid',
          },
        });

        expect(result.$2, isNotNull);
        expect(result.$2!.length, equals(2));

        final paths = result.$2!.map((e) => e.path.join('.')).toList();
        expect(paths, contains('user.name'));
        expect(paths, contains('user.email'));
      });
    });

    group('Custom constructor', () {
      test('transforms to custom class', () {
        final schema = Z.objectAs<User>(
          {
            'name': Z.string,
            'age': Z.int,
          },
          (map) => User(
            name: map['name'] as String,
            age: map['age'] as int,
          ),
        );

        final result = schema.safeParse({
          'name': 'Alice',
          'age': 30,
        });

        expect(result.$2, isNull);
        expect(result.$1, isA<User>());
        expect(result.$1!.name, equals('Alice'));
        expect(result.$1!.age, equals(30));
      });

      test('handles constructor errors', () {
        final schema = Z.objectAs<User>(
          {'name': Z.string, 'age': Z.int},
          (map) => throw Exception('Constructor failed'),
        );

        final result = schema.safeParse({
          'name': 'Alice',
          'age': 30,
        });

        expect(result.$2, isNotNull);
        expect(result.$2!.first.code, equals('transform_error'));
      });
    });

    group('Strict mode', () {
      test('allows unknown keys by default', () {
        final schema = Z.object({'name': Z.string});

        final result = schema.safeParse({
          'name': 'Alice',
          'unknown': 'field',
        });

        expect(result.$2, isNull);
      });

      test('rejects unknown keys in strict mode', () {
        final schema = Z.object({'name': Z.string}).makeStrict();

        final result = schema.safeParse({
          'name': 'Alice',
          'unknown': 'field',
        });

        expect(result.$2, isNotNull);
        expect(result.$2!.first.code, equals('unknown_key'));
        expect(result.$2!.first.path, equals(['unknown']));
      });
    });

    group('Utility methods', () {
      test('extend adds fields', () {
        final base = Z.object({'name': Z.string});
        final extended = base.extend({'age': Z.int});

        final result = extended.safeParse({
          'name': 'Alice',
          'age': 30,
        });

        expect(result.$2, isNull);
      });

      test('pick selects fields', () {
        final schema = Z.object({
          'name': Z.string,
          'age': Z.int,
          'email': Z.string,
        }).pick(['name', 'email']);

        final result = schema.safeParse({
          'name': 'Alice',
          'email': 'alice@example.com',
        });

        expect(result.$2, isNull);
      });

      test('omit excludes fields', () {
        final schema = Z.object({
          'name': Z.string,
          'password': Z.string,
          'email': Z.string,
        }).omit(['password']);

        final result = schema.safeParse({
          'name': 'Alice',
          'email': 'alice@example.com',
        });

        expect(result.$2, isNull);
      });
    });
  });
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}
