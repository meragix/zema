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
///   z.integer().positive(),
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
/// ## Discriminated unions
///
/// Call [discriminatedBy] to name a field whose [ZemaLiteral] value is used
/// to select the matching [ZemaObject] schema directly, skipping the linear
/// scan. Each schema in [schemas] must be a [ZemaObject] with a [ZemaLiteral]
/// at the named field.
///
/// ```dart
/// final schema = z.union([
///   z.object({'type': z.literal('click'),    'x': z.integer(), 'y': z.integer()}),
///   z.object({'type': z.literal('keypress'), 'key': z.string()}),
/// ]).discriminatedBy('type');
///
/// schema.parse({'type': 'click',    'x': 100, 'y': 200}); // validated directly
/// schema.parse({'type': 'keypress', 'key': 'Enter'});      // validated directly
/// ```
///
/// See also:
/// - `z.union` — factory method in [Zema].
/// - `z.literal` — for exact-value schemas often used inside unions.
final class ZemaUnion<T> extends ZemaSchema<dynamic, T> {
  /// The candidate schemas, tried in order until one succeeds.
  final List<ZemaSchema<dynamic, T>> schemas;

  /// When set, names a field whose [ZemaLiteral] value selects the matching
  /// [ZemaObject] schema directly. Set via [discriminatedBy].
  final String? discriminator;

  const ZemaUnion(this.schemas, {this.discriminator});

  @override
  ZemaResult<T> safeParse(dynamic value) {
    // Discriminated union fast-path: use the discriminator field value to
    // select the matching ZemaObject schema directly.
    if (discriminator != null && value is Map) {
      final discValue = value[discriminator];
      // Iterate as dynamic so the is-check narrows to ZemaObject<dynamic>.
      for (final dynamic schema in schemas) {
        if (schema is ZemaObject<dynamic>) {
          final discSchema = schema.shape[discriminator!];
          if (discSchema is ZemaLiteral && discSchema.value == discValue) {
            return schema.safeParse(value) as ZemaResult<T>;
          }
        }
      }
      // No schema matched the discriminator value.
      return singleFailure(
        ZemaIssue(
          code: 'invalid_union',
          message: ZemaI18n.translate('invalid_union'),
          meta: {
            'discriminator': discriminator,
            'receivedType': value.runtimeType.toString(),
          },
        ),
      );
    }

    // Linear scan: try each schema until one succeeds.
    final unionErrors = <List<ZemaIssue>>[];
    for (final schema in schemas) {
      final result = schema.safeParse(value);
      if (result.isSuccess) {
        return result;
      }
      unionErrors.add(result.errors);
    }

    // All schemas failed — return a single issue with full diagnostics.
    return singleFailure(
      ZemaIssue(
        code: 'invalid_union',
        message: ZemaI18n.translate('invalid_union'),
        meta: {
          'unionErrors': unionErrors,
          'schemaCount': schemas.length,
          'receivedType': value.runtimeType.toString(),
        },
      ),
    );
  }

  /// Returns a new schema that uses [field] as a discriminator key to select
  /// the matching [ZemaObject] schema directly, skipping the linear scan.
  ///
  /// Every schema in [schemas] must be a [ZemaObject] with a [ZemaLiteral]
  /// at [field]. On parse, the value at [field] is compared against each
  /// schema's literal until a match is found. Only the matching schema is
  /// validated.
  ///
  /// If no schema's literal matches the input's discriminator value, an
  /// `invalid_union` issue is returned without trying any schema.
  ///
  /// ```dart
  /// final schema = z.union([
  ///   z.object({'type': z.literal('click'),    'x': z.integer(), 'y': z.integer()}),
  ///   z.object({'type': z.literal('keypress'), 'key': z.string()}),
  /// ]).discriminatedBy('type');
  ///
  /// schema.parse({'type': 'click',    'x': 100, 'y': 200});
  /// schema.parse({'type': 'keypress', 'key': 'Enter'});
  /// schema.parse({'type': 'unknown'});  // fails — invalid_union
  /// ```
  ZemaUnion<T> discriminatedBy(String field) =>
      ZemaUnion(schemas, discriminator: field);
}
