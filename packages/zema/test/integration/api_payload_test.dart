import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('API Payload Validation', () {
    test('validates REST API create user payload', () {
      final createUserSchema = z.object({
        'email': z.string.email(),
        'password': z.string.min(8),
        'name': z.string.min(2),
        'age': z.int.gte(18).lte(120).optional(),
        'acceptTerms': z.boolean,
      });

      final payload = {
        'email': 'user@example.com',
        'password': 'securePassword123',
        'name': 'John Doe',
        'age': 25,
        'acceptTerms': true,
      };

      final result = createUserSchema.safeParse(payload);
      expect(result.$2, isNull);
    });

    test('validates with extra fields (non-strict)', () {
      final schema = z.object({
        'id': z.int,
        'name': z.string,
      });

      final payload = {
        'id': 1,
        'name': 'Test',
        'extraField': 'ignored',
      };

      final result = schema.safeParse(payload);
      expect(result.$2, isNull); // Extra fields ignored by default
    });

    test('validates strictly when required', () {
      final schema = z.object({
        'id': z.int,
        'name': z.string,
      }).makeStrict();

      final payload = {
        'id': 1,
        'name': 'Test',
        'extraField': 'not allowed',
      };

      final result = schema.safeParse(payload);
      expect(result.$2, isNotNull);
      expect(result.$2!.first.code, equals('unknown_key'));
    });
  });
}
