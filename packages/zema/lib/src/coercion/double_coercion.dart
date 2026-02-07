import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class CoerceDouble extends ZemaSchema<dynamic, double> {
  final double? min;
  final double? max;

  const CoerceDouble({this.min, this.max});

  @override
  ZemaResult<double> safeParse(dynamic value) {
    double? parsed;

    if (value is double) {
      parsed = value;
    } else if (value is int) {
      parsed = value.toDouble();
    } else if (value is String) {
      parsed = double.tryParse(value.trim());
    }

    if (parsed == null) {
      return singleFailure(
         ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'double'},
          ),
          meta: {'actual': value.runtimeType},
        ),
      );
    }

    final issues = <ZemaIssue>[];

    if (min != null && parsed < min!) {
      issues.add(
        ZemaIssue(
          code: 'too_small',
          message: ZemaI18n.translate(
            'too_small',
            params: {
              'min': min,
              'actual': parsed,
            },
          ),
          meta: {'min': min, 'actual': parsed},
        ),
      );
    }

    if (max != null && parsed > max!) {
      issues.add(
         ZemaIssue(
          code: 'too_big',
          message: ZemaI18n.translate(
            'too_big',
            params: {
              'max': max,
              'actual': parsed,
            },
          ),
          meta: {'max': max, 'actual': parsed},
        ),
      );
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(parsed);
  }
}
