import 'package:zema/src/core/result.dart';

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
    return result.dataOrThrow;
  }

  /// Safe parse returning ZemaResult
  ///
  /// Returns:
  /// - Success: ZemaResult with data
  /// - Failure: ZemaResult with issues
  ZemaResult<Output> safeParse(Input value);
}
