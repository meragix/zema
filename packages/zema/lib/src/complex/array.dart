import 'package:zema/src/core/result.dart';
import 'package:zema/zema.dart';

final class ZemaArray<T> extends ZemaSchema<dynamic, List<T>> {
  final ZemaSchema<dynamic, T> element;
  const ZemaArray(this.element);

  @override
  ZemaResult<List<T>> safeParse(dynamic value) {
    if (value is! List) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_type',
          message: ZemaI18n.translate(
            'invalid_type',
            params: {
              'expected': 'array',
              'received': value.runtimeType.toString(),
            },
          ),
          receivedValue: value,
          meta: {'expected': 'array', 'received': value.runtimeType.toString()},
        ),
      );
    }

    final parsed = <T>[];
    final issues = <ZemaIssue>[];

    for (var i = 0; i < value.length; i++) {
      final result = element.safeParse(value[i]);
      if (result.isFailure) {
        for (final issue in result.errors) {
          issues.add(issue.withPath(i));
        }
      } else {
        parsed.add(result.value);
      }
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(parsed);
  }
}
