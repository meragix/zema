import 'package:test/test.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/zema.dart';

void main() {
  group('optional()', () {
    test('passes null through', () {
      final schema = z.string.optional();
      final result = schema.safeParse(null);

      expect(result.$1, isNull);
      expect(result.$2, isNull);
    });

    test('validates non-null values', () {
      final schema = z.string.min(5).optional();

      expect(schema.safeParse('hello').$2, isNull);
      expect(schema.safeParse('hi').$2, isNotNull);
      expect(schema.safeParse(null).$2, isNull);
    });

    test('works with complex types', () {
      final schema = z.object({
        'name': z.string,
        'nickname': z.string.optional(),
      });

      expect(
        schema.safeParse({'name': 'Alice'}).$2,
        isNull,
      );
    });
  });

  group('nullable()', () {
    test('passes null through', () {
      final schema = z.string.nullable();
      final result = schema.safeParse(null);

      expect(result.$1, isNull);
      expect(result.$2, isNull);
    });

    test('validates non-null values', () {
      final schema = z.int.positive().nullable();

      expect(schema.safeParse(10).$2, isNull);
      expect(schema.safeParse(-5).$2, isNotNull);
      expect(schema.safeParse(null).$2, isNull);
    });
  });

  group('withDefault()', () {
    test('returns default for null', () {
      final schema = z.string.withDefault('default');
      final result = schema.safeParse(null);

      expect(result.$1, equals('default'));
      expect(result.$2, isNull);
    });

    test('returns default on validation error', () {
      final schema = z.int.positive().withDefault(0);

      expect(schema.safeParse(-5).$1, equals(0));
      expect(schema.safeParse(10).$1, equals(10));
    });

    test('works with coercion', () {
      final schema = z.coerce.integer().withDefault(100);

      expect(schema.safeParse(null).$1, equals(100));
      expect(schema.safeParse('50').$1, equals(50));
      expect(schema.safeParse('invalid').$1, equals(100));
    });
  });

  group('catchError()', () {
    test('catches errors and returns fallback', () {
      final schema = z.int.positive().catchError((issues) => 0);

      expect(schema.safeParse(-5).$1, equals(0));
      expect(schema.safeParse(10).$1, equals(10));
    });

    test('handler receives all issues', () {
      List<ZemaIssue>? capturedIssues;

      final schema = z.string.min(5).email().catchError((issues) {
        capturedIssues = issues;
        return 'fallback';
      });

      schema.safeParse('ab');

      expect(capturedIssues, isNotNull);
      expect(capturedIssues!.length, equals(2));
    });
  });
}
