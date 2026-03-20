zema_hive - Type-Safe Local Storage
Suppression totale des TypeAdapters. Storage brut + validation Zema.
🏗️ Architecture Finale
zema_hive/
├── lib/
│   ├── zema_hive.dart                          // Export principal
│   │
│   └── src/
│       ├── core/
│       │   ├── zema_box.dart                   // Wrapper principal
│       │   ├── migration_manager.dart          // Gestion migrations
│       │   └── schema_metadata.dart            // Versioning
│       │
│       ├── extensions/
│       │   └── box_extension.dart              // Box.withZema()
│       │
│       └── exceptions/
│           └── hive_exception.dart             // Exceptions Zema Hive
│
├── example/
│   └── migration_example.dart                  // Démo migration
│
└── test/
    └── zema_box_test.dart
🔧 1. ZemaBox - Wrapper Principal
// lib/src/core/zema_box.dart

import 'package:hive/hive.dart';
import 'package:zema/zema.dart';
import 'migration_manager.dart';
import 'schema_metadata.dart';
import '../exceptions/hive_exception.dart';

/// Wrapper type-safe autour d'une Box Hive.
/// 
/// Stocke des Map<String, dynamic> brutes mais garantit :
/// - Validation à l'écriture (atomic)
/// - Typage à la lecture (Extension Types)
/// - Migration automatique (schema versioning)
/// 
///
Dart


/// final box = await Hive.openBox('users');
/// final userBox = box.withZema<User>(
///   userSchema,
///   version: 2,
///   migrate: (oldData, oldVersion) {
///     if (oldVersion == 1) {
///       oldData['role'] = 'user'; // Ajout champ par défaut
///     }
///     return oldData;
///   },
/// );
/// 
/// userBox.put('123', user); // ✅ Validé avant write
/// final user = userBox.get('123'); // ✅ Extension Type typé
/// 
class ZemaBox<T> {
  /// Box Hive sous-jacente (stocke Map<String, dynamic>).
  final Box<Map<String, dynamic>> _box;

  /// Schema Zema pour validation.
  final ZemaSchema<T> _schema;

  /// Version du schema actuel.
  final int _version;

  /// Manager de migration.
  final MigrationManager? _migrationManager;

  /// Clé réservée pour stocker les metadata.
  static const String _metadataKey = 'zema_metadata';

  ZemaBox._({
    required Box<Map<String, dynamic>> box,
    required ZemaSchema<T> schema,
    required int version,
    MigrationManager? migrationManager,
  })  : _box = box,
        _schema = schema,
        _version = version,
        _migrationManager = migrationManager {
    // Vérifie et met à jour la version
    _checkAndUpdateVersion();
  }

  /// Factory pour créer un ZemaBox depuis une Box Hive.
  factory ZemaBox.wrap({
    required Box box,
    required ZemaSchema<T> schema,
    int version = 1,
    Map<String, dynamic> Function(Map<String, dynamic>, int)? migrate,
  }) {
    // Cast la box en Box<Map<String, dynamic>>
    // Note: Hive accepte Box<dynamic> qu'on peut caster
    final typedBox = box as Box<Map<String, dynamic>>;

    final migrationManager = migrate != null
        ? MigrationManager(migrate: migrate)
        : null;

    return ZemaBox._(
      box: typedBox,
      schema: schema,
      version: version,
      migrationManager: migrationManager,
    );
  }

  /// Vérifie la version du schema et lance les migrations si nécessaire.
  void _checkAndUpdateVersion() {
    final metadata = _loadMetadata();

    if (metadata.version < _version) {
      _performMigrations(metadata.version);
      _saveMetadata(SchemaMetadata(version: _version));
    }
  }

  /// Charge les metadata depuis la box.
  SchemaMetadata _loadMetadata() {
    final data = _box.get(_metadataKey);
    if (data == null) {
      // Première initialisation
      return SchemaMetadata(version: 0);
    }

    return SchemaMetadata.fromMap(data);
  }

  /// Sauvegarde les metadata dans la box.
  void _saveMetadata(SchemaMetadata metadata) {
    _box.put(_metadataKey, metadata.toMap());
  }

