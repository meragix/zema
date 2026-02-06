import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaBool extends ZemaSchema<dynamic, bool> {
  const ZemaBool();

  @override
  ZemaResult<bool> safeParse(dynamic value) {
    if (value is! bool) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'bool',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'bool', 'received': value.runtimeType.toString()},
      );
      return singleFailure(issue);
    }
    return success(value);
  }
}
