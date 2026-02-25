import 'package:zema/src/core/result.dart';
import 'package:zema/zema.dart';

/// A schema that accepts a value if **any** of the given [schemas] succeeds.
///
/// Construct via `z.union(schemas)` — do not instantiate directly.
///
/// ## Validation
///
/// Schemas are tried in the order they appear in [schemas]. The first one
/// that succeeds determines the output — remaining schemas are not evaluated.
/// If **all** schemas fail, a single `invalid_union` issue is returned. Its
/// `meta` map contains:
///
/// - `'unionErrors'` — a `List<List<ZemaIssue>>` with each schema's errors.
/// - `'schemaCount'` — the total number of schemas tried.
/// - `'receivedType'` — the runtime type of the input as a string.
/// - `'discriminator'` — the discriminator key, if one was provided.
///
/// ## Examples
///
/// ```dart
/// // Accept either a UUID string or a positive integer ID
/// final idSchema = z.union([
///   z.string().uuid(),
///   z.int().positive(),
/// ]);
///
/// idSchema.parse('550e8400-e29b-41d4-a716-446655440000'); // string UUID
/// idSchema.parse(42);                                      // int
/// idSchema.parse(true);                                    // fails
///
/// // Combine literal schemas for a closed set of string values
/// final statusSchema = z.union([
///   z.literal('pending'),
///   z.literal('active'),
///   z.literal('archived'),
/// ]);
/// ```
///
/// ## Ordering matters
///
/// Because the first matching schema wins, place more specific schemas before
/// broader ones. For example, put `z.literal('admin')` before `z.string()`
/// if you want the literal to be matched with a distinct output type.
///
/// ## Discriminated unions (future)
///
/// The [discriminator] field is reserved for a future optimisation where a
/// known key in the input map is used to select the matching schema directly,
/// avoiding a linear scan. It is not yet fully implemented — all schemas are
/// still tried in order regardless.
///
/// See also:
/// - `z.union` — factory method in [Zema].
/// - `z.literal` — for exact-value schemas often used inside unions.
final class ZemaUnion<T> extends ZemaSchema<dynamic, T> {
  /// The candidate schemas, tried in order until one succeeds.
  final List<ZemaSchema<dynamic, T>> schemas;

  /// Reserved for future discriminated-union optimisation. Has no effect yet.
  final String? discriminator;

  const ZemaUnion(this.schemas, {this.discriminator});

  @override
  ZemaResult<T> safeParse(dynamic value) {
    final unionErrors = <List<ZemaIssue>>[];

    // If discriminated union, try to fast-path
    // Fast path discriminated union (to be implemented properly later)
    if (discriminator != null && value is Map) {
      final discValue = value[discriminator];
      if (discValue != null) {
        // Try to match discriminator-specific schema first
        // (would need schema metadata for this optimization)
      }
    }

    // Try each schema until one succeeds
    for (final schema in schemas) {
      final result = schema.safeParse(value);
      if (result.isSuccess) {
        return result;
      }
      unionErrors.add(result.errors);
    }

    // All schemas failed — return a single issue with full diagnostics
    return singleFailure(
      ZemaIssue(
        code: 'invalid_union',
        message: ZemaI18n.translate('invalid_union'),
        meta: {
          'unionErrors': unionErrors,
          'schemaCount': schemas.length,
          if (discriminator != null) 'discriminator': discriminator,
          'receivedType': value.runtimeType.toString(),
        },
      ),
    );
  }
}
