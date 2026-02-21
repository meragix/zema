import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaDateTime extends ZemaSchema<dynamic, DateTime> {
  final DateTime? min;
  final DateTime? max;

  const ZemaDateTime({this.min, this.max});

  @override
  ZemaResult<DateTime> safeParse(dynamic value) {
    DateTime? date;

    if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    } else if (value is int) {
      // Unix timestamp (milliseconds)
      date = DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (date == null) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_date',
          message: ZemaI18n.translate('invalid_date'),
        ),
      );
    }

    if (min != null && date.isBefore(min!)) {
      return singleFailure(
        ZemaIssue(
          code: 'date_too_early',
          message: ZemaI18n.translate(
            'date_too_early',
            params: {
              'min': min!.toIso8601String(),
              'actual': date.toIso8601String(),
            },
          ),
          receivedValue: date.toIso8601String(),
          meta: {
            'min': min!.toIso8601String(),
            'actual': date.toIso8601String()
          },
        ),
      );
    }

    if (max != null && date.isAfter(max!)) {
      return singleFailure(
        ZemaIssue(
          code: 'date_too_late',
          message: ZemaI18n.translate(
            'date_too_late',
            params: {
              'max': max!.toIso8601String(),
              'actual': date.toIso8601String(),
            },
          ),
          receivedValue: date.toIso8601String(),
          meta: {
            'max': max!.toIso8601String(),
            'actual': date.toIso8601String()
          },
        ),
      );
    }

    return success(date);
  }

  ZemaDateTime after(DateTime date) => ZemaDateTime(min: date, max: max);
  ZemaDateTime before(DateTime date) => ZemaDateTime(min: min, max: date);
  ZemaDateTime between(DateTime start, DateTime end) =>
      ZemaDateTime(min: start, max: end);
}
