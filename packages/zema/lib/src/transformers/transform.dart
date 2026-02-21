import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

final class TransformedSchema<I, O, T> extends ZemaSchema<I, T> {
  final ZemaSchema<I, O> base;
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
          ZemaIssue(code: 'transform_error', message: 'Transform failed: $e'));
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
          ZemaIssue(code: 'transform_error', message: 'Transform failed: $e'));
    }
  }
}
