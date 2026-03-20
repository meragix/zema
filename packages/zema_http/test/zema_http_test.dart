import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:zema/zema.dart';
import 'package:zema_http/zema_http.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds a minimal [http.Response] with [body] as the JSON-encoded body.
http.Response _response(Object? body, {int statusCode = 200}) =>
    http.Response(jsonEncode(body), statusCode);

/// Builds an [http.Response] with a raw (non-JSON) string body.
http.Response _rawResponse(String body, {int statusCode = 200}) =>
    http.Response(body, statusCode);

final _userSchema = z.object({
  'id': z.integer(),
  'name': z.string().min(1),
  'email': z.string().email(),
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ZemaHttpResponseX.parse', () {
    test('returns parsed output on valid JSON body', () {
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

    test('throws ZemaException on schema validation failure', () {
      final response = _response({'id': 1, 'name': '', 'email': 'not-valid'});

      expect(
        () => response.parse(_userSchema),
        throwsA(isA<ZemaException>()),
      );
    });

    test('throws FormatException on non-JSON body', () {
      final response = _rawResponse('not json at all');

      expect(
        () => response.parse(_userSchema),
        throwsA(isA<FormatException>()),
      );
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

  group('ZemaHttpResponseX.safeParse', () {
    test('returns ZemaSuccess on valid JSON body', () {
      final response = _response({
        'id': 1,
        'name': 'Alice',
        'email': 'alice@example.com',
      });

      final result = response.safeParse(_userSchema);

      expect(result, isA<ZemaSuccess<Map<String, dynamic>>>());
      expect(result.errors, isEmpty);
    });

    test('returns ZemaFailure on schema validation failure', () {
      final response = _response({'id': 1, 'name': '', 'email': 'bad'});

      final result = response.safeParse(_userSchema);

      expect(result, isA<ZemaFailure<Map<String, dynamic>>>());
      expect(result.errors, isNotEmpty);
    });

    test('returns ZemaFailure with invalid_json on non-JSON body', () {
      final response = _rawResponse('not json');

      final result = response.safeParse(_userSchema);

      expect(result, isA<ZemaFailure>());
      expect(result.errors.first.code, equals('invalid_json'));
    });

    test('never throws on invalid data', () {
      final response = _response(null);

      expect(
        () => response.safeParse(_userSchema),
        returnsNormally,
      );
    });

    test('never throws on malformed JSON', () {
      final response = _rawResponse('{bad json');

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

    test('invalid_json error includes raw body as receivedValue', () {
      final response = _rawResponse('not json');

      final result = response.safeParse(_userSchema);
      expect(result.errors.first.receivedValue, equals('not json'));
    });
  });
}
