import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/utils/custom_message.dart';

final class ZemaInt extends ZemaSchema<dynamic, int>
    with ZemaCustomMessage<dynamic, int> {
  final int? min;
  final int? max;

  @override
  final String? customMessage;

  const ZemaInt({this.min, this.max, this.customMessage});

  @override
  ZemaResult<int> safeParse(dynamic value) {
    if (value is! int) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'int',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'int', 'received': value.runtimeType.toString()},
      );
      return singleFailure(applyCustomMessage(issue));
    }

    final issues = <ZemaIssue>[];

    if (min != null && value < min!) {
      final issue = ZemaIssue(
        code: 'too_small',
        message: ZemaI18n.translate(
          'too_small',
          params: {
            'min': min,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'min': min, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (max != null && value > max!) {
      final issue = ZemaIssue(
        code: 'too_big',
        message: ZemaI18n.translate('too_big', params: {
          'max': max,
          'actual': value,
        }),
        receivedValue: value,
        meta: {'max': max, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(value);
  }

  ZemaInt gte(int value, {String? message}) =>
      ZemaInt(min: value, max: max, customMessage: message);
  ZemaInt lte(int value, {String? message}) =>
      ZemaInt(min: min, max: value, customMessage: message);
  ZemaInt positive() => ZemaInt(min: 1, max: max);
}

final class ZemaDouble extends ZemaSchema<dynamic, double>
    with ZemaCustomMessage<dynamic, double> {
  final double? min;
  final double? max;

  @override
  final String? customMessage;

  const ZemaDouble({this.min, this.max, this.customMessage});

  @override
  ZemaResult<double> safeParse(dynamic value) {
    if (value is! double) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'double',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'double', 'received': value.runtimeType.toString()},
      );
      return singleFailure(applyCustomMessage(issue));
    }

    final issues = <ZemaIssue>[];

    if (min != null && value < min!) {
      final issue = ZemaIssue(
        code: 'too_small',
        message: ZemaI18n.translate(
          'too_small',
          params: {
            'min': min,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'min': min, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (max != null && value > max!) {
      final issue = ZemaIssue(
        code: 'too_big',
        message: ZemaI18n.translate('too_big', params: {
          'max': max,
          'actual': value,
        }),
        receivedValue: value,
        meta: {'max': max, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(value);
  }

  ZemaDouble gte(double value, {String? message}) =>
      ZemaDouble(min: value, max: max, customMessage: message);
  ZemaDouble lte(double value, {String? message}) =>
      ZemaDouble(min: min, max: value, customMessage: message);
  ZemaDouble positive() => ZemaDouble(min: 0.0000001, max: max);
}
