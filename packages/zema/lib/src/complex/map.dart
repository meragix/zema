import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that validates `Map` values with a **dynamic** set of entries,
/// producing a typed `Map<K, V>`.
///
/// Construct via `z.map(keySchema, valueSchema)` — do not instantiate directly.
///
/// ## ZemaMap vs ZemaObject
///
/// | | [ZemaMap] | [ZemaObject] |
/// |---|---|---|
/// | Keys | Dynamic — any number, validated by [keySchema] | Fixed — defined in the shape |
/// | Use case | Dictionaries, lookup tables | Structured records |
/// | Output type | `Map<K, V>` | `Map<String, dynamic>` or `T` |
///
/// ## Validation
///
/// 1. **Type check** — input must be a `Map` (`invalid_type` on failure).
/// 2. **Size constraints** — [minSize] and [maxSize] are checked before entries
///    (`too_small` / `too_big`).
/// 3. **Entry validation** — every key is validated by [keySchema] and every
///    value by [valueSchema]. Validation is **exhaustive**: all entry failures
///    are collected before returning. Issues are scoped to the entry's key
///    string in [ZemaIssue.path].
///
/// ## Examples
///
/// ```dart
/// // Map from string keys to non-negative integer scores
/// final scoreSchema = z.map(
///   z.string(),
///   z.int().gte(0),
/// );
///
/// scoreSchema.parse({'alice': 95, 'bob': 87}); // Map<String, int>
///
/// // Map from validated string keys to validated string values
/// final headersSchema = z.map(
///   z.string().min(1),
///   z.string(),
/// );
///
/// // Size constraints
/// z.map(z.string(), z.int()).min(1)    // at least one entry
/// z.map(z.string(), z.int()).max(100)  // at most 100 entries
/// ```
///
/// See also:
/// - [ZemaObject] — for maps with a fixed, named set of fields.
/// - `z.map` — factory method in [Zema].
final class ZemaMap<K, V> extends ZemaSchema<dynamic, Map<K, V>> {
  /// Schema applied to every key in the input map.
  final ZemaSchema<dynamic, K> keySchema;

  /// Schema applied to every value in the input map.
  final ZemaSchema<dynamic, V> valueSchema;

  /// Minimum number of entries (inclusive). `null` means no lower bound.
  final int? minSize;

  /// Maximum number of entries (inclusive). `null` means no upper bound.
  final int? maxSize;

  const ZemaMap(
    this.keySchema,
    this.valueSchema, {
    this.minSize,
    this.maxSize,
  });

  @override
  ZemaResult<Map<K, V>> safeParse(dynamic value) {
    if (value is! Map) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_type',
          message: ZemaI18n.translate(
            'invalid_type',
            params: {
              'expected': 'Map',
              'received': value.runtimeType.toString(),
            },
          ),
          receivedValue: value,
          meta: {'expected': 'Map', 'received': value.runtimeType.toString()},
        ),
      );
    }

    if (minSize != null && value.length < minSize!) {
      return singleFailure(
        ZemaIssue(
          code: 'too_small',
          message: ZemaI18n.translate(
            'too_small',
            params: {
              'min': minSize,
              'actual': value.length,
            },
          ),
          receivedValue: value.length,
          meta: {'min': minSize, 'actual': value.length},
        ),
      );
    }

    if (maxSize != null && value.length > maxSize!) {
      return singleFailure(
        ZemaIssue(
          code: 'too_big',
          message: ZemaI18n.translate(
            'too_big',
            params: {
              'max': maxSize,
              'actual': value.length,
            },
          ),
          receivedValue: value.length,
          meta: {'max': maxSize, 'actual': value.length},
        ),
      );
    }

    final errors = <ZemaIssue>[];
    final parsed = <K, V>{};

    for (final entry in value.entries) {
      // Validate key
      final keyResult = keySchema.safeParse(entry.key);
      if (keyResult.isFailure) {
        errors.addAll(
          keyResult.errors.map(
            (issue) => issue.withPath(entry.key.toString()),
          ),
        );
      }

      // Validate value
      final valueResult = valueSchema.safeParse(entry.value);
      if (valueResult.isFailure) {
        errors.addAll(
          valueResult.errors.map(
            (issue) => issue.withPath(entry.key.toString()),
          ),
        );
      }

      if (keyResult.isSuccess && valueResult.isSuccess) {
        parsed[keyResult.value] = valueResult.value;
      }
    }

    if (errors.isNotEmpty) {
      return failure(errors);
    }

    return success(parsed);
  }

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Requires the map to have at least [size] entries.
  ///
  /// Produces a `too_small` issue on failure. Entry validation is skipped
  /// when this check fails.
  ///
  /// ```dart
  /// z.map(z.string(), z.int()).min(1)  // non-empty map
  /// ```
  ZemaMap<K, V> min(int size) =>
      ZemaMap(keySchema, valueSchema, minSize: size, maxSize: maxSize);

  /// Requires the map to have at most [size] entries.
  ///
  /// Produces a `too_big` issue on failure. Entry validation is skipped
  /// when this check fails.
  ///
  /// ```dart
  /// z.map(z.string(), z.string()).max(50)
  /// ```
  ZemaMap<K, V> max(int size) =>
      ZemaMap(keySchema, valueSchema, minSize: minSize, maxSize: size);
}
