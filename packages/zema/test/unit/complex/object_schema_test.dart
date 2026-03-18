import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaObject', () {
    group('Type validation', () {
      test('accepts valid map', () {
        final schema = z.object({
          'name': z.string(),
          'age': z.int(),
        });

        final result = schema.safeParse({'name': 'Alice', 'age': 30});

        expect(result.isSuccess, isTrue);
        expect(result.value['name'], equals('Alice'));
        expect(result.value['age'], equals(30));
      });

      test('rejects non-map: string', () {
        final schema = z.object({'name': z.string()});
        final result = schema.safeParse('not a map');

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('invalid_type'));
      });

      test('rejects non-map: list', () {
        final schema = z.object({'name': z.string()});
        expect(schema.safeParse([1, 2, 3]).isFailure, isTrue);
      });

      test('rejects non-map: null', () {
        final schema = z.object({'name': z.string()});
        expect(schema.safeParse(null).isFailure, isTrue);
      });

      test('accepts empty object when shape is empty', () {
        final schema = z.object({});
        final result = schema.safeParse(<String, dynamic>{});

        expect(result.isSuccess, isTrue);
      });
    });

    group('Field validation', () {
      test('validates each field with its schema', () {
        final schema = z.object({
          'name': z.string().min(2),
          'email': z.string().email(),
          'age': z.int().positive(),
        });

        final result = schema.safeParse({
          'name': 'Bob',
          'email': 'bob@example.com',
          'age': 25,
        });

        expect(result.isSuccess, isTrue);
      });

      test('fails when a required field is missing (null)', () {
        final schema = z.object({'name': z.string()});
        final result = schema.safeParse(<String, dynamic>{});

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('invalid_type'));
      });

      test('allows missing optional fields', () {
        final schema = z.object({
          'name': z.string(),
          'nickname': z.string().optional(),
        });

        final result = schema.safeParse({'name': 'Alice'});
        expect(result.isSuccess, isTrue);
        expect(result.value['nickname'], isNull);
      });

      test('strips extra keys not in shape', () {
        final schema = z.object({'name': z.string()});
        final result = schema.safeParse({'name': 'Alice', 'extra': 'value'});

        expect(result.isSuccess, isTrue);
        expect(result.value.containsKey('extra'), isFalse);
      });
    });

    group('Error accumulation', () {
      test('collects all field errors in a single pass', () {
        final schema = z.object({
          'name': z.string().min(5),
          'email': z.string().email(),
          'age': z.int().gte(18),
        });

        final result = schema.safeParse({
          'name': 'Bob',
          'email': 'invalid',
          'age': 10,
        });

        expect(result.isFailure, isTrue);
        expect(result.errors.length, equals(3));
      });

      test('error paths include field name', () {
        final schema = z.object({'email': z.string().email()});
        final result = schema.safeParse({'email': 'invalid'});

        expect(result.isFailure, isTrue);
        expect(result.errors.first.path, equals(['email']));
      });

      test('error paths include all failing field names', () {
        final schema = z.object({
          'name': z.string().min(5),
          'email': z.string().email(),
        });

        final result = schema.safeParse({'name': 'Bob', 'email': 'bad'});
        final paths = result.errors.map((e) => e.path.first).toList();

        expect(paths, containsAll(['name', 'email']));
      });
    });

    group('Nested objects', () {
      test('validates nested object', () {
        final schema = z.object({
          'user': z.object({
            'name': z.string(),
            'email': z.string().email(),
          }),
        });

        final result = schema.safeParse({
          'user': {'name': 'Alice', 'email': 'alice@example.com'},
        });

        expect(result.isSuccess, isTrue);
      });

      test('collects nested errors with path including parent key', () {
        final schema = z.object({
          'user': z.object({
            'name': z.string().min(5),
            'email': z.string().email(),
          }),
        });

        final result = schema.safeParse({
          'user': {'name': 'Bob', 'email': 'invalid'},
        });

        expect(result.isFailure, isTrue);
        expect(result.errors.length, equals(2));

        // path is built bottom-up: [childSegment, parentSegment]
        final paths = result.errors.map((e) => e.path.join('.')).toList();
        expect(paths, contains('name.user'));
        expect(paths, contains('email.user'));
      });
    });

    group('objectAs() custom constructor', () {
      test('transforms validated map to typed class', () {
        final schema = z.objectAs(
          {'name': z.string(), 'age': z.int()},
          (map) => _User(
            name: map['name'] as String,
            age: map['age'] as int,
          ),
        );

        final result = schema.safeParse({'name': 'Alice', 'age': 30});

        expect(result.isSuccess, isTrue);
        expect(result.value, isA<_User>());
        expect(result.value.name, equals('Alice'));
        expect(result.value.age, equals(30));
      });

      test('produces transform_error when constructor throws', () {
        final schema = z.objectAs<_User>(
          {'name': z.string(), 'age': z.int()},
          (_) => throw Exception('Constructor failed'),
        );

        final result = schema.safeParse({'name': 'Alice', 'age': 30});

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('transform_error'));
      });
    });

    group('makeStrict()', () {
      test('allows valid input without unknown keys', () {
        final schema = z.object({'name': z.string()}).makeStrict();
        expect(schema.safeParse({'name': 'Alice'}).isSuccess, isTrue);
      });

      test('rejects input with unknown keys', () {
        final schema = z.object({'name': z.string()}).makeStrict();
        final result = schema.safeParse({'name': 'Alice', 'extra': 'value'});

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('unknown_key'));
        expect(result.errors.first.path, equals(['extra']));
      });

      test('non-strict (default) allows unknown keys', () {
        final schema = z.object({'name': z.string()});
        expect(
          schema.safeParse({'name': 'Alice', 'extra': 'value'}).isSuccess,
          isTrue,
        );
      });
    });

    group('extend()', () {
      test('adds fields from additional shape', () {
        final base = z.object({'name': z.string()});
        final extended = base.extend({'age': z.int()});

        final result = extended.safeParse({'name': 'Alice', 'age': 30});
        expect(result.isSuccess, isTrue);
      });

      test('override fields from additional shape wins', () {
        final base = z.object({'value': z.int()});
        final extended = base.extend({'value': z.string()});

        expect(extended.safeParse({'value': 'text'}).isSuccess, isTrue);
        expect(extended.safeParse({'value': 42}).isFailure, isTrue);
      });

      test('original schema is not mutated', () {
        final base = z.object({'name': z.string()});
        base.extend({'age': z.int()});

        // base should still only require 'name'
        expect(base.safeParse({'name': 'Alice'}).isSuccess, isTrue);
        expect(base.shape.containsKey('age'), isFalse);
      });
    });

    group('merge()', () {
      test('merges fields from another ZemaObject', () {
        final base = z.object({'name': z.string(), 'age': z.int()});
        final override = z.object({
          'age': z.int().gte(18),
          'email': z.string().email(),
        });
        final merged = base.merge(override);

        expect(
          merged.safeParse({
            'name': 'Alice',
            'age': 20,
            'email': 'alice@example.com',
          }).isSuccess,
          isTrue,
        );
      });

      test('other schema fields override base fields with same key', () {
        final base = z.object({'age': z.int()});
        final other = z.object({'age': z.int().gte(18)});
        final merged = base.merge(other);

        expect(merged.safeParse({'age': 20}).isSuccess, isTrue);
        expect(merged.safeParse({'age': 10}).isFailure, isTrue);
      });
    });

    group('pick()', () {
      test('returns schema with only picked fields', () {
        final full = z.object({
          'id': z.int(),
          'name': z.string(),
          'email': z.string().email(),
        });

        final picked = full.pick(['id', 'name']);

        expect(
          picked.safeParse({'id': 1, 'name': 'Alice'}).isSuccess,
          isTrue,
        );
        expect(picked.shape.containsKey('email'), isFalse);
      });

      test('ignores keys not in shape', () {
        final schema = z.object({'name': z.string()});
        final picked = schema.pick(['name', 'nonexistent']);

        expect(picked.shape.containsKey('name'), isTrue);
        expect(picked.shape.length, equals(1));
      });
    });

    group('omit()', () {
      test('returns schema with specified fields removed', () {
        final full = z.object({
          'id': z.int(),
          'name': z.string(),
          'password': z.string(),
        });

        final safe = full.omit(['password']);

        expect(safe.safeParse({'id': 1, 'name': 'Alice'}).isSuccess, isTrue);
        expect(safe.shape.containsKey('password'), isFalse);
      });

      test('ignores keys not in shape', () {
        final schema = z.object({'name': z.string()});
        final omitted = schema.omit(['nonexistent']);

        expect(omitted.shape.containsKey('name'), isTrue);
      });
    });
  });
}

class _User {
  final String name;
  final int age;

  _User({required this.name, required this.age});
}
