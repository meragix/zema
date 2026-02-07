import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('Environment Variable Validation', () {
    test('validates complete environment configuration', () {
      final envSchema = Z.object({
        'NODE_ENV': Z.string.oneOf(['development', 'production', 'test']),
        'PORT': Z.coerce.integer(min: 1, max: 65535),
        'DB_HOST': Z.string,
        'DB_PORT': Z.coerce.integer(),
        'DB_NAME': Z.string.min(1),
        'DB_USER': Z.string.min(1),
        'DB_PASSWORD': Z.string.nullable(),
        'ENABLE_LOGGING': Z.coerce.boolean(),
        'LOG_LEVEL': Z.string.oneOf(['debug', 'info', 'warn', 'error']),
        'JWT_SECRET': Z.string.min(32),
        'MAX_CONNECTIONS': Z.coerce.integer().withDefault(100),
      });

      final envVars = {
        'NODE_ENV': 'production',
        'PORT': '8080',
        'DB_HOST': 'localhost',
        'DB_PORT': '5432',
        'DB_NAME': 'myapp',
        'DB_USER': 'admin',
        'DB_PASSWORD': null,
        'ENABLE_LOGGING': 'true',
        'LOG_LEVEL': 'info',
        'JWT_SECRET': 'this_is_a_very_long_secret_key_for_jwt_tokens',
        'MAX_CONNECTIONS': null, // Should use default
      };

      final result = envSchema.safeParse(envVars);

      expect(result.$2, isNull);
      expect(result.$1!['PORT'], equals(8080));
      expect(result.$1!['PORT'], isA<int>());
      expect(result.$1!['ENABLE_LOGGING'], isTrue);
      expect(result.$1!['MAX_CONNECTIONS'], equals(100));
    });

    test('collects all environment validation errors', () {
      final envSchema = Z.object({
        'NODE_ENV': Z.string.oneOf(['development', 'production']),
        'PORT': Z.coerce.integer(min: 1, max: 65535),
        'JWT_SECRET': Z.string.min(32),
      });

      final badEnv = {
        'NODE_ENV': 'staging', // Invalid enum
        'PORT': '99999', // Out of range
        'JWT_SECRET': 'short', // Too short
      };

      final result = envSchema.safeParse(badEnv);

      expect(result.$2, isNotNull);
      expect(result.$2!.length, equals(3));

      final paths = result.$2!.map((e) => e.path.join('.')).toList();
      expect(paths, contains('NODE_ENV'));
      expect(paths, contains('PORT'));
      expect(paths, contains('JWT_SECRET'));
    });
  });
}
