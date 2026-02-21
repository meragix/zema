import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaArray<T> extends ZemaSchema<dynamic, List<T>> {
  final ZemaSchema<dynamic, T> element;
  final int? minLength;
  final int? maxLength;

  const ZemaArray(this.element, {this.minLength, this.maxLength});

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

    if (minLength != null && value.length < minLength!) {
      return singleFailure(
        ZemaIssue(
          code: 'too_small',
          message: ZemaI18n.translate(
            'too_small',
            params: {
              'min': minLength,
              'actual': value.length,
            },
          ),
          receivedValue: value.length,
          meta: {'min': minLength, 'actual': value.length},
        ),
      );
    }

    if (maxLength != null && value.length > maxLength!) {
      return singleFailure(
        ZemaIssue(
          code: 'too_big',
          message: ZemaI18n.translate(
            'too_big',
            params: {
              'max': maxLength,
              'actual': value.length,
            },
          ),
          receivedValue: value.length,
          meta: {'max': maxLength, 'actual': value.length},
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

  ZemaArray<T> min(int length) =>
      ZemaArray(element, minLength: length, maxLength: maxLength);
  ZemaArray<T> max(int length) =>
      ZemaArray(element, minLength: minLength, maxLength: length);
  ZemaArray<T> length(int exact) =>
      ZemaArray(element, minLength: exact, maxLength: exact);
  ZemaArray<T> nonempty() =>
      ZemaArray(element, minLength: 1, maxLength: maxLength);
}
