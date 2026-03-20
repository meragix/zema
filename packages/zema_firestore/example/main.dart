import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:zema/zema.dart';
import 'package:zema_firestore/zema_firestore.dart';

// ---------------------------------------------------------------------------
// Schemas — defined once at module scope.
// ---------------------------------------------------------------------------

final userSchema = z.object({
  'id': z.string(),
  'name': z.string().min(1),
  'email': z.string().email(),
  'createdAt': zTimestamp(),
});

final postSchema = z.object({
  'id': z.string(),
  'title': z.string().min(1),
  'body': z.string(),
  'authorId': z.string(),
  'publishedAt': zTimestamp(),
  'location': zGeoPoint().nullable(),
});

// ---------------------------------------------------------------------------
// Typed references — one definition, used everywhere.
// ---------------------------------------------------------------------------

CollectionReference<Map<String, dynamic>> usersRef(FirebaseFirestore db) =>
    db.collection('users').withZema(userSchema);

CollectionReference<Map<String, dynamic>> postsRef(FirebaseFirestore db) =>
    db.collection('posts').withZema(postSchema);

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase before using Firestore (requires firebase_core and a
  // generated firebase_options.dart from FlutterFire CLI):
  //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final db = FirebaseFirestore.instance;

  await _writeExample(db);
  await _readExample(db);
  await _queryExample(db);
  await _streamExample(db);
  await _errorHandlingExample(db);
  await _timestampExample(db);
}

// --- Write a document (DateTime auto-converted to Timestamp) ---

Future<void> _writeExample(FirebaseFirestore db) async {
  print('\n--- write ---');

  await usersRef(db).doc('alice').set({
    'name': 'Alice',
    'email': 'alice@example.com',
    'createdAt': DateTime.now(), // stored as Timestamp in Firestore
  });

  print('Written: alice');
}

// --- Read and validate a single document ---

Future<void> _readExample(FirebaseFirestore db) async {
  print('\n--- read ---');

  final snapshot = await usersRef(db).doc('alice').get();
  final user = snapshot.data();

  if (user != null) {
    print('name: ${user['name']}');
    print('email: ${user['email']}');
    print('createdAt: ${user['createdAt'].runtimeType}'); // DateTime
  }
}

// --- Query with validation ---

Future<void> _queryExample(FirebaseFirestore db) async {
  print('\n--- query ---');

  final snap =
      await usersRef(db).orderBy('createdAt', descending: true).limit(10).get();

  for (final doc in snap.docs) {
    final user = doc.data();
    print('  ${user['id']}: ${user['name']}');
  }
}

// --- Stream — each document validated as it arrives ---

Future<void> _streamExample(FirebaseFirestore db) async {
  print('\n--- stream (first batch) ---');

  final sub = usersRef(db).snapshots().listen((snap) {
    for (final doc in snap.docs) {
      print('  live: ${doc.data()['name']}');
    }
  });

  await Future<void>.delayed(const Duration(seconds: 1));
  await sub.cancel();
}

// --- Error handling with onParseError fallback ---

Future<void> _errorHandlingExample(FirebaseFirestore db) async {
  print('\n--- error handling ---');

  final safeRef = db.collection('users').withZema(
    userSchema,
    onParseError: (snapshot, error, stackTrace) {
      // In production: Sentry.captureException(error, stackTrace: stackTrace);
      print('  parse error on ${snapshot.id}: ${error.runtimeType}');
      // Return a placeholder to avoid crashing the stream
      return {
        'id': snapshot.id,
        'name': 'Unknown',
        'email': 'unknown@example.com',
        'createdAt': DateTime(2000),
      };
    },
  );

  // Write a document that intentionally fails validation
  await db.collection('users').doc('corrupt').set({
    'name': '', // too short
    'email': 'not-an-email',
  });

  final snap = await safeRef.doc('corrupt').get();
  print('  fallback name: ${snap.data()?['name']}'); // Unknown
}

// --- Timestamp round-trip ---

Future<void> _timestampExample(FirebaseFirestore db) async {
  print('\n--- timestamp round-trip ---');

  final event = {
    'title': 'Product launch',
    'body': 'We are live.',
    'authorId': 'alice',
    'publishedAt': DateTime(2024, 6, 15, 9, 0), // DateTime written as Timestamp
    'location': null,
  };

  await postsRef(db).doc('launch').set(event);

  final snap = await postsRef(db).doc('launch').get();
  final data = snap.data()!;

  // publishedAt is read back as DateTime (zTimestamp() converts it)
  final ts = data['publishedAt'] as DateTime;
  print('  publishedAt type: ${ts.runtimeType}'); // DateTime
  print('  publishedAt: $ts');
}
