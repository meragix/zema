import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:zema/zema.dart';
import 'package:zema_hive/zema_hive.dart';

// ---------------------------------------------------------------------------
// Schemas
// ---------------------------------------------------------------------------

final userSchemaV1 = z.object({
  'id': z.string(),
  'name': z.string().min(1),
  'email': z.string().email(),
});

final userSchemaV2 = z.object({
  'id': z.string(),
  'name': z.string().min(1),
  'email': z.string().email(),
  'role': z.string().withDefault('user'),
});

// ---------------------------------------------------------------------------
// Extension type — same runtime representation as Map<String, dynamic>
// ---------------------------------------------------------------------------

extension type User(Map<String, dynamic> _) {
  String get id => _['id'] as String;
  String get name => _['name'] as String;
  String get email => _['email'] as String;
  String get role => _['role'] as String;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  final dir = await Directory.systemTemp.createTemp('zema_hive_example_');
  Hive.init(dir.path);

  await _basicExample();
  await _extensionTypeExample();
  await _migrationExample();
  await _errorHandlingExample();

  await Hive.close();
  await dir.delete(recursive: true);
}

// --- Basic read / write ---

Future<void> _basicExample() async {
  print('\n--- basic ---');

  final box = await Hive.openBox('basic');
  final userBox = box.withZema(userSchemaV1);

  await userBox.put('alice', {
    'id': 'alice',
    'name': 'Alice',
    'email': 'alice@example.com',
  });

  final user = userBox.get('alice');
  print('name: ${user?['name']}');   // Alice
  print('email: ${user?['email']}'); // alice@example.com

  // Missing key returns null
  final missing = userBox.get('nobody');
  print('missing: $missing'); // null

  await box.close();
}

// --- Extension type ---

Future<void> _extensionTypeExample() async {
  print('\n--- extension type ---');

  // The schema produces Map<String, dynamic>. Wrap in the extension type
  // afterwards to get named field access without any runtime overhead.
  final box = await Hive.openBox('ext');
  final userBox = box.withZema(userSchemaV2);

  await userBox.put('bob', {
    'id': 'bob',
    'name': 'Bob',
    'email': 'bob@example.com',
    'role': 'admin',
  });

  final raw = userBox.get('bob');
  if (raw != null) {
    final user = User(raw);
    print('name: ${user.name}');   // Bob
    print('role: ${user.role}');   // admin
  }

  // Wrap all values on the way out
  for (final u in userBox.values.map(User.new)) {
    print('  user: ${u.name}');
  }

  await box.close();
}

// --- Schema migration ---

Future<void> _migrationExample() async {
  print('\n--- migration ---');

  final box = await Hive.openBox('migration');

  // Simulate data written with V1 schema (no 'role' field)
  await box.put('alice', {
    'id': 'alice',
    'name': 'Alice',
    'email': 'alice@example.com',
  });

  // Wrap with V2 schema + migration callback
  final userBox = box.withZema(
    userSchemaV2,
    migrate: (rawData) {
      // V1 -> V2: back-fill the 'role' field
      if (!rawData.containsKey('role')) {
        rawData['role'] = 'user';
      }
      return rawData;
    },
  );

  // get() detects validation failure, applies migration, writes back
  final user = userBox.get('alice');
  print('name: ${user?['name']}'); // Alice
  print('role: ${user?['role']}'); // user  ← migrated

  await box.close();
}

// --- Error handling with onParseError ---

Future<void> _errorHandlingExample() async {
  print('\n--- error handling ---');

  final box = await Hive.openBox('errors');

  // Write a document that intentionally fails validation
  await box.put('corrupt', {
    'id': 'corrupt',
    'name': '', // too short
    'email': 'not-an-email',
  });

  final userBox = box.withZema(
    userSchemaV1,
    onParseError: (key, rawData, issues) {
      // In production: Sentry.captureException(issues)
      print('  parse error on "$key": ${issues.map((i) => i.message).join(', ')}');
      return {
        'id': key,
        'name': 'Unknown',
        'email': 'unknown@example.com',
      };
    },
  );

  final user = userBox.get('corrupt');
  print('fallback name: ${user?['name']}'); // Unknown

  // Attempting to write invalid data throws ZemaHiveException
  try {
    await userBox.put('bad', {
      'id': 'bad',
      'name': '',
      'email': 'not-valid',
    });
  } on ZemaHiveException catch (e) {
    print('write rejected: ${e.issues?.first.message}');
  }

  await box.close();
}
