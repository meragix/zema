/// Zema - Ultra-typed schema validation for Dart 3.5+
///
/// Inspired by Zod with superior type inference and zero-cost abstractions.
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

// Factory
export 'src/factory.dart' show z;
