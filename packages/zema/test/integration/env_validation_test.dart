import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('Environment Variable Validation', () {
    test('validates complete environment configuration', () {
      final envSchema = z.object({
        'NODE_ENV': z.string().oneOf(['development', 'production', 'test']),
        'PORT': z.coerce().integer(min: 1, max: 65535),
        'DB_HOST': z.string(),
        'DB_PORT': z.coerce().integer(),
        'DB_NAME': z.string().min(1),
        'DB_USER': z.string().min(1),
        //'DB_PASSWORD': z.string().nullable(),
        'ENABLE_LOGGING': z.coerce().boolean(),
        'LOG_LEVEL': z.string().oneOf(['debug', 'info', 'warn', 'error']),
        'JWT_SECRET': z.string().min(32),
        //'MAX_CONNECTIONS': z.coerce().integer().withDefault(100),
      });

      final envVars = {
        'NODE_ENV': 'production',
        'PORT': '8080',
        'DB_HOST': 'localhost',
        'DB_PORT': '5432',
        'DB_NAME': 'myapp',
        'DB_USER': 'admin',
       // 'DB_PASSWORD': null,
        'ENABLE_LOGGING': 'true',
        'LOG_LEVEL': 'info',
        'JWT_SECRET': 'this_is_a_very_long_secret_key_for_jwt_tokens',
        //'MAX_CONNECTIONS': null, // Should use default
      };

      final result = envSchema.safeParse(envVars);

      expect(result.isSuccess, isTrue);
      expect(result.value['PORT'], equals(8080));
      expect(result.value['PORT'], isA<int>());
      expect(result.value['ENABLE_LOGGING'], isTrue);
      // expect(result.value['MAX_CONNECTIONS'], equals(100));
    });

    test('collects all environment validation errors', () {
      final envSchema = z.object({
        'NODE_ENV': z.string().oneOf(['development', 'production']),
        'PORT': z.coerce().integer(min: 1, max: 65535),
        'JWT_SECRET': z.string().min(32),
      });

      final badEnv = {
        'NODE_ENV': 'staging', // Invalid enum
        'PORT': '99999', // Out of range
        'JWT_SECRET': 'short', // Too short
      };

      final result = envSchema.safeParse(badEnv);

      expect(result.isSuccess, isFalse);
      expect(result.errors.length, equals(3));

      final paths = result.errors.map((e) => e.path.join('.')).toList();
      expect(paths, contains('NODE_ENV'));
      expect(paths, contains('PORT'));
      expect(paths, contains('JWT_SECRET'));
    });
  });
}
