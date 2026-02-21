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

/// Base schema interface with full type propagation
///
/// Type parameters:
/// - [Input]: The input type accepted by this schema
/// - [Output]: The validated and potentially transformed output type
abstract class ZemaSchema<Input, Output> {
  const ZemaSchema();

  /// Parse input with exception on failure
  ///
  /// Throws [ZemaException] containing all validation issues
  Output parse(Input value) {
    final result = safeParse(value);
    if (result.isFailure) {
      throw ZemaException(result.errors);
    }
    return result.value;
  }

  /// Safe parse returning ZemaResult
  ///
  /// Returns:
  /// - Success: ZemaResult with data
  /// - Failure: ZemaResult with issues
  ZemaResult<Output> safeParse(Input value);

  /// Async parse with exception on failure
  Future<Output> parseAsync(Input value) async {
    final result = await safeParseAsync(value);
    if (result.isFailure) {
      throw ZemaException(result.errors);
    }
    return result.value;
  }

  /// Async safe parse - default implementation delegates to sync version
  /// Override for true async validation
  Future<ZemaResult<Output>> safeParseAsync(Input value) async {
    return safeParse(value);
  }

  // ===========================================================================
  // TRANSFORMATION METHODS
  // ===========================================================================

  /// Transform output to another type with full type safety
  ZemaSchema<Input, T> transform<T>(T Function(Output) fn) =>
      TransformedSchema(this, fn);

  /// Pipe into another schema
  ZemaSchema<Input, T> pipe<T>(ZemaSchema<Output, T> next) =>
      PipedSchema(this, next);

  /// Preprocess input before validation
  ZemaSchema<I, Output> preprocess<I>(Input Function(I) fn) =>
      PreprocessedSchema<I, Input, Output>(fn, this);

  // ===========================================================================
  // MODIFIER METHODS
  // ===========================================================================

  /// Optional version of this schema
  ZemaSchema<Input?, Output?> optional() => OptionalSchema(this);

  /// Nullable version with null passthrough
  ZemaSchema<Input?, Output?> nullable() => NullableSchema(this);

  /// Default value on error or null
  ZemaSchema<Input?, Output> withDefault(Output defaultValue) =>
      DefaultSchema(this, defaultValue);

  /// Catch errors and provide fallback
  ZemaSchema<Input, Output> catchError(
          Output Function(List<ZemaIssue>) handler) =>
      CatchSchema(this, handler);
}
