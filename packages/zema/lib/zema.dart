/// Ultra-typed, zero-cost schema validation library for Dart 3.5+
///
/// Zema provides a fluent API for defining, validating, and transforming
/// data with full type safety and minimal runtime overhead.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:zema/zema.dart';
///
/// // Define a schema
/// final userSchema = Z.object({
///   'name': Z.string.min(2),
///   'age': Z.int.gte(0),
///   'email': Z.string.email(),
/// });
///
/// // Validate data
/// final result = userSchema.safeParse({
///   'name': 'Alice',
///   'age': 30,
///   'email': 'alice@example.com',
/// });
///
/// // Pattern match the result
/// switch (result) {
///   case (final user?, null):
///     print('Valid: $user');
///   case (null, final error?):
///     print('Invalid: $error');
/// }
///```
// ignore_for_file: directives_ordering
library;

// Core types
export 'src/core/schema.dart' show ZemaSchema;
export 'src/core/result.dart' show ZemaResult;

// Error system
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
        ZemaIssue;

// Primitive schemas
export 'src/primitives/primitives.dart' show ZemaString, ZemaInt, ZemaDouble, ZemaBool, ZemaDateTime, ZemaLiteral;

// Complex schemas
export 'src/complex/complex.dart' show ZemaObject, ZemaArray, ZemaUnion, ZemaMap;

// Coercion
export 'src/coercion/coerce.dart' show ZemaCoerce;

// Modifiers (selective export of public types only)
export 'src/modifiers/modifiers.dart' show Branded;

// Extensions
export 'src/extensions/custom_message.dart' show ZemaCustomMessage;

// Global z factory
export 'src/factory.dart' show z, zema;
