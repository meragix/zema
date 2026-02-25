import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that transforms the raw input with [preprocessor] before passing
/// it to [base] for validation.
///
/// Created by calling [ZemaSchema.preprocess] on any schema — do not
/// instantiate directly.
///
/// ## Behaviour
///
/// 1. [preprocessor] is called with the raw input [I] → [M].
/// 2. If [preprocessor] throws, a `preprocess_error` issue is returned
///    immediately — [base] is never called.
/// 3. If [preprocessor] succeeds, its output [M] is passed to [base].
/// 4. [base] validates [M] → [O] and its result is returned.
///
/// ## Type parameters
///
/// - [I] — the raw input type accepted by the overall schema.
/// - [M] — the intermediate type produced by [preprocessor] and consumed
///   by [base].
/// - [O] — the final output type produced by [base] on success.
///
/// ## preprocess vs transform
///
/// | | [PreprocessedSchema] | [TransformedSchema] |
/// |---|---|---|
/// | Runs | **Before** validation | **After** validation |
/// | Purpose | Normalise / coerce input | Map valid output to another type |
/// | On failure | `preprocess_error` | `transform_error` |
///
/// ## Examples
///
/// ```dart
/// // Trim whitespace before the min-length check
/// z.string().min(3)
///     .preprocess<dynamic>((v) => v?.toString().trim() ?? '');
///
/// // Accept int or string for an age field, coerce to int before validating
/// z.int().gte(0).lte(120)
///     .preprocess<dynamic>((v) => v is String ? int.tryParse(v) ?? v : v);
///
/// // Normalise a list by removing duplicates before checking length
/// z.array(z.string()).max(5)
///     .preprocess<dynamic>((v) => v is List ? v.toSet().toList() : v);
/// ```
///
/// See also:
/// - [ZemaSchema.preprocess] — the fluent API method that constructs this.
/// - [TransformedSchema] — transforms the *output* after validation.
/// - [PipedSchema] — chains two full schemas in sequence.
final class PreprocessedSchema<I, M, O> extends ZemaSchema<I, O> {
  /// The function applied to the raw input before [base] validates it.
  final M Function(I) preprocessor;

  /// The schema that validates the preprocessed intermediate value.
  final ZemaSchema<M, O> base;

  const PreprocessedSchema(this.preprocessor, this.base);

  @override
  ZemaResult<O> safeParse(I value) {
    try {
      final preprocessed = preprocessor(value);
      return base.safeParse(preprocessed);
    } catch (e) {
      return singleFailure(
        ZemaIssue(
          code: 'preprocess_error',
          message: 'Preprocessing failed: $e',
        ),
      );
    }
  }
}
