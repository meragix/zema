import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('Nested Object Validation', () {
    test('validates deeply nested structures', () {
      final schema = Z.object({
        'user': Z.object({
          'profile': Z.object({
            'name': Z.string.min(2),
            'email': Z.string.email(),
            'address': Z.object({
              'street': Z.string,
              'city': Z.string,
              //'zipCode': Z.string.regex(RegExp(r'^\d{5})),
            }),
          }),
          'preferences': Z.object({
            'theme': Z.string.oneOf(['light', 'dark']),
            'notifications': Z.boolean,
          }),
        }),
      });

      final validData = {
        'user': {
          'profile': {
            'name': 'Alice',
            'email': 'alice@example.com',
            'address': {
              'street': '123 Main St',
              'city': 'New York',
              'zipCode': '10001',
            },
          },
          'preferences': {
            'theme': 'dark',
            'notifications': true,
          },
        },
      };

      final result = schema.safeParse(validData);
      expect(result.$2, isNull);
    });

    test('collects errors from all nesting levels', () {
      final schema = Z.object({
        'level1': Z.object({
          'level2': Z.object({
            'level3': Z.object({
              'value': Z.int.positive(),
            }),
          }),
        }),
      });

      final invalidData = {
        'level1': {
          'level2': {
            'level3': {
              'value': -5,
            },
          },
        },
      };

      final result = schema.safeParse(invalidData);

      expect(result.$2, isNotNull);
      expect(
        result.$2!.first.path.join('.'),
        equals('level1.level2.level3.value'),
      );
    });

    test('validates arrays of nested objects', () {
      final schema = Z.object({
        'users': Z.array(Z.object({
          'name': Z.string.min(2),
          'email': Z.string.email(),
        })),
      });

      final data = {
        'users': [
          {'name': 'Alice', 'email': 'alice@example.com'},
          {'name': 'B', 'email': 'invalid'},
          {'name': 'Charlie', 'email': 'charlie@example.com'},
        ],
      };

      final result = schema.safeParse(data);

      expect(result.$2, isNotNull);
      expect(result.$2!.length, equals(2));

      final paths = result.$2!.map((e) => e.path.join('.')).toList();
      expect(paths, contains('users.[1].name'));
      expect(paths, contains('users.[1].email'));
    });
  });
}