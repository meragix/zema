import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaString', () {
    group('Type validation', () {
      test('accepts valid string', () {
        final schema = z.string();
        final result = schema.safeParse('hello');

        expect(result.$1, equals('hello'));
        expect(result.$2, isNull);
      });

      test('rejects non-string', () {
        final schema = z.string;
        final result = schema.safeParse(123);

        expect(result.$1, isNull);
        expect(result.$2, isNotNull);
        expect(result.$2!.first.code, equals('invalid_type'));
        expect(result.$2!.first.message, contains('Expected string'));
      });

      test('rejects null', () {
        final schema = z.string;
        final result = schema.safeParse(null);

        expect(result.$1, isNull);
        expect(result.$2, isNotNull);
        expect(result.$2!.first.code, equals('invalid_type'));
      });
    });

    group('Length validation', () {
      test('validates minimum length', () {
        final schema = z.string.min(5);

        expect(schema.safeParse('hello').$2, isNull);
        expect(schema.safeParse('hi').$2, isNotNull);
        expect(schema.safeParse('hi').$2!.first.code, equals('too_short'));
      });

      test('validates maximum length', () {
        final schema = z.string.max(5);

        expect(schema.safeParse('hello').$2, isNull);
        expect(schema.safeParse('hello world').$2, isNotNull);
        expect(
            schema.safeParse('hello world').$2!.first.code, equals('too_long'));
      });

      test('validates exact length', () {
        final schema = z.string.length(5);

        expect(schema.safeParse('hello').$2, isNull);
        expect(schema.safeParse('hi').$2, isNotNull);
        expect(schema.safeParse('hello world').$2, isNotNull);
      });

      test('validates min and max together', () {
        final schema = z.string.min(2).max(5);

        expect(schema.safeParse('hi').$2, isNull);
        expect(schema.safeParse('hello').$2, isNull);
        expect(schema.safeParse('a').$2, isNotNull);
        expect(schema.safeParse('toolong').$2, isNotNull);
      });
    });

    group('Trim modifier', () {
      test('trims whitespace', () {
        final schema = z.string.trim();
        final result = schema.safeParse('  hello  ');

        expect(result.$1, equals('hello'));
        expect(result.$2, isNull);
      });

      test('trim works with validation', () {
        final schema = z.string.trim().min(5);

        // " hi " becomes "hi" (length 2)
        expect(schema.safeParse('  hi  ').$2, isNotNull);

        // " hello " becomes "hello" (length 5)
        expect(schema.safeParse('  hello  ').$2, isNull);
      });
    });

    group('Email validation', () {
      test('accepts valid emails', () {
        final schema = z.string.email();

        final validEmails = [
          'test@example.com',
          'user.name@example.com',
          'user+tag@example.co.uk',
          'user_123@example.com',
        ];

        for (final email in validEmails) {
          expect(
            schema.safeParse(email).$2,
            isNull,
            reason: '$email should be valid',
          );
        }
      });

      test('rejects invalid emails', () {
        final schema = z.string.email();

        final invalidEmails = [
          'not-an-email',
          '@example.com',
          'user@',
          'user @example.com',
          'user@.com',
        ];

        for (final email in invalidEmails) {
          expect(
            schema.safeParse(email).$2,
            isNotNull,
            reason: '$email should be invalid',
          );
          expect(
            schema.safeParse(email).$2!.first.code,
            equals('invalid_email'),
          );
        }
      });
    });

    group('URL validation', () {
      test('accepts valid URLs', () {
        final schema = z.string.url();

        final validUrls = [
          'https://example.com',
          'http://example.com',
          'https://example.com/path',
          'https://example.com:8080',
        ];

        for (final url in validUrls) {
          expect(
            schema.safeParse(url).$2,
            isNull,
            reason: '$url should be valid',
          );
        }
      });

      test('rejects invalid URLs', () {
        final schema = z.string.url();

        final invalidUrls = [
          'not-a-url',
          'ftp://example.com',
          'example.com',
          '//example.com',
        ];

        for (final url in invalidUrls) {
          expect(
            schema.safeParse(url).$2,
            isNotNull,
            reason: '$url should be invalid',
          );
        }
      });
    });

    group('UUID validation', () {
      test('accepts valid UUIDs', () {
        final schema = z.string.uuid();

        final validUuids = [
          '550e8400-e29b-41d4-a716-446655440000',
          '123e4567-e89b-12d3-a456-426614174000',
        ];

        for (final uuid in validUuids) {
          expect(
            schema.safeParse(uuid).$2,
            isNull,
            reason: '$uuid should be valid',
          );
        }
      });

      test('rejects invalid UUIDs', () {
        final schema = z.string.uuid();

        final invalidUuids = [
          'not-a-uuid',
          '550e8400-e29b-41d4-a716',
          '550e8400-e29b-41d4-a716-446655440000-extra',
        ];

        for (final uuid in invalidUuids) {
          expect(
            schema.safeParse(uuid).$2,
            isNotNull,
            reason: '$uuid should be invalid',
          );
        }
      });
    });

    group('Enum validation', () {
      test('accepts values in enum', () {
        final schema = z.string.oneOf(['red', 'green', 'blue']);

        expect(schema.safeParse('red').$2, isNull);
        expect(schema.safeParse('green').$2, isNull);
        expect(schema.safeParse('blue').$2, isNull);
      });

      test('rejects values not in enum', () {
        final schema = z.string.oneOf(['red', 'green', 'blue']);

        final result = schema.safeParse('yellow');
        expect(result.$2, isNotNull);
        expect(result.$2!.first.code, equals('invalid_enum'));
        expect(result.$2!.first.message, contains('red, green, blue'));
      });
    });

    group('Custom regex', () {
      test('validates against custom pattern', () {
        final schema = z.string.regex(RegExp(r'^\d{3}-\d{4}$'));

        expect(schema.safeParse('123-4567').$2, isNull);
        expect(schema.safeParse('abc-defg').$2, isNotNull);
        expect(schema.safeParse('123-456').$2, isNotNull);
      });
    });

    group('Multiple error accumulation', () {
      test('collects multiple validation errors', () {
        final schema = z.string.min(10).email();
        final result = schema.safeParse('ab');

        expect(result.$2, isNotNull);
        expect(result.$2!.length, equals(2));

        final codes = result.$2!.map((e) => e.code).toList();
        expect(codes, contains('too_short'));
        expect(codes, contains('invalid_email'));
      });
    });

    group('Chaining', () {
      test('chains multiple validations fluently', () {
        final schema = z.string.trim().min(5).max(50).email();

        final result = schema.safeParse('  test@example.com  ');
        expect(result.$1, equals('test@example.com'));
        expect(result.$2, isNull);
      });
    });

    group('parse() method', () {
      test('returns value on success', () {
        final schema = z.string.min(2);
        final result = schema.parse('hello');

        expect(result, equals('hello'));
      });

      test('throws ZemaException on failure', () {
        final schema = z.string.min(5);

        expect(
          () => schema.parse('hi'),
          throwsA(isA<ZemaException>()),
        );
      });

      test('ZemaException contains all issues', () {
        final schema = z.string.min(10).email();

        try {
          schema.parse('ab');
          fail('Should have thrown');
        } on ZemaException catch (e) {
          expect(e.issues.length, equals(2));
        }
      });
    });
  });
}
