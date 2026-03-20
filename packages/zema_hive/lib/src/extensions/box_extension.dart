import 'package:hive_ce/hive_ce.dart';
import 'package:zema/zema.dart';

import '../core/zema_box.dart';

/// Adds [withZema] to Hive's [Box].
extension ZemaBoxExtension on Box {
  /// Wraps this [Box] with Zema for schema validation on every read and write.
  ///
  /// ```dart
  /// final box = await Hive.openBox('users');
  /// final userBox = box.withZema(userSchema);
  ///
  /// await userBox.put('alice', {'name': 'Alice', 'email': 'alice@example.com'});
  /// final user = userBox.get('alice'); // validated Map<String, dynamic>
  /// ```
  ///
  /// Pass [migrate] to automatically transform stored documents that fail the
  /// current schema, useful when your schema evolves over time.
  ///
  /// ```dart
  /// final userBox = box.withZema(
  ///   userSchemaV2,
  ///   migrate: (rawData) {
  ///     if (!rawData.containsKey('role')) rawData['role'] = 'user';
  ///     return rawData;
  ///   },
  /// );
  /// ```
  ZemaBox<T> withZema<T extends Object>(
    ZemaSchema<dynamic, T> schema, {
    ZemaHiveMigration? migrate,
    OnHiveParseError<T>? onParseError,
  }) {
    return ZemaBox<T>(
      box: this,
      schema: schema,
      migrate: migrate,
      onParseError: onParseError,
    );
  }
}
