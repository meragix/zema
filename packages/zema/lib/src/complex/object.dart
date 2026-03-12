import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that validates `Map` values against a fixed set of named fields.
///
/// Construct via `z.object(shape)` or `z.objectAs(shape, constructor)` —
/// do not instantiate directly.
///
/// ## Validation
///
/// Each key in [shape] is looked up in the input map and validated by its
/// corresponding schema. The validation is **exhaustive**: every field is
/// checked and all failures are collected before returning. Field-level issues
/// have the field name prepended to their [ZemaIssue.path], so you always know
/// which field failed:
///
/// ```
/// ZemaIssue(code: 'too_short', path: ['name'], ...)
/// ZemaIssue(code: 'invalid_email', path: ['email'], ...)
/// ```
///
/// ## Extra keys
///
/// By default, keys present in the input but absent from [shape] are silently
/// ignored and stripped from the output. Call [makeStrict] to reject them with
/// an `unknown_key` issue instead.
///
/// ## Missing keys
///
/// A key absent from the input map arrives as `null`. Whether that is valid
/// depends on the field's schema:
/// - `z.string()` — fails with `invalid_type` (null is not a String).
/// - `z.string().optional()` — succeeds, producing `null` in the output.
/// - `z.string().withDefault('x')` — succeeds, substituting `'x'`.
///
/// ## Typed output
///
/// When [constructor] is `null` (the default via `z.object()`), the output
/// type `T` is `Map<String, dynamic>`. When [constructor] is provided (via
/// `z.objectAs()`), the cleaned map is passed to it and the result is `T`.
/// If [constructor] throws, a `transform_error` issue is produced.
///
/// ```dart
/// // Untyped — output is Map<String, dynamic>
/// final schema = z.object({
///   'name':  z.string().min(2),
///   'email': z.string().email(),
/// });
///
/// // Typed — output is User
/// final typedSchema = z.objectAs(
///   {
///     'name':  z.string().min(2),
///     'email': z.string().email(),
///   },
///   (map) => User(name: map['name'], email: map['email']),
/// );
/// ```
///
/// See also:
/// - [ZemaMap] — for maps with a dynamic set of keys validated uniformly.
/// - `z.object` / `z.objectAs` — factory methods in [Zema].
final class ZemaObject<T> extends ZemaSchema<dynamic, T> {
  /// The field definitions. Each key maps to the schema that validates it.
  final Map<String, ZemaSchema<dynamic, dynamic>> shape;

  /// Optional constructor that maps the validated `Map<String, dynamic>` to [T].
  /// When `null`, the raw cleaned map is cast to [T] directly.
  final T Function(Map<String, dynamic>)? constructor;

  /// When `true`, keys in the input that are not in [shape] produce
  /// `unknown_key` issues. Defaults to `false` (extra keys are ignored).
  final bool strict;

  const ZemaObject(
    this.shape, {
    this.constructor,
    this.strict = false,
  });

