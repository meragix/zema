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
export 'src/error/error_map.dart'
    show ZemaErrorMap, ZemaErrorMapFunc, ZemaErrorContext;
export 'src/error/formatter.dart'
    show ZemaIssueListExtensions, ZemaFormattedErrors;
export 'src/error/i18n.dart' show ZemaI18n, ZemaTranslations;
export 'src/error/exception.dart' show ZemaException;
export 'src/error/issue.dart' show ZemaIssue;

// Primitive schemas
export 'src/primitives/string.dart' show ZemaString;
export 'src/primitives/number.dart' show ZemaInt, ZemaDouble;
export 'src/primitives/bool.dart' show ZemaBool;
// export 'src/primitives/literal.dart' show ZemaLiteral;

// Complex schemas
export 'src/complex/object.dart' show ZemaObject;
export 'src/complex/array.dart' show ZemaArray;

// Coercion
export 'src/coercion/coerce.dart' show ZemaCoerce;

// Modifiers (selective export of public types only)
// export 'src/modifiers/branded.dart' show Branded;

// Extensions
export 'src/extensions/custom_message.dart' show ZemaCustomMessage;

// Global z factory
export 'src/factory.dart' show z, zema;
