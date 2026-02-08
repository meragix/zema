import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('ZemaBool', () {
    test('accepts true', () {
      final schema = z.boolean();
      final result = schema.safeParse(true);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('accepts false', () {
      final schema = z.boolean();
      final result = schema.safeParse(false);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
    });

    test('rejects non-boolean', () {
      final schema = z.boolean();

      expect(schema.safeParse(1).errors, isNotNull);
      expect(schema.safeParse('true').errors, isNotNull);
      expect(schema.safeParse(null).errors, isNotNull);
    });

    test('error has correct code', () {
      final schema = z.boolean();
      final result = schema.safeParse('true');

      expect(result.errors.first.code, equals('invalid_type'));
    });
  });
}
