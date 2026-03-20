// ignore_for_file: avoid_print

import 'package:http/http.dart' as http;
import 'package:zema/zema.dart';
import 'package:zema_http/zema_http.dart';

// ---------------------------------------------------------------------------
// Schemas — defined once at module scope, reused for every request.
// ---------------------------------------------------------------------------

final _userSchema = z.object({
  'id': z.integer(),
  'name': z.string().min(1),
  'email': z.string().email(),
});

final _postSchema = z.object({
  'id': z.integer(),
  'userId': z.integer(),
  'title': z.string().min(1),
  'body': z.string(),
});

final _postsSchema = z.array(_postSchema);

const _base = 'https://jsonplaceholder.typicode.com';

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final client = http.Client();

  try {
    await _exampleSafeParse(client);
    await _exampleParse(client);
    await _exampleList(client);
    await _exampleInvalidJson(client);
    await _exampleSchemaFailure(client);
  } finally {
    client.close();
  }
}

// --- safeParse: never throws, handle both branches with switch ---

Future<void> _exampleSafeParse(http.Client client) async {
  print('\n--- safeParse ---');

  final response = await client.get(Uri.parse('$_base/users/1'));
  final result = response.safeParse(_userSchema);

  switch (result) {
    case ZemaSuccess(:final value):
      print('User: ${value['name']} <${value['email']}>');
    case ZemaFailure(:final errors):
      for (final issue in errors) {
        print('  [${issue.path.join(".")}] ${issue.message}');
      }
  }
}

// --- parse: throws ZemaException on failure ---

Future<void> _exampleParse(http.Client client) async {
  print('\n--- parse ---');

  try {
    final response = await client.get(Uri.parse('$_base/users/2'));
    final user = response.parse(_userSchema);
    print('User: ${user['name']}');
  } on ZemaException catch (e) {
    print('Validation failed: ${e.issues.map((i) => i.message).join(", ")}');
  }
}

// --- array response ---

Future<void> _exampleList(http.Client client) async {
  print('\n--- list (array schema) ---');

  final response = await client.get(Uri.parse('$_base/posts'));
  final result = response.safeParse(_postsSchema);

  switch (result) {
    case ZemaSuccess(:final value):
      print('Fetched ${value.length} posts. First: "${value.first['title']}"');
    case ZemaFailure(:final errors):
      print('${errors.length} validation error(s)');
  }
}

// --- safeParse wraps invalid JSON as ZemaFailure (code: invalid_json) ---

Future<void> _exampleInvalidJson(http.Client client) async {
  print('\n--- invalid JSON body ---');

  // Simulate a response with a non-JSON body (e.g. an HTML error page).
  final fakeResponse =
      http.Response('<html>503 Service Unavailable</html>', 503);
  final result = fakeResponse.safeParse(_userSchema);

  switch (result) {
    case ZemaSuccess():
      print('Unexpected success');
    case ZemaFailure(:final errors):
      final issue = errors.first;
      print('code: ${issue.code}'); // invalid_json
      print('received: ${issue.receivedValue}');
  }
}

// --- deliberate schema mismatch to show ZemaFailure ---

Future<void> _exampleSchemaFailure(http.Client client) async {
  print('\n--- schema mismatch ---');

  final strictSchema = z.object({
    'id': z.integer(),
    'name': z.string().min(1),
    'email': z.string().email(),
    'verified': z.boolean(), // field absent in the API response
  });

  final response = await client.get(Uri.parse('$_base/users/1'));
  final result = response.safeParse(strictSchema);

  switch (result) {
    case ZemaSuccess():
      print('Unexpected success');
    case ZemaFailure(:final errors):
      print('Validation errors (${errors.length}):');
      for (final issue in errors) {
        final path = issue.path.isEmpty ? 'root' : issue.path.join('.');
        print('  [$path] ${issue.code}: ${issue.message}');
      }
  }
}
