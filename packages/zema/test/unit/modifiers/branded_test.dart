import 'package:test/test.dart';
import 'package:zema/zema.dart';

abstract class _UserIdBrand {}

void main() {
  group('brand()', () {
    test('is reachable from the public library', () {
      final schema = z.string().uuid().brand<_UserIdBrand>();
      const raw = '550e8400-e29b-41d4-a716-446655440000';
      final id = schema.parse(raw);

      expect(id, isA<Branded<String, _UserIdBrand>>());
      expect(id.value, raw);
    });
  });
}
