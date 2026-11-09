import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('parseInIsolate()', () {
    test('returns the same result as safeParse', () async {
      final schema = z.object({'n': z.integer().positive()});

      expect((await schema.parseInIsolate({'n': 1})).isSuccess, isTrue);
      expect((await schema.parseInIsolate({'n': -1})).isFailure, isTrue);
    });
  });
}
