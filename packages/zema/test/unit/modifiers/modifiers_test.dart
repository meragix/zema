import 'package:test/test.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/factory.dart';
import 'package:zema/src/modifiers/branded.dart';

// Brand marker classes used in brand() tests — must be top-level in Dart.
abstract class _UserIdBrand {}

abstract class _TeamIdBrand {}

abstract class _Brand {}

void main() {
  group('optional()', () {
    test('passes null through as success with null value', () {
      final schema = z.string().optional();
      final result = schema.safeParse(null);

      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });

    test('validates non-null values normally', () {
      final schema = z.string().min(5).optional();

      expect(schema.safeParse('hello').isSuccess, isTrue);
      expect(schema.safeParse('hi').isFailure, isTrue);
    });

    test('passes null when non-null validation would fail', () {
      final schema = z.string().email().optional();

      expect(schema.safeParse(null).isSuccess, isTrue);
      expect(schema.safeParse(null).value, isNull);
    });

    test('works inside ZemaObject for absent fields', () {
      final schema = z.object({
        'name': z.string(),
        'nickname': z.string().optional(),
      });

      final result = schema.safeParse({'name': 'Alice'});
      expect(result.isSuccess, isTrue);
      expect(result.value['nickname'], isNull);
    });

    test('errors on non-null invalid values', () {
      final schema = z.int().positive().optional();

      expect(schema.safeParse(-5).isFailure, isTrue);
      expect(schema.safeParse(null).isSuccess, isTrue);
    });
  });

  group('nullable()', () {
    test('passes null through as success with null value', () {
      final schema = z.string().nullable();
      final result = schema.safeParse(null);

      expect(result.isSuccess, isTrue);
      expect(result.value, isNull);
    });

    test('validates non-null values normally', () {
      final schema = z.int().positive().nullable();

      expect(schema.safeParse(10).isSuccess, isTrue);
      expect(schema.safeParse(-5).isFailure, isTrue);
    });

    test('errors on non-null invalid values', () {
      final schema = z.string().email().nullable();

      expect(schema.safeParse('not-an-email').isFailure, isTrue);
      expect(schema.safeParse(null).isSuccess, isTrue);
    });
  });

  group('withDefault()', () {
    test('returns default when input is null', () {
      final schema = z.string().withDefault('anonymous');
      final result = schema.safeParse(null);

      expect(result.isSuccess, isTrue);
      expect(result.value, equals('anonymous'));
    });

    test('returns parsed value when input is valid', () {
      final schema = z.string().withDefault('anonymous');
      expect(schema.safeParse('Alice').value, equals('Alice'));
    });

    test('returns default when base schema fails', () {
      final schema = z.int().positive().withDefault(0);

      expect(schema.safeParse(-5).isSuccess, isTrue);
      expect(schema.safeParse(-5).value, equals(0));
    });

    test('returns parsed value when base schema succeeds', () {
      final schema = z.int().positive().withDefault(0);
      expect(schema.safeParse(10).value, equals(10));
    });

    test('works with integer defaults', () {
      final schema = z.int().withDefault(42);
      expect(schema.safeParse(null).value, equals(42));
    });

    test('works with boolean defaults', () {
      final schema = z.boolean().withDefault(false);
      expect(schema.safeParse(null).value, equals(false));
    });
  });

  group('catchError()', () {
    test('returns fallback value on failure', () {
      final schema = z.int().positive().catchError((_) => 0);

      expect(schema.safeParse(-5).isSuccess, isTrue);
      expect(schema.safeParse(-5).value, equals(0));
    });

    test('forwards success unchanged', () {
      final schema = z.int().positive().catchError((_) => 0);
      expect(schema.safeParse(10).value, equals(10));
    });

    test('handler receives the list of issues', () {
      List<ZemaIssue>? captured;

      final schema = z.string().email().catchError((issues) {
        captured = issues;
        return 'fallback@example.com';
      });

      schema.safeParse('not-an-email');

      expect(captured, isNotNull);
      expect(captured, isNotEmpty);
    });

    test('schema always succeeds (never propagates failure)', () {
      final schema = z.int().positive().catchError((_) => -1);

      expect(schema.safeParse(-100).isFailure, isFalse);
      expect(schema.safeParse(-100).value, equals(-1));
    });

    test('handler can inspect issue codes', () {
      final schema = z.string().email().catchError((issues) {
        final hasEmailIssue = issues.any((e) => e.code == 'invalid_email');
        return hasEmailIssue ? 'invalid-email' : 'other-error';
      });

      expect(schema.safeParse('not-an-email').value, equals('invalid-email'));
    });
  });

  group('brand()', () {
    test('wraps valid output in Branded', () {
      final schema = z.string().uuid().brand<_UserIdBrand>();
      final result = schema.safeParse('550e8400-e29b-41d4-a716-446655440000');

      expect(result.isSuccess, isTrue);
      expect(result.value, isA<Branded<String, _UserIdBrand>>());
    });

    test('Branded.value holds the underlying validated value', () {
      final schema = z.string().brand<_UserIdBrand>();
      final branded = schema.safeParse('hello').value;

      expect(branded.value, equals('hello'));
    });

    test('fails when base schema fails', () {
      final schema = z.string().uuid().brand<_UserIdBrand>();
      expect(schema.safeParse('not-a-uuid').isFailure, isTrue);
    });

    test('two branded schemas with different brands are distinct types', () {
      final userIdSchema = z.string().brand<_UserIdBrand>();
      final teamIdSchema = z.string().brand<_TeamIdBrand>();

      final userId = userIdSchema.safeParse('abc').value;
      final teamId = teamIdSchema.safeParse('abc').value;

      // Both hold 'abc' but are different Branded types
      expect(userId.value, equals(teamId.value));
      expect(userId, isNot(isA<Branded<String, _TeamIdBrand>>()));
    });

    test('Branded equality is based on underlying value', () {
      final schema = z.string().brand<_Brand>();
      final a = schema.safeParse('hello').value;
      final b = schema.safeParse('hello').value;

      expect(a, equals(b));
    });
  });
}
