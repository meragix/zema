import 'dart:isolate';

import 'package:zema/src/core/result.dart';
import 'package:zema/src/error/exception.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/modifiers/default.dart';
import 'package:zema/src/modifiers/nullable.dart';
import 'package:zema/src/modifiers/optional.dart';
import 'package:zema/src/transformers/catch.dart';
import 'package:zema/src/transformers/pipe.dart';
import 'package:zema/src/transformers/preprocess.dart';
import 'package:zema/src/transformers/transform.dart';

/// The foundation of every Zema schema.
///
/// [ZemaSchema] is a generic, immutable description of a validation rule.
/// It accepts a value of type [Input], validates it, and—if valid—produces
/// a value of type [Output]. [Input] and [Output] may differ when
/// transformations are applied (see [transform] and [pipe]).
///
/// Every concrete schema (e.g. [ZemaString], [ZemaObject]) extends this class
/// and implements [safeParse]. All other methods are derived from it.
///
/// ## Parsing
///
/// There are four ways to parse a value:
///
/// | Method | Throws | Async |
/// |---|---|---|
/// | [parse] | Yes ([ZemaException]) | No |
/// | [safeParse] | No (returns [ZemaResult]) | No |
/// | [parseAsync] | Yes ([ZemaException]) | Yes |
/// | [safeParseAsync] | No (returns [ZemaResult]) | Yes |
///
/// Prefer [safeParse] when you need to handle errors without try/catch.
/// Use [parse] when a failure is truly unexpected and should be treated as
/// a programming error.
///
/// ## Example
///
/// ```dart
/// final schema = z.object({
///   'name': z.string().min(2),
///   'age':  z.int().gte(0),
/// });
///
/// // Throws ZemaException on invalid input
/// final user = schema.parse({'name': 'Alice', 'age': 30});
///
/// // Returns ZemaResult — never throws
/// final result = schema.safeParse({'name': 'X', 'age': -1});
/// if (result.isFailure) {
///   for (final issue in result.errors) {
///     print('${issue.pathString}: ${issue.message}');
///   }
/// }
/// ```
///
/// ## Composition
///
/// Schemas are composable and immutable. Every method returns a **new**
/// schema; the original is never mutated. This makes schemas safe to share
/// and reuse across your application.
///
/// ```dart
/// final base    = z.string().min(2);
/// final trimmed = base.transform((s) => s.trim()); // base is unchanged
/// final opt     = base.optional();                  // base is unchanged
/// ```
///
/// Type parameters:
/// - [Input]  — the raw type accepted by [safeParse] (often `dynamic`).
/// - [Output] — the validated, possibly-transformed type produced on success.
abstract class ZemaSchema<Input, Output> {
  const ZemaSchema();

  // ===========================================================================
  // PARSING
  // ===========================================================================

  /// Parses [value] and returns the validated [Output].
  ///
  /// Throws a [ZemaException] that bundles **all** collected [ZemaIssue]s if
  /// validation fails. Use this when invalid input is a programming error and
  /// you want a hard crash rather than conditional error-handling.
  ///
  /// ```dart
  /// // Succeeds — returns the validated value
  /// final name = z.string().min(2).parse('Alice'); // 'Alice'
  ///
  /// // Fails — throws ZemaException
  /// z.string().min(2).parse('X');
  /// ```
  ///
  /// See also:
  /// - [safeParse] — returns a [ZemaResult] instead of throwing.
  /// - [parseAsync] — the async equivalent.
  Output parse(Input value) {
    final result = safeParse(value);
    if (result.isFailure) {
      throw ZemaException(result.errors);
    }
    return result.value;
  }

