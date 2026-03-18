import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaUnion', () {
    group('Linear scan (no discriminator)', () {
      test('accepts value matching first schema', () {
        final schema = z.union<dynamic>([z.string(), z.int()]);
        expect(schema.safeParse('hello').isSuccess, isTrue);
      });

      test('accepts value matching second schema', () {
        final schema = z.union<dynamic>([z.string(), z.int()]);
        expect(schema.safeParse(42).isSuccess, isTrue);
      });

      test('returns value from first matching schema', () {
        final schema = z.union<dynamic>([z.string(), z.int()]);
        expect(schema.safeParse('hello').value, equals('hello'));
      });

      test('fails when no schema matches', () {
        final schema = z.union<dynamic>([z.string(), z.int()]);
        final result = schema.safeParse(true);

        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('invalid_union'));
      });

      test('invalid_union meta includes unionErrors list', () {
        final schema = z.union<dynamic>([z.string(), z.int()]);
        final result = schema.safeParse(true);

        expect(result.errors.first.meta?['unionErrors'], isNotNull);
        expect(
          result.errors.first.meta?['unionErrors'],
          isA<List<dynamic>>(),
        );
      });

      test('invalid_union meta includes schemaCount', () {
        final schema = z.union<dynamic>([z.string(), z.int()]);
        final result = schema.safeParse(true);

        expect(result.errors.first.meta?['schemaCount'], equals(2));
      });

      test('first matching schema wins (more specific before broader)', () {
        final schema = z.union([
          z.literal('admin'),
          z.string(),
        ]);

        expect(schema.safeParse('admin').value, equals('admin'));
        expect(schema.safeParse('user').value, equals('user'));
      });

      test('validates union of literals', () {
        final schema = z.union([
          z.literal('pending'),
          z.literal('active'),
          z.literal('archived'),
        ]);

        expect(schema.safeParse('pending').isSuccess, isTrue);
        expect(schema.safeParse('active').isSuccess, isTrue);
        expect(schema.safeParse('archived').isSuccess, isTrue);
        expect(schema.safeParse('unknown').isFailure, isTrue);
      });
    });

    group('discriminatedBy()', () {
      test('validates correct schema based on discriminator value', () {
        final schema = z.union([
          z.object({
            'type': z.literal('click'),
            'x': z.int(),
            'y': z.int(),
          }),
          z.object({
            'type': z.literal('keypress'),
            'key': z.string(),
          }),
        ]).discriminatedBy('type');

        expect(
          schema.safeParse({'type': 'click', 'x': 100, 'y': 200}).isSuccess,
          isTrue,
        );
        expect(
          schema.safeParse({'type': 'keypress', 'key': 'Enter'}).isSuccess,
          isTrue,
        );
      });

      test('fails with invalid_union when discriminator value has no match',
          () {
        final schema = z.union([
          z.object({'type': z.literal('click'), 'x': z.int(), 'y': z.int()}),
        ]).discriminatedBy('type');

        final result = schema.safeParse({'type': 'unknown', 'x': 1, 'y': 2});
        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('invalid_union'));
      });

      test('invalid_union meta includes discriminator key on mismatch', () {
        final schema = z.union([
          z.object({'type': z.literal('click'), 'x': z.int(), 'y': z.int()}),
        ]).discriminatedBy('type');

        final result = schema.safeParse({'type': 'unknown'});
        expect(result.errors.first.meta?['discriminator'], equals('type'));
      });

      test('validates fields of the matched schema', () {
        final schema = z.union([
          z.object({
            'type': z.literal('click'),
            'x': z.int(),
            'y': z.int(),
          }),
          z.object({
            'type': z.literal('keypress'),
            'key': z.string(),
          }),
        ]).discriminatedBy('type');

        // 'click' matched but y is missing (required field)
        final result = schema.safeParse({'type': 'click', 'x': 1});
        expect(result.isFailure, isTrue);
        expect(result.errors.any((e) => e.path.contains('y')), isTrue);
      });

      test('only the matched schema is validated (fast-path)', () {
        // If the keypress schema were tried for 'click', key would be missing.
        // With discriminatedBy, only the matching schema is validated.
        final schema = z.union([
          z.object({'type': z.literal('click'), 'x': z.int(), 'y': z.int()}),
          z.object({'type': z.literal('keypress'), 'key': z.string()}),
        ]).discriminatedBy('type');

        final result = schema.safeParse({'type': 'click', 'x': 10, 'y': 20});
        expect(result.isSuccess, isTrue);
      });

      test('discriminatedBy returns new ZemaUnion, original is unchanged', () {
        final base = z.union([
          z.object({'type': z.literal('a')}),
        ]);
        final discriminated = base.discriminatedBy('type');

        expect(discriminated.discriminator, equals('type'));
        expect(base.discriminator, isNull);
      });
    });
  });
}