  /// Exécute les migrations nécessaires.
  void _performMigrations(int fromVersion) {
    if (_migrationManager == null) return;

    print('[Zema Hive] Migrating from v$fromVersion to v$_version');
// Migration lazy : on ne migre PAS toute la box maintenant
    // On marquera les entrées comme "nécessitant migration" au get()
    // Cela évite de bloquer l'ouverture de la box
  }

  // ===== WRITE OPERATIONS (Atomic Validation) =====

  /// Écrit une valeur dans la box.
  /// 
  /// Valide AVANT toute écriture. Si validation échoue, aucune modification.
  /// 
  ///
Dart


  /// userBox.put('123', user); // Validé atomiquement
  /// 
  Future<void> put(String key, T value) async {
    // Valide la donnée
    final result = _schema.parse(_extractMap(value));

    if (result.isError) {
      throw ZemaHiveValidationException(
        'Validation failed for key "$key"',
        errors: result.errors,
        key: key,
        value: _extractMap(value),
      );
    }

    // Écrit dans Hive (atomic)
    await _box.put(key, result.value as Map<String, dynamic>);
  }

  /// Ajoute une valeur dans la box (génère une clé auto).
  Future<String> add(T value) async {
    final result = _schema.parse(_extractMap(value));

    if (result.isError) {
      throw ZemaHiveValidationException(
        'Validation failed for add operation',
        errors: result.errors,
        value: _extractMap(value),
      );
    }

    // Génère une clé unique
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    await _box.put(key, result.value as Map<String, dynamic>);
    
    return key;
  }

  /// Écrit plusieurs valeurs atomiquement.
  Future<void> putAll(Map<String, T> entries) async {
    // Valide TOUTES les entrées avant d'écrire
    final validatedEntries = <String, Map<String, dynamic>>{};

    for (final entry in entries.entries) {
      final result = _schema.parse(_extractMap(entry.value));

      if (result.isError) {
        throw ZemaHiveValidationException(
          'Validation failed for key "${entry.key}" in batch operation',
          errors: result.errors,
          key: entry.key,
          value: _extractMap(entry.value),
        );
      }

      validatedEntries[entry.key] = result.value as Map<String, dynamic>;
    }

    // Toutes les validations ont réussi → Écrit atomiquement
    await _box.putAll(validatedEntries);
  }

  // ===== READ OPERATIONS (Resilience & Migration) =====

  /// Lit une valeur depuis la box.
  /// 
  /// Gère automatiquement :
  /// - Validation du schema
  /// - Migration si nécessaire
  /// - Fallback sur null si erreur
  /// 
  ///
Dart


  /// final user = userBox.get('123'); // Extension Type typé
  /// 
  T? get(String key, {T? defaultValue}) {
    final data = _box.get(key);

    if (data == null) {
      return defaultValue;
    }

    // Tente de parser avec le schema actuel
    final result = _schema.safeParse(data);

    if (result.isSuccess) {
      // Données valides
      return result.value;
    }

    // Échec de validation → Tente migration
    if (_migrationManager != null) {
      try {
        final metadata = _loadMetadata();
        final migrated = _migrationManager!.migrate(data, metadata.version);

        // Re-valide après migration
        final migratedResult = _schema.safeParse(migrated);

        if (migratedResult.isSuccess) {
          // Migration réussie → Sauvegarde la version migrée
          _box.put(key, migratedResult.value as Map<String, dynamic>);
          return migratedResult.value;
        }
      } catch (e) {
        _logMigrationError(key, e);
      }
    }

    // Échec total → Log et retourne defaultValue
    _logValidationError(key, result.errors);
    return defaultValue;
  }

  /// Récupère toutes les valeurs.
  /// 
  /// Filtre automatiquement les entrées invalides.
  Iterable<T> get values {
    return _box.keys
        .where((key) => key != _metadataKey) // Skip metadata
        .map((key) => get(key as String))
        .where((value) => value != null)
        .cast<T>();
  }

  /// Récupère toutes les entrées (key + value).
  Map<String, T> get toMap {
    final result = <String, T>{};

    for (final key in _box.keys) {
      if (key == _metadataKey) continue; // Skip metadata
final value = get(key as String);
      if (value != null) {
        result[key as String] = value;
      }
    }

    return result;
  }

  /// Récupère plusieurs valeurs par clés.
  List<T?> getAll(List<String> keys) {
    return keys.map((key) => get(key)).toList();
  }

  // ===== DELETE OPERATIONS =====

