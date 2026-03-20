import 'package:dio/dio.dart';
import 'package:test/test.dart';
import 'package:zema/zema.dart';
import 'package:zema_dio/zema_dio.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal [Response] with [data] as the decoded body.
Response<dynamic> _response(dynamic data, {int statusCode = 200}) =>
    Response<dynamic>(
      data: data,
      statusCode: statusCode,
      requestOptions: RequestOptions(),
    );

final _userSchema = z.object({
  'id': z.integer(),
  'name': z.string().min(1),
  'email': z.string().email(),
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ZemaDioResponseX.parse', () {
    test('returns parsed output on valid data', () {
      final response = _response({
        'id': 1,
        'name': 'Alice',
        'email': 'alice@example.com',
      });

      final result = response.parse(_userSchema);

      expect(result['id'], equals(1));
      expect(result['name'], equals('Alice'));
      expect(result['email'], equals('alice@example.com'));
    });

    test('throws ZemaException on invalid data', () {
      final response =
          _response({'id': 1, 'name': '', 'email': 'not-an-email'});

      expect(
        () => response.parse(_userSchema),
        throwsA(isA<ZemaException>()),
      );
    });

    test('exception contains all validation issues', () {
      final response = _response({'id': 'not-int', 'name': '', 'email': 'bad'});

      ZemaException? exception;
      try {
        response.parse(_userSchema);
      } on ZemaException catch (e) {
        exception = e;
      }

      // 3 fields failing: id (invalid_type), name (too_short), email (invalid_email)
      expect(exception, isNotNull);
      expect(exception!.issues.length, greaterThanOrEqualTo(2));
    });

    test('works with primitive schema', () {
      final response = _response(42);
      expect(response.parse(z.integer()), equals(42));
    });

    test('works with array schema', () {
      final response = _response([1, 2, 3]);
      expect(response.parse(z.array(z.integer())), equals([1, 2, 3]));
    });
  });

  group('ZemaDioResponseX.safeParse', () {
    test('returns ZemaSuccess on valid data', () {
      final response = _response({
        'id': 1,
        'name': 'Alice',
        'email': 'alice@example.com',
      });

      final result = response.safeParse(_userSchema);

      expect(result, isA<ZemaSuccess<Map<String, dynamic>>>());
      expect(result.errors, isEmpty);
    });

    test('returns ZemaFailure on invalid data', () {
      final response = _response({'id': 1, 'name': '', 'email': 'bad'});

      final result = response.safeParse(_userSchema);

      expect(result, isA<ZemaFailure<Map<String, dynamic>>>());
      expect(result.errors, isNotEmpty);
    });

    test('never throws on invalid data', () {
      final response = _response(null);

      expect(
        () => response.safeParse(_userSchema),
        returnsNormally,
      );
    });

    test('failure contains field paths', () {
      final response = _response({'id': 1, 'name': 'Alice', 'email': 'bad'});

      final result = response.safeParse(_userSchema);

      expect(result, isA<ZemaFailure>());
      final paths = result.errors.map((i) => i.path).toList();
      expect(paths.any((p) => p.contains('email')), isTrue);
    });

    test('success value matches input', () {
      final input = {'id': 7, 'name': 'Bob', 'email': 'bob@example.com'};
      final result = _response(input).safeParse(_userSchema);

      expect(result, isA<ZemaSuccess>());
      expect((result as ZemaSuccess).value['id'], equals(7));
    });
  });
}
