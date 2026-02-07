import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('ZemaBool', () {
    test('accepts true', () {
      final schema = z.boolean;
      final result = schema.safeParse(true);

      expect(result.$1, isTrue);
      expect(result.$2, isNull);
    });

    test('accepts false', () {
      final schema = z.boolean;
      final result = schema.safeParse(false);

      expect(result.$1, isFalse);
      expect(result.$2, isNull);
    });

    test('rejects non-boolean', () {
      final schema = z.boolean;

      expect(schema.safeParse(1).$2, isNotNull);
      expect(schema.safeParse('true').$2, isNotNull);
      expect(schema.safeParse(null).$2, isNotNull);
    });

    test('error has correct code', () {
      final schema = z.boolean;
      final result = schema.safeParse('true');

      expect(result.$2!.first.code, equals('invalid_type'));
    });
  });
}
