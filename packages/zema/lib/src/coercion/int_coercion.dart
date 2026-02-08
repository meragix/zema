import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class CoerceInt extends ZemaSchema<dynamic, int> {
  final int? min;
  final int? max;

  const CoerceInt({this.min, this.max});

  @override
  ZemaResult<int> safeParse(dynamic value) {
    int? parsed;

    if (value is int) {
      parsed = value;
    } else if (value is double) {
      // Allow coercion from double if it's a whole number
      if (value == value.truncateToDouble()) {
        parsed = value.toInt();
      }
    } else if (value is String) {
      parsed = int.tryParse(value.trim());
    }

    if (parsed == null) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_coercion',
          message: ZemaI18n.translate(
            'invalid_coercion',
            params: {'type': 'int'},
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
