import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

/// A schema that treats `null` as a distinct, explicitly-present value and
/// delegates non-null input to the wrapped [base] schema.
///
/// Created by calling [ZemaSchema.nullable] on any schema — do not instantiate
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
/// `I` to `I?`.
///
/// ## optional vs nullable
///
/// Both [OptionalSchema] and [NullableSchema] accept `null`, but their
/// intent differs:
///
/// - **optional** — the field may be absent; `null` means the key was omitted.
/// - **nullable** — the field is present but its value is explicitly `null`.
///
/// ```dart
/// // Optional: omitting the field entirely is valid
/// z.string().optional()
///
/// // Nullable: the field must be present, but null is a valid value
/// z.string().nullable()
/// ```
///
/// See also:
/// - [OptionalSchema] — identical behaviour; use for absent/missing fields.
/// - [DefaultSchema] — substitutes a fallback so the output is never `null`.
/// - [ZemaSchema.nullable] — the fluent API method that constructs this.
final class NullableSchema<I, O> extends ZemaSchema<I?, O?> {
  /// The schema used to validate non-null input.
  final ZemaSchema<I, O> base;

  const NullableSchema(this.base);

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
