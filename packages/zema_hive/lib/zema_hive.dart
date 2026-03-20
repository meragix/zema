/// Zema schema validation integration for Hive.
///
/// Wraps a Hive [Box] so every document read is validated against a Zema
/// schema and every write is rejected if it fails validation. No [TypeAdapter],
/// no code generation: just raw [Map<String, dynamic>] storage with
/// type-safe access.
///
/// ## Setup
///
/// ```dart
/// import 'package:hive_ce/hive_ce.dart';
/// import 'package:zema/zema.dart';
/// import 'package:zema_hive/zema_hive.dart';
///
/// final userSchema = z.object({
///   'id': z.string(),
///   'name': z.string().min(1),
///   'email': z.string().email(),
/// });
///
/// final box = await Hive.openBox('users');
/// final userBox = box.withZema(userSchema);
///
/// // Write — validated before storage
/// await userBox.put('alice', {'id': 'alice', 'name': 'Alice', 'email': 'alice@example.com'});
///
/// // Read — validated on retrieval
/// final user = userBox.get('alice'); // Map<String, dynamic>?
/// ```
library;

export 'src/core/zema_box.dart'
    show ZemaBox, ZemaHiveMigration, OnHiveParseError;
export 'src/exceptions/hive_exception.dart';
export 'src/extensions/box_extension.dart';
