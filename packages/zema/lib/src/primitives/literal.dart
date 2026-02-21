import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaLiteral<T> extends ZemaSchema<dynamic, T> {
  final T value;

  const ZemaLiteral(this.value);

  @override
  ZemaResult<T> safeParse(dynamic input) {
    if (input == value) {
      return success(value);
    }

    return singleFailure(
      ZemaIssue(
        code: 'invalid_literal',
        message: ZemaI18n.translate('invalid_literal'),
      ),
    );
  }
}
