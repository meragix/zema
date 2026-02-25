import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that validates `List` values and produces a typed `List<T>`.
///
/// Construct via `z.array(elementSchema)` — do not instantiate directly.
///
/// ## Validation order
///
/// 1. **Type check** — input must be a `List` (`invalid_type` on failure).
/// 2. **Length constraints** — [minLength] and [maxLength] are checked next
///    (`too_small` / `too_big`). If either fails, element validation is
///    skipped entirely.
/// 3. **Element validation** — every element is validated by the [element]
///    schema. Validation is **exhaustive**: all element failures are collected
///    before returning.
///
/// Element-level issues have the element's integer index prepended to their
/// [ZemaIssue.path], making it easy to identify exactly which item failed:
///
/// ```
/// ZemaIssue(code: 'too_short', path: [2, 'name'], ...)
/// // → the 'name' field of the element at index 2
/// ```
///
/// ## Examples
///
/// ```dart
/// z.array(z.string())              // List of any strings
/// z.array(z.int().positive())      // List of positive integers
/// z.array(z.string()).min(1)       // non-empty list
/// z.array(z.string()).max(10)      // at most 10 elements
/// z.array(z.string()).length(3)    // exactly 3 elements
/// z.array(z.string()).nonempty()   // shorthand for .min(1)
///
/// z.array(z.object({
///   'id':   z.int(),
///   'name': z.string().min(2),
/// }));
/// ```
///
/// See also:
/// - [ZemaObject] — for maps with a fixed, named set of fields.
/// - `z.array` — factory method in [Zema].
final class ZemaArray<T> extends ZemaSchema<dynamic, List<T>> {
  /// The schema applied to every element of the list.
  final ZemaSchema<dynamic, T> element;

  /// Minimum list length (inclusive). `null` means no lower bound.
  final int? minLength;

  /// Maximum list length (inclusive). `null` means no upper bound.
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

  // ===========================================================================
  // Fluent API
  // ===========================================================================

  /// Requires the list to have at least [length] elements.
  ///
  /// Produces a `too_small` issue on failure. Element validation is skipped
  /// when this check fails.
  ///
  /// ```dart
  /// z.array(z.string()).min(1)   // at least one element
  /// ```
  ZemaArray<T> min(int length) =>
      ZemaArray(element, minLength: length, maxLength: maxLength);

  /// Requires the list to have at most [length] elements.
  ///
  /// Produces a `too_big` issue on failure. Element validation is skipped
  /// when this check fails.
  ///
  /// ```dart
  /// z.array(z.string()).max(100)
  /// ```
  ZemaArray<T> max(int length) =>
      ZemaArray(element, minLength: minLength, maxLength: length);

  /// Requires the list to have **exactly** [exact] elements.
  ///
  /// Sets both [minLength] and [maxLength] to [exact].
  ///
  /// ```dart
  /// z.array(z.int()).length(3)  // exactly 3 integers (e.g. RGB tuple)
  /// ```
  ZemaArray<T> length(int exact) =>
      ZemaArray(element, minLength: exact, maxLength: exact);

  /// Requires the list to have at least one element.
  ///
  /// Shorthand for `.min(1)`. Produces a `too_small` issue on an empty list.
  ///
  /// ```dart
  /// z.array(z.string()).nonempty()
  /// ```
  ZemaArray<T> nonempty() =>
      ZemaArray(element, minLength: 1, maxLength: maxLength);
}