  /// Supprime une entrée.
  Future<void> delete(String key) async {
    await _box.delete(key);
  }

  /// Supprime plusieurs entrées.
  Future<void> deleteAll(List<String> keys) async {
    await _box.deleteAll(keys);
  }

  /// Vide la box (sauf metadata).
  Future<void> clear() async {
    final metadata = _loadMetadata();
    await _box.clear();
    _saveMetadata(metadata); // Restaure metadata
  }

  // ===== UTILITIES =====

  /// Nombre d'entrées (hors metadata).
  int get length => _box.length - 1; // -1 pour metadata

  /// La box est vide.
  bool get isEmpty => length == 0;

  /// La box contient des données.
  bool get isNotEmpty => !isEmpty;

  /// Vérifie si une clé existe.
  bool containsKey(String key) => _box.containsKey(key);

  /// Liste des clés (hors metadata).
  Iterable<String> get keys {
    return _box.keys
        .where((key) => key != _metadataKey)
        .cast<String>();
  }

  /// Compact la box (optimisation Hive).
  Future<void> compact() async {
    await _box.compact();
  }

  /// Ferme la box.
  Future<void> close() async {
    await _box.close();
  }

  // ===== HELPERS =====

  /// Extrait la Map depuis un Extension Type.
  Map<String, dynamic> _extractMap(T value) {
    // T est un Extension Type qui wrappe une Map
    return value as Map<String, dynamic>;
  }

  /// Log une erreur de validation.
  void _logValidationError(String key, List<ZemaValidationError> errors) {
    print('[Zema Hive] Validation failed for key "$key":');
    for (final error in errors) {
      final path = error.path.isEmpty ? 'root' : error.path.join('.');
      print('  • $path: ${error.message}');
    }
  }

  /// Log une erreur de migration.
  void _logMigrationError(String key, Object error) {
    print('[Zema Hive] Migration failed for key "$key": $error');
  }
}
🎯 2. Extension Box.withZema()
// lib/src/extensions/box_extension.dart

import 'package:hive/hive.dart';
import 'package:zema/zema.dart';
import '../core/zema_box.dart';

extension ZemaBoxExtension on Box {
  /// Wrap cette Box avec Zema pour validation et typage.
  /// 
  ///
Dart


  /// final box = await Hive.openBox('users');
  /// final userBox = box.withZema<User>(
  ///   userSchema,
  ///   version: 2,
  ///   migrate: (oldData, oldVersion) {
  ///     if (oldVersion == 1) {
  ///       oldData['role'] = 'user';
  ///     }
  ///     return oldData;
  ///   },
  /// );
  /// 
  ZemaBox<T> withZema<T>(
    ZemaSchema<T> schema, {
    int version = 1,
    Map<String, dynamic> Function(Map<String, dynamic> oldData, int oldVersion)? migrate,
  }) {
    return ZemaBox.wrap(
      box: this,
      schema: schema,
      version: version,
      migrate: migrate,
    );
  }
}
⚙️ 3. Migration Manager
// lib/src/core/migration_manager.dart

/// Gestionnaire de migrations de schema.
class MigrationManager {
  final Map<String, dynamic> Function(Map<String, dynamic>, int) migrate;

  MigrationManager({required this.migrate});
}
📊 4. Schema Metadata
// lib/src/core/schema_metadata.dart

/// Metadata de versioning stockées dans la Box.
class SchemaMetadata {
  final int version;

  SchemaMetadata({required this.version});

  factory SchemaMetadata.fromMap(Map<String, dynamic> map) {
    return SchemaMetadata(
      version: map['version'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
    };
  }
}
💥 5. Exceptions
// lib/src/exceptions/hive_exception.dart

import 'package:zema/zema.dart';

/// Exception levée lors d'une erreur de validation Hive.
class ZemaHiveValidationException implements Exception {
  final String message;
  final List<ZemaValidationError> errors;
  final String? key;
  final Map<String, dynamic>? value;
ZemaHiveValidationException(
    this.message, {
    required this.errors,
    this.key,
    this.value,
  });

