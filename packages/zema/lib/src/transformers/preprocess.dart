import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

final class PreprocessedSchema<I, M, O> extends ZemaSchema<I, O> {
  final M Function(I) preprocessor;
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
