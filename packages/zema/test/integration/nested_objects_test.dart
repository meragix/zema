import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('Nested Object Validation', () {
    test('validates deeply nested structures', () {
      final schema = z.object({
        'user': z.object({
          'profile': z.object({
            'name': z.string.min(2),
            'email': z.string.email(),
            'address': z.object({
              'street': z.string,
              'city': z.string,
              //'zipCode': z.string.regex(RegExp(r'^\d{5})),
            }),
          }),
          'preferences': z.object({
            'theme': z.string.oneOf(['light', 'dark']),
            'notifications': z.boolean,
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
      final schema = z.object({
        'level1': z.object({
          'level2': z.object({
            'level3': z.object({
              'value': z.int.positive(),
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
      final schema = z.object({
        'users': z.array(z.object({
          'name': z.string.min(2),
          'email': z.string.email(),
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
