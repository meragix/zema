import 'package:standard_schema/standard_schema.dart';
import 'package:test/test.dart';
import 'package:zema/zema.dart';
import 'package:zema_standard_schema/zema_standard_schema.dart';

void main() {
  group('ZemaStandardAdapter', () {
    test('wraps a valid schema and returns StandardSuccess', () {
      final schema = z.string().min(3);
      final adapter = ZemaStandardAdapter(schema);

      final result = adapter.standard.validate('hello');

      expect(result, isA<StandardSuccess<String>>());
      expect((result as StandardSuccess<String>).value, 'hello');
    });

    test('returns StandardFailure on invalid input', () {
      final schema = z.string().min(3);
      final adapter = ZemaStandardAdapter(schema);

      final result = adapter.standard.validate('ab');

      expect(result, isA<StandardFailure<String>>());
      final failure = result as StandardFailure<String>;
      expect(failure.issues, isNotEmpty);
      expect(failure.issues.first.message, isNotEmpty);
    });

    test('maps issue path correctly', () {
      final schema = z.object({
        'name': z.string().min(2),
      });
      final adapter = ZemaStandardAdapter(schema);

      final result = adapter.standard.validate(<String, dynamic>{'name': 'X'});

      expect(result, isA<StandardFailure<Map<String, dynamic>>>());
      final failure = result as StandardFailure<Map<String, dynamic>>;
      expect(failure.issues.first.path, contains('name'));
    });

    test('reports vendor as zema', () {
      final schema = z.string();
      final adapter = ZemaStandardAdapter(schema);

      expect(adapter.standard.vendor, 'zema');
    });

    test('filters out warning-level issues', () {
      final schema = z.string().min(1).refineWarn(
            (value) => value.length > 5,
            message: 'Value is unusually long',
          );
      final adapter = ZemaStandardAdapter(schema);

      // 'hello' is valid (min 1) but triggers the warning (length <= 5)
      final result = adapter.standard.validate('hello');

      expect(result, isA<StandardSuccess<String>>());
      final success = result as StandardSuccess<String>;
      expect(success.value, 'hello');
    });
  });

  group('ZemaStandardSchemaExtension', () {
    test('.asStandard returns a StandardSchemaV1', () {
      final schema = z.int().gte(0);
      final standard = schema.asStandard;

      expect(standard, isA<StandardSchemaV1<dynamic, int>>());
    });

    test('.asStandard validates correctly', () {
      final schema = z.int().gte(0);
      final standard = schema.asStandard;

      final success = standard.standard.validate(42);
      expect(success, isA<StandardSuccess<int>>());
      expect((success as StandardSuccess<int>).value, 42);

      final failure = standard.standard.validate('not a number');
      expect(failure, isA<StandardFailure<int>>());
    });

    test('.asStandard returns failure for invalid input', () {
      final schema = z.int().gte(0);
      final standard = schema.asStandard;

      final result = standard.standard.validate('not a number');

      expect(result, isA<StandardFailure<int>>());
    });
  });

  group('zemaIssueToStandard', () {
    test('maps message and path', () {
      const zemaIssue = ZemaIssue(
        code: 'too_short',
        message: 'Must be at least 3 characters',
        path: ['name'],
      );

      final standardIssue = zemaIssueToStandard(zemaIssue);

      expect(standardIssue.message, 'Must be at least 3 characters');
      expect(standardIssue.path, ['name']);
    });

    test('preserves empty path as root', () {
      const zemaIssue = ZemaIssue(
        code: 'invalid_type',
        message: 'Expected string',
      );

      final standardIssue = zemaIssueToStandard(zemaIssue);

      expect(standardIssue.path, isEmpty);
    });
  });

  group('zemaIssuesToStandard', () {
    test('filters out warnings', () {
      final issues = [
        const ZemaIssue(
          code: 'too_short',
          message: 'Too short',
          severity: ZemaSeverity.error,
        ),
        const ZemaIssue(
          code: 'custom',
          message: 'Just a warning',
          severity: ZemaSeverity.warning,
        ),
      ];

      final result = zemaIssuesToStandard(issues);

      expect(result, hasLength(1));
      expect(result.first.message, 'Too short');
    });

    test('returns empty list when all issues are warnings', () {
      final issues = [
        const ZemaIssue(
          code: 'custom',
          message: 'Warning only',
          severity: ZemaSeverity.warning,
        ),
      ];

      final result = zemaIssuesToStandard(issues);

      expect(result, isEmpty);
    });
  });
}
