import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('pipe()', () {
    test('accepts built-in schemas after transform', () {
      final schema =
          z.string().transform(int.parse).pipe(z.integer().gte(0).lte(100));

      expect(schema.parse('42'), 42);
      expect(schema.safeParse('150').isFailure, isTrue);
      expect(schema.safeParse('abc').errors.first.code, 'transform_error');
    });

    test('accepts coercion schemas', () {
      final schema = z.string().regex(RegExp(r'^\d+$')).pipe(
            z.coerce().integer(),
          );

      expect(schema.parse('7'), 7);
      expect(schema.safeParse('x').isFailure, isTrue);
    });

    test('stops at the first stage on failure', () {
      final schema = z.string().min(3).pipe(z.string().email());
      final result = schema.safeParse('ab');

      expect(result.errors.single.code, 'too_short');
    });

    test('works through safeParseAsync', () async {
      final schema = z.string().transform(int.parse).pipe(z.integer());

      expect((await schema.safeParseAsync('3')).value, 3);
    });
  });
}