  /// Parses [value] and returns a [ZemaResult] — never throws.
  ///
  /// On success, returns [ZemaSuccess] wrapping the validated [Output].
  /// On failure, returns [ZemaFailure] wrapping every [ZemaIssue] collected
  /// during validation. Validation is **exhaustive**: all issues are reported,
  /// not just the first one.
  ///
  /// This is the **primary method** to override when creating a new schema.
  /// All other parse methods delegate to it.
  ///
  /// ```dart
  /// final result = z.string().email().safeParse('not-an-email');
  ///
  /// switch (result) {
  ///   case ZemaSuccess(:final value):
  ///     print('Valid: $value');
  ///   case ZemaFailure(:final errors):
  ///     print('Invalid: ${errors.first.message}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [parse] — throws on failure instead.
  /// - [safeParseAsync] — the async equivalent.
  ZemaResult<Output> safeParse(Input value);

  /// Asynchronously parses [value] and returns the validated [Output].
  ///
  /// Behaves exactly like [parse] but awaits [safeParseAsync] internally.
  /// Throws a [ZemaException] if validation fails.
  ///
  /// Use this when the schema chain contains at least one async step
  /// (e.g. a schema built with [ZemaSchema.pipe] over a schema that overrides
  /// [safeParseAsync], or a schema refined with `refineAsync`).
  ///
  /// ```dart
  /// final result = await schema.parseAsync(rawInput);
  /// ```
  ///
  /// See also:
  /// - [safeParseAsync] — returns [ZemaResult] instead of throwing.
  /// - [parse] — the synchronous equivalent.
  Future<Output> parseAsync(Input value) async {
    final result = await safeParseAsync(value);
    if (result.isFailure) {
      throw ZemaException(result.errors);
    }
    return result.value;
  }

  /// Asynchronously parses [value] and returns a [ZemaResult] — never throws.
  ///
  /// The default implementation simply delegates to [safeParse], so sync-only
  /// schemas work transparently in async pipelines without any extra code.
  ///
  /// **Override this** when your schema needs to perform I/O or other
  /// async work as part of validation (e.g. checking a value against a
  /// database). In that case, also call `super.safeParseAsync` (or
  /// `safeParse`) first and short-circuit on failure.
  ///
  /// ```dart
  /// @override
  /// Future<ZemaResult<String>> safeParseAsync(dynamic value) async {
  ///   final result = safeParse(value);
  ///   if (result.isFailure) return result;
  ///
  ///   final exists = await db.usernameExists(result.value);
  ///   if (exists) {
  ///     return singleFailure(ZemaIssue(
  ///       code: 'username_taken',
  ///       message: 'Username is already taken.',
  ///     ));
  ///   }
  ///   return result;
  /// }
  /// ```
  ///
  /// See also:
  /// - [safeParseAsync] — the non-throwing variant.
  /// - [parseAsync] — throws on failure.
  Future<ZemaResult<Output>> safeParseAsync(Input value) async {
    return safeParse(value);
  }

  /// Runs [safeParse] in a separate [Isolate] and returns the result.
  ///
  /// Offloads CPU-intensive validation to a background isolate so the Flutter
  /// UI thread is not blocked. Returns a `Future<ZemaResult<Output>>` that
  /// resolves when the isolate finishes.
  ///
  /// ```dart
  /// // Parse a large JSON payload without freezing the UI
  /// final result = await schema.parseInIsolate(largePayload);
  /// ```
  ///
  /// ## Important limitations
  ///
  /// Dart isolates communicate via message passing and can only transfer
  /// **sendable** values. Schemas that capture Dart closures (`.transform()`,
  /// `.refine()`, `.preprocess()`, etc.) are **not sendable** and will throw
  /// a runtime `IsolateSpawnException` when passed to a new isolate.
  ///
  /// Use [parseInIsolate] for schemas composed exclusively of built-in
  /// primitive and complex schemas (`z.string()`, `z.object()`, etc.) with
  /// no user-supplied callbacks. For schemas with callbacks, run validation
  /// manually via `Isolate.run(() => schema.safeParse(value))` inside a
  /// closure that captures the schema in the spawning isolate.
  ///
  /// For async refinements, use [safeParseAsync] directly — async refinements
  /// perform I/O and do not benefit from isolate offloading.
  ///
  /// See also:
  /// - [safeParse] — the synchronous equivalent.
  /// - [safeParseAsync] — for schemas with async refinements.
  Future<ZemaResult<Output>> parseInIsolate(Input value) =>
      Isolate.run(() => safeParse(value));

