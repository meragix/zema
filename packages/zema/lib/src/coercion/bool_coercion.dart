import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class CoerceBool extends ZemaSchema<dynamic, bool> {
  const CoerceBool();

  @override
  ZemaResult<bool> safeParse(dynamic value) {
    if (value is bool) return success(value);

    if (value is int) {
      if (value == 1) return success(true);
      if (value == 0) return success(false);
    }

    if (value is String) {
      final lower = value.trim().toLowerCase();
      if (lower == 'true' || lower == '1' || lower == 'yes' || lower == 'on') {
        return success(true);
      }
      if (lower == 'false' || lower == '0' || lower == 'no' || lower == 'off') {
        return success(false);
      }
    }

    return singleFailure(
      ZemaIssue(
        code: 'invalid_coercion',
        message: ZemaI18n.translate(
          'invalid_coercion',
          params: {'type': 'bool'},
        ),
        meta: {'actual': value.runtimeType},
      ),
    );
  }
}
