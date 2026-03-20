import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/zema.dart';
import 'package:zema_firestore/zema_firestore.dart';

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
  'occurredAt': zTimestamp(),
});

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('zTimestamp()', () {
    test('accepts a Timestamp and converts to DateTime', () {
      final now = DateTime(2024, 6, 1);
      final ts = Timestamp.fromDate(now);
      final schema = zTimestamp();

      final result = schema.safeParse(ts);

      expect(result, isA<ZemaSuccess<DateTime>>());
      expect((result as ZemaSuccess).value, equals(now));
    });

    test('accepts a DateTime and passes it through', () {
      final now = DateTime(2024, 6, 1);
      final result = zTimestamp().safeParse(now);

      expect(result, isA<ZemaSuccess<DateTime>>());
      expect((result as ZemaSuccess).value, equals(now));
    });

    test('rejects an invalid type', () {
      final result = zTimestamp().safeParse('not-a-date');

      expect(result, isA<ZemaFailure>());
      expect(result.errors.first.message,
          contains('Expected Timestamp or DateTime'));
    });
  });

  group('zGeoPoint()', () {
    test('accepts a GeoPoint', () {
      final point = GeoPoint(48.8566, 2.3522);
      final result = zGeoPoint().safeParse(point);

      expect(result, isA<ZemaSuccess<GeoPoint>>());
    });

    test('rejects a non-GeoPoint', () {
      final result = zGeoPoint().safeParse({'lat': 48.8, 'lng': 2.3});

      expect(result, isA<ZemaFailure>());
      expect(result.errors.first.message, contains('Expected GeoPoint'));
    });
  });

  group('zBlob()', () {
    test('accepts a Blob', () {
      final blob = Blob(Uint8List.fromList([1, 2, 3]));
      final result = zBlob().safeParse(blob);

      expect(result, isA<ZemaSuccess<Blob>>());
    });

    test('rejects a non-Blob', () {
      final result = zBlob().safeParse('not-a-blob');

      expect(result, isA<ZemaFailure>());
    });
  });

  group('ZemaFirestoreException', () {
    test('toString includes message', () {
      const ex = ZemaFirestoreException('Schema validation failed');
      expect(ex.toString(), contains('Schema validation failed'));
    });

    test('toString includes path and id when provided', () {
      const ex = ZemaFirestoreException(
        'Schema validation failed',
        path: 'users/abc',
        documentId: 'abc',
      );
      final str = ex.toString();
      expect(str, contains('users/abc'));
      expect(str, contains('abc'));
    });

    test('toString lists issues', () {
      const ex = ZemaFirestoreException(
        'Schema validation failed',
        issues: [
          ZemaIssue(code: 'invalid_type', message: 'Expected string'),
        ],
      );
      expect(ex.toString(), contains('invalid_type'));
      expect(ex.toString(), contains('Expected string'));
    });
  });

  group('ZemaFirestoreConverter — date conversion', () {
    test('toFirestore converts DateTime to Timestamp', () {
      final converter = ZemaFirestoreConverter(schema: _userSchema);
      final now = DateTime(2024, 1, 15);
      final input = {
        'id': '1',
        'name': 'Alice',
        'email': 'alice@example.com',
        'ts': now
      };

      final result = converter.toFirestore(input, null);

      expect(result['ts'], isA<Timestamp>());
      expect((result['ts'] as Timestamp).toDate(), equals(now));
    });

    test('toFirestore removes documentIdField', () {
      final converter = ZemaFirestoreConverter(schema: _userSchema);
      final input = {
        'id': 'abc',
        'name': 'Alice',
        'email': 'alice@example.com'
      };

      final result = converter.toFirestore(input, null);

      expect(result.containsKey('id'), isFalse);
    });

    test('toFirestore keeps documentIdField when injectDocumentId is false',
        () {
      final converter = ZemaFirestoreConverter(
        schema: _userSchema,
        injectDocumentId: false,
      );
      final input = {
        'id': 'abc',
        'name': 'Alice',
        'email': 'alice@example.com'
      };

      final result = converter.toFirestore(input, null);

      expect(result.containsKey('id'), isTrue);
    });

    test('toFirestore recursively converts nested DateTime', () {
      final schema = z.object({
        'meta': z.object({'createdAt': z.string()})
      });
      final converter = ZemaFirestoreConverter(schema: schema);
      final now = DateTime(2024, 3, 10);
      final input = {
        'meta': <String, dynamic>{'createdAt': now}
      };

      final result = converter.toFirestore(input, null);
      final meta = result['meta'] as Map<String, dynamic>;

      expect(meta['createdAt'], isA<Timestamp>());
    });
  });

  group('withZema — CollectionReference integration', () {
    late FakeFirebaseFirestore fakeFirestore;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
    });

    test('reads and validates a valid document', () async {
      await fakeFirestore.collection('users').doc('1').set({
        'name': 'Alice',
        'email': 'alice@example.com',
      });

      final usersRef = fakeFirestore.collection('users').withZema(_userSchema);
      final snapshot = await usersRef.doc('1').get();
      final data = snapshot.data();

      expect(data, isNotNull);
      expect(data!['name'], equals('Alice'));
      expect(data['id'], equals('1')); // injected
    });

    test('injects document ID under custom field', () async {
      await fakeFirestore.collection('users').doc('42').set({
        'name': 'Bob',
        'email': 'bob@example.com',
      });

      final schema = z.object({
        'uid': z.string(),
        'name': z.string(),
        'email': z.string().email(),
      });
      final usersRef = fakeFirestore.collection('users').withZema(
            schema,
            documentIdField: 'uid',
          );
      final snapshot = await usersRef.doc('42').get();
      final data = snapshot.data();

      expect(data!['uid'], equals('42'));
    });

    test('throws ZemaFirestoreException on schema mismatch', () async {
      await fakeFirestore.collection('users').doc('bad').set({
        'name': '', // too short — min(1)
        'email': 'not-valid',
      });

      final usersRef = fakeFirestore.collection('users').withZema(_userSchema);

      expect(
        () async => (await usersRef.doc('bad').get()).data(),
        throwsA(isA<ZemaFirestoreException>()),
      );
    });

    test('calls onParseError and uses fallback on failure', () async {
      await fakeFirestore.collection('users').doc('broken').set({
        'name': '',
        'email': 'bad',
      });

      final fallback = {
        'id': 'broken',
        'name': 'Unknown',
        'email': 'unknown@example.com'
      };
      var errorCallbackInvoked = false;

      final usersRef = fakeFirestore.collection('users').withZema(
        _userSchema,
        onParseError: (_, __, ___) {
          errorCallbackInvoked = true;
          return fallback;
        },
      );

      final data = (await usersRef.doc('broken').get()).data();

      expect(errorCallbackInvoked, isTrue);
      expect(data!['name'], equals('Unknown'));
    });

    test('reads timestamp fields as DateTime via zTimestamp()', () async {
      final now = DateTime(2024, 6, 15, 10);
      await fakeFirestore.collection('events').doc('e1').set({
        'title': 'Launch',
        'occurredAt': Timestamp.fromDate(now),
      });

      final eventsRef =
          fakeFirestore.collection('events').withZema(_eventSchema);
      final data = (await eventsRef.doc('e1').get()).data();

      expect(data!['occurredAt'], isA<DateTime>());
      expect(data['occurredAt'], equals(now));
    });

    test('withZema on Query returns typed results', () async {
      await fakeFirestore.collection('users').doc('u1').set({
        'name': 'Alice',
        'email': 'alice@example.com',
        'active': true,
      });
      await fakeFirestore.collection('users').doc('u2').set({
        'name': 'Bob',
        'email': 'bob@example.com',
        'active': false,
      });

      final query = fakeFirestore
          .collection('users')
          .where('active', isEqualTo: true)
          .withZema(_userSchema);

      final snapshot = await query.get();
      expect(snapshot.docs.length, equals(1));
      expect(snapshot.docs.first.data()['name'], equals('Alice'));
    });
  });
}