  // ===========================================================================
  // TRANSFORMATION METHODS
  // ===========================================================================

  /// Attaches a transformation that maps the validated [Output] to a new type [T].
  ///
  /// The transform function runs **after** validation succeeds. If validation
  /// fails, [fn] is never called.
  ///
  /// The resulting schema has type `ZemaSchema<Input, T>`, meaning its [Output]
  /// type changes to [T] while [Input] stays the same.
  ///
  /// ```dart
  /// // Parse a string, then convert it to uppercase
  /// final schema = z.string().transform((s) => s.toUpperCase());
  /// schema.parse('hello'); // 'HELLO'
  ///
  /// // Parse a date string, then convert it to a DateTime
  /// final dateSchema = z.string()
  ///     .transform(DateTime.parse);
  /// dateSchema.parse('2024-01-15'); // DateTime(2024, 1, 15)
  /// ```
  ///
  /// If [fn] throws, [safeParse] returns a failure with code `transform_error`.
  ///
  /// See also:
  /// - [pipe] — for connecting two full schemas where one's output feeds into
  ///   another's input.
  /// - [preprocess] — for transforming the *input* before validation, not after.
  ZemaSchema<Input, T> transform<T>(T Function(Output) fn) =>
      TransformedSchema(this, fn);

  /// Pipes the validated output of this schema into [next] as its input.
  ///
  /// Creates a two-stage pipeline:
  /// 1. `this` validates [Input] → [Output].
  /// 2. [next] validates [Output] → [T].
  ///
  /// Both stages must succeed for the overall parse to succeed. This is
  /// useful for multi-step coercions or for applying a second layer of
  /// validation on the already-validated output.
  ///
  /// ```dart
  /// // Parse a string, validate it is a valid integer string, then
  /// // pass it to an int schema that checks range.
  /// final schema = z.string()
  ///     .transform(int.parse)
  ///     .pipe(z.int().gte(0).lte(100));
  ///
  /// schema.parse('42');   // 42
  /// schema.parse('150');  // fails: value > 100
  /// schema.parse('abc');  // fails: int.parse throws → transform_error
  /// ```
  ///
  /// See also:
  /// - [transform] — for a simple one-step output transformation.
  /// - [preprocess] — for transforming the raw *input* before this schema runs.
  ZemaSchema<Input, T> pipe<T>(ZemaSchema<Output, T> next) =>
      PipedSchema(this, next);

  /// Applies [fn] to transform the raw input before this schema validates it.
  ///
  /// [preprocess] runs **before** validation. The original [Input] type of
  /// this schema becomes [I] — the type your preprocessing function accepts.
  /// The [Output] type is unchanged.
  ///
  /// Use this to normalize messy data before it hits your schema rules:
  /// trimming strings, coercing types, converting formats, etc.
  ///
  /// ```dart
  /// // Trim whitespace before the min-length check
  /// final schema = z.string()
  ///     .min(3)
  ///     .preprocess<dynamic>((v) => v?.toString().trim() ?? '');
  ///
  /// schema.parse('  hi  '); // fails: 'hi' has length 2 < 3
  /// schema.parse('  hey '); // succeeds: 'hey'
  ///
  /// // Coerce a number from a JSON field that may arrive as a string
  /// final ageSchema = z.integer()
  ///     .gte(0)
  ///     .preprocess<dynamic>((v) => v is String ? int.tryParse(v) ?? v : v);
  /// ```
  ///
  /// See also:
  /// - [transform] — for transforming the *output* after validation.
  /// - [pipe] — for chaining two complete schemas together.
  ZemaSchema<I, Output> preprocess<I>(Input Function(I) fn) =>
      PreprocessedSchema<I, Input, Output>(fn, this);

  // ===========================================================================
  // MODIFIER METHODS
  // ===========================================================================