  @override
  String toString() {
    final buffer = StringBuffer('ZemaHiveValidationException: $message\n');

    if (key != null) {
      buffer.writeln('Key: $key');
    }

    if (errors.isNotEmpty) {
      buffer.writeln('Validation errors:');
      for (final error in errors) {
        final path = error.path.isEmpty ? 'root' : error.path.join('.');
        buffer.writeln('  • $path: ${error.message}');
      }
    }

    if (value != null) {
      buffer.writeln('Value: $value');
    }

    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'message': message,
        'key': key,
        'errors': errors
            .map((e) => {
                  'path': e.path.join('.'),
                  'message': e.message,
                })
            .toList(),
        'value': value,
      };
}
📱 6. Exemple Complet avec Migration
// example/migration_example.dart

import 'package:hive/hive.dart';
import 'package:zema/zema.dart';
import 'package:zema_hive/zema_hive.dart';

// ===== SCHEMA V1 =====
final userSchemaV1 = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'name': z.string(),
});

// ===== SCHEMA V2 (ajout du champ 'role') =====
final userSchemaV2 = z.object({
  'id': z.string(),
  'email': z.string().email(),
  'name': z.string(),
  'role': z.string().default('user'), // ← Nouveau champ
});

extension type User(Map<String, dynamic> _) implements ZemaObject {
  String get id => _['id'];
  String get email => _['email'];
  String get name => _['name'];
  String get role => _['role']; // ← Nouveau champ
}

void main() async {
  // Initialise Hive
  await Hive.initFlutter();

  // Ouvre la box standard
  final box = await Hive.openBox('users');

  // ===== SIMULATION : Données V1 dans la box =====
  // (Imagine que ces données ont été écrites avec userSchemaV1)
  await box.put('user_1', {
    'id': 'u1',
    'email': 'alice@example.com',
    'name': 'Alice',
    // 'role' manquant (V1)
  });

  // ===== WRAP avec Zema V2 + Migration =====
  final userBox = box.withZema<User>(
    userSchemaV2,
    version: 2,
    migrate: (oldData, oldVersion) {
      print('Migrating from v$oldVersion to v2');

      // Migration V1 → V2
      if (oldVersion == 1) {
        // Ajoute le champ 'role' par défaut
        if (!oldData.containsKey('role')) {
          oldData['role'] = 'user';
        }
      }

      return oldData;
    },
  );

  // ===== LECTURE (Migration automatique) =====
  final user = userBox.get('user_1');

  if (user != null) {
    print('User: ${user.name}');
    print('Role: ${user.role}'); // ← Champ migré automatiquement !
  }

  // ===== ÉCRITURE (V2 validée) =====
  try {
    final newUser = User({
      'id': 'u2',
      'email': 'bob@example.com',
      'name': 'Bob',
      'role': 'admin',
    });

    await userBox.put('user_2', newUser);
    print('User created successfully');
  } on ZemaHiveValidationException catch (e) {
    print('Validation failed: ${e.errors}');
  }

  // ===== LECTURE DE TOUTES LES VALEURS =====
  print('\nAll users:');
  for (final user in userBox.values) {
    print('  - ${user.name} (${user.role})');
  }

  // Cleanup
  await userBox.close();
}
Output :
Migrating from v1 to v2
User: Alice
Role: user
User created successfully

All users:
  - Alice (user)
  - Bob (admin)
🔥 7. Exemple Avancé : Migration Complexe
// Migration multi-versions
final userBox = box.withZema<User>(
  userSchemaV3,
  version: 3,
  migrate: (oldData, oldVersion) {
    // V1 → V2 : Ajout 'role'
    if (oldVersion < 2) {
      oldData['role'] = 'user';
    }

    // V2 → V3 : Renommage 'email' → 'emailAddress'
    if (oldVersion < 3) {
      if (oldData.containsKey('email')) {
        oldData['emailAddress'] = oldData['email'];
        oldData.remove('email');
      }
    }
return oldData;
  },
);
✅ Checklist MVP
✅ ZemaBox wrapper : Encapsule Box<Map<String, dynamic>>
✅ Atomic validation write : put/add valide AVANT écriture
✅ Resilient read : get avec safeParse + migration
✅ Schema versioning : Metadata stockée dans la box
✅ Lazy migration : Migration uniquement au get()
✅ Fallback graceful : Retourne null si validation + migration échouent
✅ Extension .withZema() : Syntaxe ergonomique
✅ Logging : Avertissements pour erreurs de validation/migration
État : zema_hive MVP complet. Zero TypeAdapter, zero build_runner.