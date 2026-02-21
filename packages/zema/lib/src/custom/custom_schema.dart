import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

final class CustomSchema<T> extends ZemaSchema<T, T> {
  final bool Function(T) validator;
  final String? message;

  const CustomSchema(this.validator, this.message);

  @override
  ZemaResult<T> safeParse(T value) {
    if (validator(value)) {
      return success(value);
    }

    return singleFailure(
      ZemaIssue(
        code: 'custom_validation_failed',
        message: message ?? 'Custom validation failed',
      ),
    );
  }
}
