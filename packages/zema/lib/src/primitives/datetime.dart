import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that validates and parses date/time values into [DateTime].
///
/// Construct via `z.dateTime()` — do not instantiate directly.
///
/// Unlike the other primitive schemas, [ZemaDateTime] is also a **coercion**
/// schema: it accepts multiple input representations and converts them to
/// [DateTime] automatically.
///
/// ## Accepted inputs
///
/// | Input type | Parsing rule |
/// |---|---|
/// | `DateTime` | passed through unchanged |
/// | `String` | parsed with [DateTime.tryParse] (ISO 8601) |
/// | `int` | treated as milliseconds since the Unix epoch |
/// | anything else | `invalid_date` failure |
///
/// ```dart
/// final schema = z.dateTime();
///
/// schema.parse(DateTime(2024, 1, 15));     // DateTime — passthrough
/// schema.parse('2024-01-15T10:30:00Z');    // ISO 8601 string
/// schema.parse(1705312200000);             // Unix ms timestamp
///
/// schema.parse('not-a-date');              // fails — invalid_date
/// schema.parse(true);                      // fails — invalid_date
/// ```
///
/// ## Range constraints
///
/// Use [after], [before], or [between] to restrict the accepted range.
/// Bounds are **inclusive** — a value equal to a bound passes.
///
/// ```dart
/// final epoch = DateTime(1970);
/// final now   = DateTime.now();
///
/// z.dateTime().after(epoch)           // must be after the Unix epoch
/// z.dateTime().before(now)            // must be in the past
/// z.dateTime().between(start, end)    // must fall within [start, end]
/// ```
///
/// Violations produce `date_too_early` or `date_too_late` issues whose
/// `meta` map contains ISO 8601 strings for the bound and the received value.
///
/// See also:
/// - [ZemaSchema.optional] — to also accept `null` input.
final class ZemaDateTime extends ZemaSchema<dynamic, DateTime> {
  /// Earliest allowed date (inclusive). `null` means no lower bound.
  final DateTime? min;

  /// Latest allowed date (inclusive). `null` means no upper bound.
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
            'actual': date.toIso8601String(),
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
            'actual': date.toIso8601String(),
          },
        ),
      );
    }

    return success(date);
  }

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Requires the date to be **after** (or equal to) [date].
  ///
  /// Produces a `date_too_early` issue if the parsed date is strictly before
  /// [date].
  ///
  /// ```dart
  /// final minAge = DateTime.now().subtract(Duration(days: 365 * 18));
  /// z.dateTime().after(minAge)  // user must be at least 18
  /// ```
  ZemaDateTime after(DateTime date) => ZemaDateTime(min: date, max: max);

  /// Requires the date to be **before** (or equal to) [date].
  ///
  /// Produces a `date_too_late` issue if the parsed date is strictly after
  /// [date].
  ///
  /// ```dart
  /// z.dateTime().before(DateTime.now())   // must be in the past
  /// ```
  ZemaDateTime before(DateTime date) => ZemaDateTime(min: min, max: date);

  /// Requires the date to fall within the inclusive range `[start, end]`.
  ///
  /// Equivalent to `.after(start).before(end)` but expressed as a single
  /// call. Produces `date_too_early` or `date_too_late` as appropriate.
  ///
  /// ```dart
  /// z.dateTime().between(
  ///   DateTime(2024, 1, 1),
  ///   DateTime(2024, 12, 31),
  /// );
  /// ```
  ZemaDateTime between(DateTime start, DateTime end) =>
      ZemaDateTime(min: start, max: end);
}
