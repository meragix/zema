import 'package:meta/meta.dart';
import 'package:zema/src/coercion/coerce.dart';
import 'package:zema/src/complex/complex.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/custom/custom_schema.dart';
import 'package:zema/src/effects/lazy.dart';
import 'package:zema/src/primitives/primitives.dart';

/// The Zema schema factory — the single namespace for constructing schemas.
///
/// You never instantiate [Zema] directly. Use the global [z] constant (or its
/// alias [zema]) which holds the single shared instance:
///
/// ```dart
/// import 'package:zema/zema.dart';
///
/// final schema = z.object({
///   'name':  z.string().min(2),
///   'email': z.string().email(),
///   'age':   z.int().gte(0).optional(),
/// });
/// ```
///
/// ## Schema families
///
/// | Factory method | Schema type | Output type |
/// |---|---|---|
/// | [string] | [ZemaString] | `String` |
/// | [int] | [ZemaInt] | `int` |
/// | [double] | [ZemaDouble] | `double` |
/// | [boolean] | [ZemaBool] | `bool` |
/// | [array] | [ZemaArray] | `List<T>` |
/// | [object] | [ZemaObject] | `Map<String, dynamic>` |
/// | [objectAs] | [ZemaObject] | `T extends Object` |
/// | [map] | [ZemaMap] | `Map<K, V>` |
/// | [union] | [ZemaUnion] | `T` |
/// | [literal] | [ZemaLiteral] | `T` |
/// | [lazy] | [ZemaSchema] | `O` |
/// | [custom] | [ZemaSchema] | `T` |
/// | [coerce] | [ZemaCoerce] | — (sub-namespace) |
///
/// See also:
/// - [z] — the global constant to use in application code.
/// - [ZemaSchema] — base class with parse, transform, and modifier methods.
@immutable
class Zema {
  const Zema._();

  static const Zema instance = Zema._();

  // ===========================================================================
  // PRIMITIVE SCHEMAS
  // ===========================================================================

  /// Creates a [ZemaString] schema that validates `String` values.
  ///
  /// The returned schema accepts any `String`. Chain validation methods to
  /// add constraints:
  ///
  /// ```dart
  /// z.string()                    // any string
  /// z.string().min(2)             // at least 2 characters
  /// z.string().max(100)           // at most 100 characters
  /// z.string().email()            // valid email address
  /// z.string().url()              // valid URL
  /// z.string().uuid()             // valid UUID v4
  /// z.string().trim().min(1)      // trim whitespace, then check length
  /// z.string().oneOf(['a', 'b'])  // must be one of the listed values
  /// ```
  ///
  /// Non-string input produces an `invalid_type` issue.
  ZemaString string() => const ZemaString();

  /// Creates a [ZemaInt] schema that validates `int` values.
  ///
  /// The returned schema accepts Dart `int`s only — not `double`s or numeric
  /// strings. Chain constraint methods to add range or sign checks:
  ///
  /// ```dart
  /// z.int()              // any integer
  /// z.int().gte(0)       // >= 0
  /// z.int().lte(100)     // <= 100
  /// z.int().positive()   // > 0
  /// z.int().negative()   // < 0
  /// z.int().step(5)      // must be a multiple of 5
  /// ```
  ///
  /// To accept a wider set of numeric inputs (strings, doubles), use
  /// [coerce] instead: `z.coerce().integer()`.
  ///
  /// Non-integer input produces an `invalid_type` issue.
  ZemaInt int() => const ZemaInt();

  /// Creates a [ZemaDouble] schema that validates `double` values.
  ///
  /// The returned schema accepts Dart `double`s only. Chain constraint methods
  /// to add range or finiteness checks:
  ///
  /// ```dart
  /// z.double()            // any double
  /// z.double().gte(0.0)   // >= 0.0
  /// z.double().lte(1.0)   // <= 1.0
  /// z.double().positive() // > 0.0
  /// z.double().finite()   // must not be NaN or Infinity
  /// ```
  ///
  /// To accept strings or integers as input, use [coerce]: `z.coerce().float()`.
  ///
  /// Non-double input produces an `invalid_type` issue.
  ZemaDouble double() => const ZemaDouble();

  /// Creates a [ZemaBool] schema that validates `bool` values.
  ///
  /// The returned schema accepts Dart `bool`s only (`true` or `false`):
  ///
  /// ```dart
  /// z.boolean()  // true or false
  /// ```
  ///
  /// To coerce truthy/falsy values from strings or integers, use [coerce]:
  /// `z.coerce().boolean()`.
  ///
  /// Non-bool input produces an `invalid_type` issue.
  ZemaBool boolean() => const ZemaBool();

