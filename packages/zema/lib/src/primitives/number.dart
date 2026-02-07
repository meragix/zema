import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/utils/custom_message.dart';

final class ZemaInt extends ZemaSchema<dynamic, int>
    with ZemaCustomMessage<dynamic, int> {
  final int? min;
  final int? max;
  final bool? isPositive;
  final bool? isNegative;
  final int? multipleOf;

  @override
  final String? customMessage;

  const ZemaInt({
    this.min,
    this.max,
    this.isPositive,
    this.isNegative,
    this.multipleOf,
    this.customMessage,
  });

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
        message: ZemaI18n.translate(
          'too_big',
          params: {
            'max': max,
            'actual': value,
          },
        ),
        receivedValue: value,
        meta: {'max': max, 'actual': value},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isPositive == true && value <= 0) {
      final issue = ZemaIssue(
        code: 'not_positive',
        message: ZemaI18n.translate('not_positive'),
        receivedValue: value,
        meta: {
          'expected': 'positive integer',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isNegative == true && value >= 0) {
      final issue = ZemaIssue(
        code: 'not_negative',
        message: ZemaI18n.translate('not_negative'),
        receivedValue: value,
        meta: {
          'expected': 'negative integer',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(value);
  }

  ZemaInt gte(int value, {String? message}) => ZemaInt(
        min: value,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  ZemaInt lte(int value, {String? message}) => ZemaInt(
        min: min,
        max: value,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  ZemaInt positive({String? message}) => ZemaInt(
        min: min,
        max: max,
        isPositive: true,
        isNegative: isNegative,
        multipleOf: multipleOf,
        customMessage: message,
      );

  ZemaInt negative({String? message}) => ZemaInt(
        min: min,
        max: max,
        isPositive: isPositive,
        isNegative: true,
        multipleOf: multipleOf,
        customMessage: message,
      );

  ZemaInt step(int value, {String? message}) => ZemaInt(
        min: min,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        multipleOf: value,
        customMessage: message,
      );
}

final class ZemaDouble extends ZemaSchema<dynamic, double>
    with ZemaCustomMessage<dynamic, double> {
  final double? min;
  final double? max;
  final bool? isPositive;
  final bool? isNegative;
  final bool? isFinite;

  @override
  final String? customMessage;

  const ZemaDouble({
    this.min,
    this.max,
    this.isPositive,
    this.isNegative,
    this.isFinite,
    this.customMessage,
  });

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

    if (isFinite == true && !value.isFinite) {
      issues.add(
        ZemaIssue(
          code: 'not_finite',
          message: ZemaI18n.translate('not_finite'),
          receivedValue: value,
          meta: {'received': value},
        ),
      );
    }

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

    if (isPositive == true && value <= 0) {
      final issue = ZemaIssue(
        code: 'not_positive',
        message: ZemaI18n.translate('not_positive'),
        receivedValue: value,
        meta: {
          'expected': 'positive double',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (isNegative == true && value >= 0) {
      final issue = ZemaIssue(
        code: 'not_negative',
        message: ZemaI18n.translate('not_negative'),
        receivedValue: value,
        meta: {
          'expected': 'negative double',
          'received': value,
        },
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(value);
  }

  ZemaDouble gte(double value, {String? message}) => ZemaDouble(
        min: value,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );

  ZemaDouble lte(double value, {String? message}) => ZemaDouble(
        min: min,
        max: value,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: isFinite,
        customMessage: message,
      );

  ZemaDouble positive() => ZemaDouble(
        min: min,
        max: max,
        isPositive: true,
        isNegative: isNegative,
        isFinite: isFinite,
      );

  ZemaDouble finite() => ZemaDouble(
        min: min,
        max: max,
        isPositive: isPositive,
        isNegative: isNegative,
        isFinite: true,
      );
}
