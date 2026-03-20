import 'dart:io';

import 'package:hive_ce/hive_ce.dart';
import 'package:test/test.dart';
import 'package:zema/zema.dart';
import 'package:zema_hive/zema_hive.dart';

// ---------------------------------------------------------------------------
// Shared schemas
// ---------------------------------------------------------------------------

final _userSchema = z.object({
  'id': z.string(),
  'name': z.string().min(1),
  'email': z.string().email(),
});

final _eventSchema = z.object({
  'id': z.string(),
  'title': z.string().min(1),
  'tags': z.array(z.string()),
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late Box box;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zema_hive_test_');
    Hive.init(tempDir.path);
    box = await Hive.openBox<Map>('test');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // ZemaHiveException
  // -------------------------------------------------------------------------

  group('ZemaHiveException', () {
    test('toString includes message', () {
      const ex = ZemaHiveException('Validation failed');
      expect(ex.toString(), contains('Validation failed'));
    });

    test('toString includes key when provided', () {
      const ex = ZemaHiveException('Validation failed', key: 'abc');
      expect(ex.toString(), contains('abc'));
    });

    test('toString lists issues', () {
      const ex = ZemaHiveException(
        'Validation failed',
        issues: [
          ZemaIssue(code: 'too_short', message: 'Name too short'),
        ],
      );
      expect(ex.toString(), contains('too_short'));
      expect(ex.toString(), contains('Name too short'));
    });
  });

  // -------------------------------------------------------------------------
  // ZemaBox — writes
  // -------------------------------------------------------------------------

  group('ZemaBox.put()', () {
    test('writes a valid document', () async {
      final userBox = box.withZema(_userSchema);

      await userBox.put('u1', {
        'id': 'u1',
        'name': 'Alice',
        'email': 'alice@example.com',
      });

      expect(userBox.containsKey('u1'), isTrue);
    });

    test('throws ZemaHiveException on invalid document', () async {
      final userBox = box.withZema(_userSchema);

      expect(
        () => userBox.put('bad', {'id': 'bad', 'name': '', 'email': 'not-valid'}),
        throwsA(isA<ZemaHiveException>()),
      );
    });

    test('nothing is written when validation fails', () async {
      final userBox = box.withZema(_userSchema);

      try {
        await userBox.put('bad', {'id': 'bad', 'name': '', 'email': 'x'});
      } catch (_) {}

      expect(userBox.containsKey('bad'), isFalse);
    });
  });

  group('ZemaBox.putAll()', () {
    test('writes all entries when all are valid', () async {
      final userBox = box.withZema(_userSchema);

      await userBox.putAll({
        'u1': {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'},
        'u2': {'id': 'u2', 'name': 'Bob', 'email': 'bob@example.com'},
      });

      expect(userBox.length, equals(2));
    });

    test('throws on first invalid entry and writes nothing', () async {
      final userBox = box.withZema(_userSchema);

      expect(
        () => userBox.putAll({
          'u1': {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'},
          'u2': {'id': 'u2', 'name': '', 'email': 'bad'}, // invalid
        }),
        throwsA(isA<ZemaHiveException>()),
      );

      expect(userBox.containsKey('u1'), isFalse);
      expect(userBox.containsKey('u2'), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ZemaBox — reads
  // -------------------------------------------------------------------------

  group('ZemaBox.get()', () {
    test('returns null for a missing key', () {
      final userBox = box.withZema(_userSchema);
      expect(userBox.get('missing'), isNull);
    });

    test('returns defaultValue for a missing key', () {
      final userBox = box.withZema(_userSchema);
      final fallback = {'id': 'x', 'name': 'Anon', 'email': 'x@x.com'};
      expect(
        userBox.get('missing', defaultValue: fallback),
        equals(fallback),
      );
    });

    test('reads back a valid document', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      final userBox = box.withZema(_userSchema);

      final user = userBox.get('u1');

      expect(user, isNotNull);
      expect(user!['name'], equals('Alice'));
      expect(user['email'], equals('alice@example.com'));
    });

    test('returns null for an invalid document when no migrate or onParseError', () async {
      await box.put('bad', {'id': 'bad', 'name': '', 'email': 'not-valid'});
      final userBox = box.withZema(_userSchema);

      expect(userBox.get('bad'), isNull);
    });

    test('calls onParseError on validation failure', () async {
      await box.put('bad', {'id': 'bad', 'name': '', 'email': 'x'});

      var callbackInvoked = false;

      final userBox = box.withZema(
        _userSchema,
        onParseError: (key, rawData, issues) {
          callbackInvoked = true;
          expect(key, equals('bad'));
          expect(issues, isNotEmpty);
          return {'id': key, 'name': 'Unknown', 'email': 'unknown@example.com'};
        },
      );

      final result = userBox.get('bad');

      expect(callbackInvoked, isTrue);
      expect(result!['name'], equals('Unknown'));
    });
  });

  // -------------------------------------------------------------------------
  // Migration
  // -------------------------------------------------------------------------

  group('ZemaBox — migration', () {
    test('applies migration callback on validation failure', () async {
      // Store a V1 document (missing 'email' field)
      await box.put('u1', {'id': 'u1', 'name': 'Alice'});

      final userBox = box.withZema(
        _userSchema,
        migrate: (rawData) {
          if (!rawData.containsKey('email')) {
            rawData['email'] = 'migrated@example.com';
          }
          return rawData;
        },
      );

      final user = userBox.get('u1');

      expect(user, isNotNull);
      expect(user!['email'], equals('migrated@example.com'));
    });

    test('writes migrated document back to Hive', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice'});

      final userBox = box.withZema(
        _userSchema,
        migrate: (rawData) {
          rawData['email'] = 'migrated@example.com';
          return rawData;
        },
      );

      // First get triggers migration and writes back.
      userBox.get('u1');
      await Future<void>.delayed(Duration.zero); // let async write complete

      // Read raw box — should now have the migrated data.
      final raw = Map<String, dynamic>.from(box.get('u1') as Map);
      expect(raw['email'], equals('migrated@example.com'));
    });

    test('calls onParseError when migration still fails validation', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice'});

      var onParseErrorCalled = false;

      final userBox = box.withZema(
        _userSchema,
        migrate: (rawData) => rawData, // no-op — still invalid after migration
        onParseError: (key, rawData, issues) {
          onParseErrorCalled = true;
          return {'id': key, 'name': 'Fallback', 'email': 'fallback@example.com'};
        },
      );

      final result = userBox.get('u1');

      expect(onParseErrorCalled, isTrue);
      expect(result!['name'], equals('Fallback'));
    });

    test('migration is idempotent across multiple gets', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice'});

      var migrationCount = 0;

      final userBox = box.withZema(
        _userSchema,
        migrate: (rawData) {
          migrationCount++;
          rawData['email'] = 'migrated@example.com';
          return rawData;
        },
      );

      userBox.get('u1');
      await Future<void>.delayed(Duration.zero);
      userBox.get('u1'); // second get should NOT trigger migration again

      expect(migrationCount, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Collection helpers
  // -------------------------------------------------------------------------

  group('ZemaBox utilities', () {
    test('values returns all valid documents', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      await box.put('u2', {'id': 'u2', 'name': 'Bob', 'email': 'bob@example.com'});
      await box.put('bad', {'id': 'bad', 'name': '', 'email': 'x'});

      final userBox = box.withZema(_userSchema);
      final values = userBox.values.toList();

      expect(values.length, equals(2));
      expect(values.map((u) => u['name']), containsAll(['Alice', 'Bob']));
    });

    test('keys returns all stored keys', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      await box.put('u2', {'id': 'u2', 'name': 'Bob', 'email': 'bob@example.com'});

      final userBox = box.withZema(_userSchema);

      expect(userBox.keys.toList(), containsAll(['u1', 'u2']));
    });

    test('length reflects number of stored entries', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      await box.put('u2', {'id': 'u2', 'name': 'Bob', 'email': 'bob@example.com'});

      final userBox = box.withZema(_userSchema);

      expect(userBox.length, equals(2));
    });

    test('isEmpty and isNotEmpty', () {
      final userBox = box.withZema(_userSchema);
      expect(userBox.isEmpty, isTrue);
      expect(userBox.isNotEmpty, isFalse);
    });

    test('containsKey', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      final userBox = box.withZema(_userSchema);

      expect(userBox.containsKey('u1'), isTrue);
      expect(userBox.containsKey('missing'), isFalse);
    });

    test('delete removes a key', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      final userBox = box.withZema(_userSchema);

      await userBox.delete('u1');

      expect(userBox.containsKey('u1'), isFalse);
    });

    test('clear removes all entries', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      await box.put('u2', {'id': 'u2', 'name': 'Bob', 'email': 'bob@example.com'});
      final userBox = box.withZema(_userSchema);

      await userBox.clear();

      expect(userBox.isEmpty, isTrue);
    });

    test('toMap returns all valid entries as a map', () async {
      await box.put('u1', {'id': 'u1', 'name': 'Alice', 'email': 'alice@example.com'});
      await box.put('u2', {'id': 'u2', 'name': 'Bob', 'email': 'bob@example.com'});
      final userBox = box.withZema(_userSchema);

      final map = userBox.toMap();

      expect(map.keys, containsAll(['u1', 'u2']));
      expect(map['u1']!['name'], equals('Alice'));
    });
  });

  // -------------------------------------------------------------------------
  // withZema extension
  // -------------------------------------------------------------------------

  group('withZema extension', () {
    test('returns a ZemaBox', () {
      final userBox = box.withZema(_userSchema);
      expect(userBox, isA<ZemaBox>());
    });

    test('works with array schema', () async {
      await box.put('evt1', {
        'id': 'evt1',
        'title': 'Launch',
        'tags': ['dart', 'flutter'],
      });

      final eventBox = box.withZema(_eventSchema);
      final event = eventBox.get('evt1');

      expect(event, isNotNull);
      expect(event!['tags'], equals(['dart', 'flutter']));
    });
  });
}