  // ===========================================================================
  // COMPLEX SCHEMAS
  // ===========================================================================

  /// Creates a [ZemaArray] schema that validates `List` values.
  ///
  /// Every element in the list is validated against [element]. Validation is
  /// exhaustive — all element failures are collected before returning.
  ///
  /// ```dart
  /// z.array(z.string())           // List of strings
  /// z.array(z.int().positive())   // List of positive integers
  ///
  /// z.array(z.object({
  ///   'id':   z.int(),
  ///   'name': z.string(),
  /// }));
  /// ```
  ///
  /// Element issues include the array index in their `path`:
  /// `ZemaIssue(path: [2, 'name'], ...)` for the `name` field of item at index 2.
  ZemaArray<T> array<T>(ZemaSchema<dynamic, T> element) => ZemaArray(element);

  /// Creates a [ZemaObject] schema that validates `Map` values.
  ///
  /// [shape] defines the expected fields — each key maps to the schema that
  /// validates its value. Extra keys in the input are silently ignored by
  /// default (use `.makeStrict()` to reject them). Missing optional fields
  /// arrive as `null` and are validated by their respective schema.
  ///
  /// The validated output type is `Map<String, dynamic>`. To get a typed
  /// model class directly, use [objectAs] instead.
  ///
  /// ```dart
  /// final userSchema = z.object({
  ///   'name':  z.string().min(2),
  ///   'email': z.string().email(),
  ///   'age':   z.int().gte(0).optional(),
  /// });
  ///
  /// final result = userSchema.safeParse(json);
  /// ```
  ///
  /// Key [ZemaObject] methods available on the returned schema:
  /// - `.extend(shape)` — adds fields to the schema.
  /// - `.pick([keys])` — keeps only specific fields.
  /// - `.omit([keys])` — removes specific fields.
  /// - `.makeStrict()` — rejects unknown keys.
  ///
  /// See also:
  /// - [objectAs] — produces a typed `T` instead of a raw map.
  ZemaObject<Map<String, dynamic>> object(
    Map<String, ZemaSchema<dynamic, dynamic>> shape,
  ) =>
      ZemaObject(shape);

  /// Creates a typed [ZemaObject] schema that validates `Map` values and maps
  /// the result to a custom class [T] via [constructor].
  ///
  /// The [shape] defines and validates the fields exactly like [object]. Once
  /// validation passes, the cleaned `Map<String, dynamic>` is handed to
  /// [constructor] to build the final [T] instance.
  ///
  /// ```dart
  /// final userSchema = z.objectAs(
  ///   {
  ///     'name':  z.string().min(2),
  ///     'email': z.string().email(),
  ///   },
  ///   (map) => User(name: map['name'], email: map['email']),
  /// );
  ///
  /// final user = userSchema.parse(json); // User instance, not a Map
  /// ```
  ///
  /// If [constructor] throws, the parse fails with a `transform_error` issue.
  ///
  /// See also:
  /// - [object] — produces `Map<String, dynamic>` without a constructor.
  ZemaObject<T> objectAs<T extends Object>(
    Map<String, ZemaSchema<dynamic, dynamic>> shape,
    T Function(Map<String, dynamic>) constructor,
  ) =>
      ZemaObject(shape, constructor: constructor);

  /// Creates a [ZemaMap] schema that validates `Map<K, V>` values.
  ///
  /// Unlike [object] (which validates a *fixed* set of known string keys),
  /// [ZemaMap] validates a *dynamic* map where every key is validated by
  /// [keySchema] and every value by [valueSchema]. Use this for dictionaries
  /// and lookup tables with an arbitrary number of entries.
  ///
  /// ```dart
  /// // { 'user_123': 42, 'user_456': 7 }
  /// final scoreSchema = z.map(
  ///   z.string(),      // key must be a string
  ///   z.int().gte(0),  // value must be a non-negative int
  /// );
  /// ```
  ///
  /// See also:
  /// - [object] — for maps with a fixed, known set of string keys.
  ZemaMap<K, V> map<K, V>(
    ZemaSchema<dynamic, K> keySchema,
    ZemaSchema<dynamic, V> valueSchema,
  ) =>
      ZemaMap(keySchema, valueSchema);

  /// Creates a [ZemaUnion] schema that accepts values valid for **any** of
  /// the given [schemas].
  ///
  /// Schemas are tried in order. The first one that succeeds determines the
  /// output. If all schemas fail, the issues from all attempts are combined
  /// into a single failure.
  ///
  /// ```dart
  /// // Accept either a UUID string or an integer ID
  /// final idSchema = z.union([z.string().uuid(), z.int().positive()]);
  ///
  /// idSchema.parse('550e8400-e29b-41d4-a716-446655440000'); // string UUID
  /// idSchema.parse(42);                                      // int
  /// idSchema.parse(true);                                    // fails
  /// ```
  ///
  /// For discriminated unions, parse the discriminant field first and delegate
  /// to the matching schema.
  ZemaUnion<T> union<T>(List<ZemaSchema<dynamic, T>> schemas) =>
      ZemaUnion(schemas);

