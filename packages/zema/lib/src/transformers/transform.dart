import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that validates with [base] and then maps the output through
/// [transformer], changing the output type from [O] to [T].
///
/// Created by calling [ZemaSchema.transform] on any schema — do not
/// instantiate directly.
///
/// ## Behaviour
///
/// 1. [base] validates the input [I] → [O].
/// 2. If [base] fails, its errors are forwarded unchanged — [transformer]
///    is never called.
/// 3. If [base] succeeds, [transformer] is called with the validated [O].
/// 4. If [transformer] throws, a `transform_error` issue is produced with
///    the exception message.
///
/// Both the synchronous and asynchronous parse paths apply the same
/// [transformer] function after awaiting the base result.
///
/// ## Type parameters
///
/// - [I] — raw input type (same as [base]'s input).
/// - [O] — intermediate type produced by [base] on success.
/// - [T] — final output type produced by [transformer].
///
/// ## Examples
///
/// ```dart
/// // String → uppercase String
/// z.string().transform((s) => s.toUpperCase())
///
/// // String → DateTime
/// z.string().transform(DateTime.parse)
///
/// // Map → typed model
/// z.object({'name': z.string()})
///     .transform((map) => User.fromJson(map))
/// ```
///
/// See also:
/// - [ZemaSchema.transform] — the fluent API method that constructs this.
/// - [PipedSchema] — chains two full schemas where the output of one is
///   the input of the next.
/// - [PreprocessedSchema] — transforms the *input* before validation rather
///   than the output after it.
final class TransformedSchema<I, O, T> extends ZemaSchema<I, T> {
  /// The schema that validates the raw input.
  final ZemaSchema<I, O> base;

  /// The function applied to the validated output to produce the final value.
  final T Function(O) transformer;

  const TransformedSchema(this.base, this.transformer);

  @override
  ZemaResult<T> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return failure(result.errors);

    try {
      return success(transformer(result.value));
    } catch (e) {
      return singleFailure(
        ZemaIssue(code: 'transform_error', message: 'Transform failed: $e'),
      );
    }
  }

  @override
  Future<ZemaResult<T>> safeParseAsync(I value) async {
    final result = await base.safeParseAsync(value);
    if (result.isFailure) return failure(result.errors);

    try {
      return success(transformer(result.value));
    } catch (e) {
      return singleFailure(
        ZemaIssue(code: 'transform_error', message: 'Transform failed: $e'),
      );
    }
  }
}
