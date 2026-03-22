/// Type-safe schema validation for Dart — inspired by Zod.
///
/// Zema provides a fluent, declarative API for defining, validating, and
/// transforming data at runtime. Every schema is **immutable** and
/// **composable**: you build complex validation rules by chaining simple ones.
///
/// ## Quick start
///
/// ```dart
/// import 'package:zema/zema.dart';
///
/// // 1. Define a schema
/// final userSchema = z.object({
///   'name':  z.string().min(2),
///   'email': z.string().email(),
///   'age':   z.int().gte(0).optional(),
/// });
///
/// // 2. Parse — throws ZemaException on failure
/// final user = userSchema.parse({
///   'name':  'Alice',
///   'email': 'alice@example.com',
/// });
///
/// // 3. Safe parse — returns ZemaResult, never throws
/// final result = userSchema.safeParse(untrustedInput);
///
/// switch (result) {
///   case ZemaSuccess(:final value):
///     saveUser(value);
///   case ZemaFailure(:final errors):
///     for (final issue in errors) {
///       print('${issue.pathString}: ${issue.message}');
///     }
/// }
/// ```
///
/// ## Entry point
///
/// All schema construction flows through the global [z] constant (alias: [zema]):
///
/// ```dart
/// z.string()    z.int()     z.double()  z.boolean()
/// z.object({})  z.array(…)  z.union([…])
/// z.literal(…)  z.custom(…) z.lazy(…)
/// z.coerce().integer()   // coercion sub-namespace
/// ```
///
/// ## Result handling
///
/// [ZemaSchema.safeParse] returns a sealed [ZemaResult]:
/// - [ZemaSuccess] — holds the validated value.
/// - [ZemaFailure] — holds a list of [ZemaIssue]s with codes, messages,
///   and field paths.
///
/// Use `result.when(success: …, failure: …)` for exhaustive handling, or
/// `result.errors.format()` to get a nested `Map` of field → messages
/// suitable for form UIs.
///
/// ## Error customisation
///
/// Override messages globally or per-schema:
///
/// ```dart
/// // Global error map (affects all schemas)
/// ZemaErrorMap.setErrorMap((issue, ctx) {
///   if (issue.code == 'invalid_email') return 'Please enter a valid email.';
///   return null; // fall back to the default message
/// });
///
/// // Locale-aware messages (built-in: 'en', 'fr')
/// ZemaErrorMap.setLocale('fr');
/// ZemaI18n.registerTranslations('es', mySpanishTranslations);
/// ```
// ignore_for_file: directives_ordering
library;

// ---------------------------------------------------------------------------
// Core types
// ---------------------------------------------------------------------------

export 'src/core/schema.dart' show ZemaSchema;
export 'src/core/result.dart' show ZemaResult, ZemaSuccess, ZemaFailure;

// ---------------------------------------------------------------------------
// Error system
// ---------------------------------------------------------------------------

export 'src/error/error.dart'
    show
        ZemaErrorMap,
        ZemaErrorMapFunc,
        ZemaErrorContext,
        ZemaIssueListExtensions,
        ZemaFormattedErrors,
        ZemaI18n,
        ZemaTranslations,
        ZemaException,
        ZemaIssue,
        ZemaMetaKeys,
        ZemaSeverity;

// ---------------------------------------------------------------------------
// Primitive schemas
// ---------------------------------------------------------------------------

export 'src/primitives/primitives.dart'
    show ZemaString, ZemaInt, ZemaDouble, ZemaBool, ZemaDateTime, ZemaLiteral;

// ---------------------------------------------------------------------------
// Complex schemas
// ---------------------------------------------------------------------------

export 'src/complex/complex.dart'
    show ZemaObject, ZemaArray, ZemaUnion, ZemaMap;

// ---------------------------------------------------------------------------
// Coercion
// ---------------------------------------------------------------------------

export 'src/coercion/coerce.dart' show ZemaCoerce;

// ---------------------------------------------------------------------------
// Modifiers
// ---------------------------------------------------------------------------

export 'src/modifiers/modifiers.dart' show Branded;
export 'src/modifiers/refined.dart' show ZemaSchemaRefinement, ValidationContext;

// ---------------------------------------------------------------------------
// Extensions
// ---------------------------------------------------------------------------

export 'src/extensions/custom_message.dart' show ZemaCustomMessage;

// ---------------------------------------------------------------------------
// Global factory (z / zema)
// ---------------------------------------------------------------------------

export 'src/factory.dart' show z, zema;