  // ===========================================================================
  // SPECIAL SCHEMAS
  // ===========================================================================

  /// Creates a [ZemaLiteral] schema that accepts **only** the exact [value].
  ///
  /// Equality is checked with `==`. Any other value produces an
  /// `invalid_literal` issue.
  ///
  /// ```dart
  /// z.literal('admin').parse('admin');  // 'admin'
  /// z.literal('admin').parse('user');   // fails
  ///
  /// z.literal(42).parse(42);            // 42
  /// z.literal(true).parse(true);        // true
  ///
  /// // Combine with union for a closed set of values
  /// final roleSchema = z.union([
  ///   z.literal('admin'),
  ///   z.literal('editor'),
  ///   z.literal('viewer'),
  /// ]);
  /// ```
  ZemaLiteral<T> literal<T>(T value) => ZemaLiteral(value);

  /// Creates a lazy schema for **self-referential** or **mutually recursive**
  /// types.
  ///
  /// [fn] is called on the first parse, not at construction time. This breaks
  /// the circular dependency that would otherwise cause a stack overflow when
  /// two schemas reference each other.
  ///
  /// ```dart
  /// // A tree node that can contain child nodes of the same type
  /// late final ZemaSchema<dynamic, dynamic> nodeSchema;
  ///
  /// nodeSchema = z.object({
  ///   'value':    z.int(),
  ///   'children': z.array(z.lazy(() => nodeSchema)).optional(),
  /// });
  /// ```
  ZemaSchema<I, O> lazy<I, O>(ZemaSchema<I, O> Function() fn) =>
      LazySchema(fn);

  /// Creates a schema backed by an arbitrary predicate function.
  ///
  /// [validator] receives the (already type-checked) value and returns `true`
  /// if valid. If it returns `false`, a single issue with the given [message]
  /// (default: `'Custom validation failed'`) is produced.
  ///
  /// Use [custom] for lightweight one-off rules. For richer control —
  /// multiple issues, async checks, or access to context — use `.refine()`,
  /// `.refineAsync()`, or `.superRefine()` on an existing schema instead.
  ///
  /// ```dart
  /// final palindrome = z.custom<String>(
  ///   (s) => s == s.split('').reversed.join(),
  ///   message: 'Must be a palindrome',
  /// );
  ///
  /// palindrome.parse('racecar'); // 'racecar'
  /// palindrome.parse('hello');   // fails
  /// ```
  ZemaSchema<T, T> custom<T>(
    bool Function(T) validator, {
    String? message,
  }) =>
      CustomSchema(validator, message);

  // ===========================================================================
  // COERCION SUB-NAMESPACE
  // ===========================================================================

  /// Returns the [ZemaCoerce] sub-namespace for coercing values to a target type.
  ///
  /// Coercion schemas convert compatible inputs before validating them, making
  /// them suitable for form data, query strings, or JSON payloads where numbers
  /// or booleans arrive as strings.
  ///
  /// ```dart
  /// z.coerce().integer()   // '42' → 42
  /// z.coerce().float()     // '3.14' → 3.14
  /// z.coerce().boolean()   // 'true' | 1 → true
  /// z.coerce().string()    // 123 → '123'
  /// ```
  ///
  /// See [ZemaCoerce] for the full list of coercion schemas and their rules.
  ZemaCoerce coerce() => const ZemaCoerce();
}

/// The global Zema schema factory.
///
/// Use `z` as the single entry point for all schema construction:
///
/// ```dart
/// import 'package:zema/zema.dart';
///
/// final loginSchema = z.object({
///   'email':    z.string().email(),
///   'password': z.string().min(8),
///   'remember': z.boolean().withDefault(false),
/// });
///
/// final result = loginSchema.safeParse(requestBody);
///
/// result.when(
///   success: (data)   => authenticate(data['email'], data['password']),
///   failure: (errors) => respond(400, errors.format()),
/// );
/// ```
///
/// See [Zema] for documentation on all available schema factories.
const z = Zema.instance;

/// Alias for [z].
///
/// Identical to [z] in every way. Prefer [z] for brevity in application code.
/// Use [zema] if you prefer a more explicit, searchable name in your codebase.
///
/// ```dart
/// final schema = zema.string().email();
/// ```
const zema = z;
