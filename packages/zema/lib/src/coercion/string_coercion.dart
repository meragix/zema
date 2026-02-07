import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class CoerceString extends ZemaSchema<dynamic, String> {
  const CoerceString();

  @override
  ZemaResult<String> safeParse(dynamic value) {
    try {
      return success(value.toString());
    } catch (e) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'string'},
          ),
          meta: {'actual': value.runtimeType},
        ),
      );
    }
  }
}
