import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

/// A schema that passes `null` through as a `null` output, and delegates
/// non-null values to the wrapped [base] schema.
///
/// Created by calling [ZemaSchema.optional] on any schema — do not instantiate
/// directly.
///
/// ## Behaviour
///
/// | Input | Output |
/// |---|---|
/// | `null` | `success(null)` — no validation runs |
/// | non-null | result of `base.safeParse(value)` |
///
/// The output type widens from `O` to `O?`, and the input type widens from
/// `I` to `I?`, reflecting that `null` is now a valid input.
///
/// ## Typical use
///
/// Use [OptionalSchema] for fields that may be **absent** — for example, a
/// JSON key that is not always present. In a [ZemaObject] schema, missing
/// keys arrive as `null`, so making a field optional means it can be omitted
/// entirely:
///
/// ```dart
/// final schema = z.object({
///   'name':     z.string(),
///   'nickname': z.string().min(2).optional(), // may be absent
/// });
///
/// schema.parse({'name': 'Alice'});             // nickname → null, OK
/// schema.parse({'name': 'Alice', 'nickname': 'X'}); // fails: too short
/// ```
///
/// ## Async support
///
/// Both [safeParse] and [safeParseAsync] short-circuit on `null`, so the
/// async delegate is only called for non-null values.
///
/// See also:
/// - [NullableSchema] — same short-circuit but intended for fields whose
///   null has semantic meaning rather than being simply absent.
/// - [DefaultSchema] — like [OptionalSchema] but substitutes a fallback
///   value so the output is never `null`.
/// - [ZemaSchema.optional] — the fluent API method that constructs this.
final class OptionalSchema<I, O> extends ZemaSchema<I?, O?> {
  /// The schema used to validate non-null input.
  final ZemaSchema<I, O> base;

  const OptionalSchema(this.base);

  @override
  ZemaResult<O?> safeParse(I? value) {
    if (value == null) return success(null);
    return base.safeParse(value);
  }

  @override
  Future<ZemaResult<O?>> safeParseAsync(I? value) async {
    if (value == null) return success(null);
    return base.safeParseAsync(value);
  }
}
