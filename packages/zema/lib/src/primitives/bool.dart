import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that validates Dart `bool` values.
///
/// Construct via `z.boolean()` — do not instantiate directly.
///
/// This is a **strict** type check: only actual `bool` values (`true` or
/// `false`) are accepted. Integers (`1`, `0`), strings (`'true'`, `'yes'`),
/// and other truthy/falsy representations are all rejected with an
/// `invalid_type` issue.
///
/// ```dart
/// z.boolean().parse(true);   // true
/// z.boolean().parse(false);  // false
///
/// z.boolean().parse(1);       // fails — invalid_type
/// z.boolean().parse('true');  // fails — invalid_type
/// z.boolean().parse(null);    // fails — invalid_type
/// ```
///
/// To accept truthy/falsy strings and integers, use the coercion variant:
///
/// ```dart
/// z.coerce().boolean().parse('yes');  // true
/// z.coerce().boolean().parse(0);      // false
/// ```
///
/// See also:
/// - `z.coerce().boolean()` — accepts strings and integers in addition to bools.
/// - [ZemaSchema.optional] — wraps this schema to also accept `null`.
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