  /// Wraps this schema so that `null` input is accepted and passes through
  /// as a `null` output without triggering validation.
  ///
  /// The returned schema has type `ZemaSchema<Input?, Output?>`.
  /// Non-null values are still validated by this schema as normal.
  ///
  /// Use [optional] for fields that may simply be absent (e.g. omitted JSON
  /// keys). Combine with [withDefault] to substitute a value for `null`.
  ///
  /// ```dart
  /// final schema = z.string().min(2).optional();
  ///
  /// schema.parse(null);    // null  — OK
  /// schema.parse('Alice'); // 'Alice' — OK
  /// schema.parse('X');     // fails: too short
  ///
  /// // Inside an object, missing keys arrive as null
  /// final userSchema = z.object({
  ///   'name':     z.string(),
  ///   'nickname': z.string().optional(), // may be absent
  /// });
  /// ```
  ///
  /// See also:
  /// - [nullable] — explicit null is a valid *non-absent* value.
  /// - [withDefault] — provide a fallback so the output is never null.
  ZemaSchema<Input?, Output?> optional() => OptionalSchema(this);

  /// Wraps this schema so that an explicit `null` input produces a `null`
  /// output without triggering validation.
  ///
  /// The returned schema has type `ZemaSchema<Input?, Output?>`.
  ///
  /// Use [nullable] when `null` is a semantically meaningful value in your
  /// domain (e.g. a field that can be deliberately set to null in an API).
  /// It differs from [optional] in intent: [optional] means "absent", while
  /// [nullable] means "present but null".
  ///
  /// ```dart
  /// final schema = z.string().nullable();
  ///
  /// schema.parse(null);    // null  — OK
  /// schema.parse('Alice'); // 'Alice' — OK
  /// schema.parse(42);      // fails: not a string
  /// ```
  ///
  /// See also:
  /// - [optional] — for absent/missing values.
  /// - [withDefault] — provide a fallback so the output is never null.
  ZemaSchema<Input?, Output?> nullable() => NullableSchema(this);

  /// Wraps this schema so that `null` input (or a validation failure) yields
  /// [defaultValue] instead of a failure.
  ///
  /// The returned schema has type `ZemaSchema<Input?, Output>` — the output
  /// is never `null` because [defaultValue] fills in the gap.
  ///
  /// ```dart
  /// final schema = z.string().withDefault('anonymous');
  ///
  /// schema.parse(null);    // 'anonymous'
  /// schema.parse('Alice'); // 'Alice'
  ///
  /// // Useful for object fields with server-side defaults
  /// final configSchema = z.object({
  ///   'timeout': z.int().withDefault(30),
  ///   'retries': z.int().withDefault(3),
  /// });
  /// ```
  ///
  /// See also:
  /// - [optional] — produces `null` instead of a fallback.
  /// - [catchError] — for computing a fallback dynamically from the issues.
  ZemaSchema<Input?, Output> withDefault(Output defaultValue) =>
      DefaultSchema(this, defaultValue);

  /// Wraps this schema so that validation failures are caught and replaced
  /// with a fallback value computed by [handler].
  ///
  /// Unlike [withDefault], the fallback is derived **from the actual issues**,
  /// giving you full context to decide what to return. The resulting schema
  /// always succeeds — it never propagates failures to the caller.
  ///
  /// ```dart
  /// // Return a sentinel value when validation fails
  /// final schema = z.int().gte(0).catchError((_) => -1);
  ///
  /// schema.parse(42);  // 42
  /// schema.parse(-5);  // -1  (caught)
  /// schema.parse('x'); // -1  (caught)
  ///
  /// // Log issues before returning the fallback
  /// final safe = z.string().email().catchError((issues) {
  ///   logger.warn('Invalid email: ${issues.first.message}');
  ///   return 'fallback@example.com';
  /// });
  /// ```
  ///
  /// See also:
  /// - [withDefault] — for a static fallback that does not depend on issues.
  /// - [optional] / [nullable] — for null-based fallbacks.
  ZemaSchema<Input, Output> catchError(
    Output Function(List<ZemaIssue>) handler,
  ) =>
      CatchSchema(this, handler);
}
