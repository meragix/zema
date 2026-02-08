import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  // group('ZemaObject', () {
  //   group('Basic validation', () {
  //     test('validates valid object', () {
  //       final schema = z.object({
  //         'name': z.string,
  //         'age': z.int,
  //       });

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'age': 30,
  //       });

  //       expect(result.$2, isNull);
  //       expect(result.$1, isA<Map>());
  //       expect(result.$1!['name'], equals('Alice'));
  //       expect(result.$1!['age'], equals(30));
  //     });

  //     test('rejects non-object', () {
  //       final schema = z.object({'name': z.string});

  //       expect(schema.safeParse('not an object').$2, isNotNull);
  //       expect(schema.safeParse([1, 2, 3]).$2, isNotNull);
  //       expect(schema.safeParse(null).$2, isNotNull);
  //     });
  //   });

  //   group('Field validation', () {
  //     test('validates each field', () {
  //       final schema = z.object({
  //         'name': z.string.min(2),
  //         'email': z.string.email(),
  //         'age': z.int.positive(),
  //       });

  //       final result = schema.safeParse({
  //         'name': 'Bob',
  //         'email': 'bob@example.com',
  //         'age': 25,
  //       });

  //       expect(result.$2, isNull);
  //     });

  //     test('allows missing optional fields', () {
  //       final schema = z.object({
  //         'name': z.string,
  //         'nickname': z.string.optional(),
  //       });

  //       final result = schema.safeParse({'name': 'Alice'});
  //       expect(result.$2, isNull);
  //     });
  //   });

  //   group('Error accumulation', () {
  //     test('collects ALL field errors', () {
  //       final schema = z.object({
  //         'name': z.string.min(5),
  //         'email': z.string.email(),
  //         'age': z.int.gte(18),
  //       });

  //       final result = schema.safeParse({
  //         'name': 'Bob', // Too short
  //         'email': 'invalid', // Not an email
  //         'age': 10, // Too young
  //       });

  //       expect(result.$2, isNotNull);
  //       expect(result.$2!.length, equals(3));

  //       final paths = result.$2!.map((e) => e.path.join('.')).toList();
  //       expect(paths, contains('name'));
  //       expect(paths, contains('email'));
  //       expect(paths, contains('age'));
  //     });

  //     test('error paths are correct', () {
  //       final schema = z.object({'email': z.string.email()});

  //       final result = schema.safeParse({'email': 'invalid'});

  //       expect(result.$2!.first.path, equals(['email']));
  //     });
  //   });

  //   group('Nested objects', () {
  //     test('validates nested objects', () {
  //       final schema = z.object({
  //         'user': z.object({
  //           'name': z.string,
  //           'email': z.string.email(),
  //         }),
  //       });

  //       final result = schema.safeParse({
  //         'user': {
  //           'name': 'Alice',
  //           'email': 'alice@example.com',
  //         },
  //       });

  //       expect(result.$2, isNull);
  //     });

  //     test('collects nested errors with correct paths', () {
  //       final schema = z.object({
  //         'user': z.object({
  //           'name': z.string.min(5),
  //           'email': z.string.email(),
  //         }),
  //       });

  //       final result = schema.safeParse({
  //         'user': {
  //           'name': 'Bob',
  //           'email': 'invalid',
  //         },
  //       });

  //       expect(result.$2, isNotNull);
  //       expect(result.$2!.length, equals(2));

  //       final paths = result.$2!.map((e) => e.path.join('.')).toList();
  //       expect(paths, contains('user.name'));
  //       expect(paths, contains('user.email'));
  //     });
  //   });

  //   group('Custom constructor', () {
  //     test('transforms to custom class', () {
  //       final schema = z.objectAs<User>(
  //         {
  //           'name': z.string,
  //           'age': z.int,
  //         },
  //         (map) => User(
  //           name: map['name'] as String,
  //           age: map['age'] as int,
  //         ),
  //       );

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'age': 30,
  //       });

  //       expect(result.$2, isNull);
  //       expect(result.$1, isA<User>());
  //       expect(result.$1!.name, equals('Alice'));
  //       expect(result.$1!.age, equals(30));
  //     });

  //     test('handles constructor errors', () {
  //       final schema = z.objectAs<User>(
  //         {'name': z.string, 'age': z.int},
  //         (map) => throw Exception('Constructor failed'),
  //       );

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'age': 30,
  //       });

  //       expect(result.$2, isNotNull);
  //       expect(result.$2!.first.code, equals('transform_error'));
  //     });
  //   });

  //   group('Strict mode', () {
  //     test('allows unknown keys by default', () {
  //       final schema = z.object({'name': z.string});

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'unknown': 'field',
  //       });

  //       expect(result.$2, isNull);
  //     });

  //     test('rejects unknown keys in strict mode', () {
  //       final schema = z.object({'name': z.string}).makeStrict();

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'unknown': 'field',
  //       });

  //       expect(result.$2, isNotNull);
  //       expect(result.$2!.first.code, equals('unknown_key'));
  //       expect(result.$2!.first.path, equals(['unknown']));
  //     });
  //   });

  //   group('Utility methods', () {
  //     test('extend adds fields', () {
  //       final base = z.object({'name': z.string});
  //       final extended = base.extend({'age': z.int});

  //       final result = extended.safeParse({
  //         'name': 'Alice',
  //         'age': 30,
  //       });

  //       expect(result.$2, isNull);
  //     });

  //     test('pick selects fields', () {
  //       final schema = z.object({
  //         'name': z.string,
  //         'age': z.int,
  //         'email': z.string,
  //       }).pick(['name', 'email']);

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'email': 'alice@example.com',
  //       });

  //       expect(result.$2, isNull);
  //     });

  //     test('omit excludes fields', () {
  //       final schema = z.object({
  //         'name': z.string,
  //         'password': z.string,
  //         'email': z.string,
  //       }).omit(['password']);

  //       final result = schema.safeParse({
  //         'name': 'Alice',
  //         'email': 'alice@example.com',
  //       });

  //       expect(result.$2, isNull);
  //     });
  //   });
  // });
}

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
}
