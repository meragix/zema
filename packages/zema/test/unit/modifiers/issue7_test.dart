import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('issue #7 - refine on object with empty input', () {
    test('refine predicate is called on empty object with all-optional fields',
        () {
      var refineCalled = false;

      final schema = z.object({
        'name': z.string().optional(),
      }).refine((vals) {
        refineCalled = true;
        return false;
      });

      final result = schema.safeParse(<String, dynamic>{});

      expect(refineCalled, isTrue);
      expect(result.isFailure, isTrue);
    });

    test('empty input produces empty output map', () {
      final schema = z.object({
        'name': z.string().optional(),
      });

      final result = schema.safeParse(<String, dynamic>{});
      expect(result.isSuccess, isTrue);
      expect((result as ZemaSuccess).value, isEmpty);
    });

    test('present keys are kept, missing optional keys are omitted', () {
      final schema = z.object({
        'name': z.string().optional(),
        'age': z.int().optional(),
      });

      final result = schema.safeParse(<String, dynamic>{'name': 'Alice'});
      expect(result.isSuccess, isTrue);
      expect((result as ZemaSuccess).value, {'name': 'Alice'});
    });

    test('required fields still fail on missing input', () {
      final schema = z.object({
        'name': z.string(),
      });

      final result = schema.safeParse(<String, dynamic>{});
      expect(result.isFailure, isTrue);
    });

    test('withDefault still populates the key', () {
      final schema = z.object({
        'role': z.string().withDefault('user'),
      });

      final result = schema.safeParse(<String, dynamic>{});
      expect(result.isSuccess, isTrue);
      expect((result as ZemaSuccess).value, {'role': 'user'});
    });
  });
}