  @override
  ZemaResult<T> safeParse(dynamic value) {
    if (value is! Map) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_type',
          message: ZemaI18n.translate(
            'invalid_type',
            params: {
              'expected': 'object',
              'received': value.runtimeType.toString(),
            },
          ),
          receivedValue: value,
          meta: {
            'expected': 'object',
            'received': value.runtimeType.toString(),
          },
        ),
      );
    }

    final cleaned = <String, dynamic>{};
    final allIssues = <ZemaIssue>[];

    for (final entry in shape.entries) {
      final key = entry.key;
      final schema = entry.value;
      final fieldValue = value[key];

      final result = schema.safeParse(fieldValue);

      if (result.isFailure) {
        for (final issue in result.errors) {
          allIssues.add(issue.withPath(key));
        }
      } else {
        cleaned[key] = result.value;
      }
    }

    // Strict mode: check for unknown keys
    if (strict) {
      for (final key in value.keys) {
        if (!shape.containsKey(key)) {
          allIssues.add(
            ZemaIssue(
              code: 'unknown_key',
              message: 'Unknown key: $key',
              path: [key.toString()],
            ),
          );
        }
      }
    }

    if (allIssues.isNotEmpty) {
      return failure(allIssues);
    }

    if (constructor != null) {
      try {
        return success(constructor!(cleaned));
      } catch (e) {
        return singleFailure(
          ZemaIssue(
            code: 'transform_error',
            message: ZemaI18n.translate('transform_error'),
          ),
        );
      }
    }

    return success(cleaned as T);
  }

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Applies [mapper] to the validated output [T], producing a new schema
  /// with output type [R].
  ///
  /// Shorthand for `.transform(mapper)` scoped to object outputs:
  ///
  /// ```dart
  /// final schema = z.object({'name': z.string()})
  ///     .map((map) => User.fromJson(map));
  /// // schema output type is User
  /// ```
  ZemaSchema<dynamic, R> map<R>(R Function(T) mapper) => transform(mapper);

  /// Returns a copy of this schema that rejects keys not present in [shape].
  ///
  /// Any extra key in the input produces an `unknown_key` issue whose
  /// [ZemaIssue.path] contains the offending key name.
  ///
  /// ```dart
  /// final strict = z.object({'name': z.string()}).makeStrict();
  ///
  /// strict.parse({'name': 'Alice'});                    // OK
  /// strict.parse({'name': 'Alice', 'extra': 'value'});  // fails — unknown_key
  /// ```
  ZemaObject<T> makeStrict() => ZemaObject(
        shape,
        constructor: constructor,
        strict: true,
      );

  /// Returns a new schema with [additionalShape] merged into the existing
  /// [shape].
  ///
  /// Fields in [additionalShape] override fields with the same key. The
  /// returned schema always has output type `Map<String, dynamic>` —
  /// the typed constructor is not carried over.
  ///
  /// ```dart
  /// final base = z.object({'name': z.string()});
  /// final extended = base.extend({'age': z.int().gte(0)});
  /// // extended validates both 'name' and 'age'
  /// ```
  ZemaObject<Map<String, dynamic>> extend(
    Map<String, ZemaSchema<dynamic, dynamic>> additionalShape,
  ) {
    return ZemaObject({...shape, ...additionalShape});
  }

  /// Returns a new schema containing **only** the fields listed in [keys].
  ///
  /// Keys not present in the current [shape] are silently ignored.
  /// The returned schema always has output type `Map<String, dynamic>`.
  ///
  /// ```dart
  /// final full = z.object({
  ///   'id':    z.int(),
  ///   'name':  z.string(),
  ///   'email': z.string().email(),
  /// });
  ///
  /// final public = full.pick(['id', 'name']); // email excluded
  /// ```
  ZemaObject<Map<String, dynamic>> pick(List<String> keys) {
    final pickedShape = <String, ZemaSchema<dynamic, dynamic>>{};
    for (final key in keys) {
      if (shape.containsKey(key)) {
        pickedShape[key] = shape[key]!;
      }
    }
    return ZemaObject(pickedShape);
  }

  /// Returns a new schema with the fields listed in [keys] removed.
  ///
  /// Keys not present in the current [shape] are silently ignored.
  /// The returned schema always has output type `Map<String, dynamic>`.
  ///
  /// ```dart
  /// final full = z.object({
  ///   'id':       z.int(),
  ///   'name':     z.string(),
  ///   'password': z.string(),
  /// });
  ///
  /// final safe = full.omit(['password']); // password excluded from output
  /// ```
  ZemaObject<Map<String, dynamic>> omit(List<String> keys) {
    final omittedShape = Map<String, ZemaSchema<dynamic, dynamic>>.from(shape);
    for (final key in keys) {
      omittedShape.remove(key);
    }
    return ZemaObject(omittedShape);
  }
}
