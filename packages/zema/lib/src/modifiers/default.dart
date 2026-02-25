import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

/// A schema that substitutes [defaultValue] whenever the input is `null`
/// **or** the [base] schema fails, ensuring the output is never `null`.
///
/// Created by calling [ZemaSchema.withDefault] on any schema — do not
/// instantiate directly.
///
/// ## Behaviour
///
/// | Input | Base result | Output |
/// |---|---|---|
/// | `null` | — (skipped) | `success(defaultValue)` |
/// | non-null | success | `success(base output)` |
/// | non-null | failure | `success(defaultValue)` |
///
/// The output type is `O` (not `O?`) because [defaultValue] guarantees a
/// non-null result in all cases. The input type widens to `I?` to accept
/// `null` as a trigger for the default.
///
/// ## Examples
///
/// ```dart
/// final schema = z.string().withDefault('anonymous');
///
/// schema.parse(null);      // 'anonymous'
/// schema.parse('Alice');   // 'Alice'
///
/// // Useful for config fields with well-known defaults
/// final configSchema = z.object({
///   'timeout': z.int().withDefault(30),
///   'retries': z.int().withDefault(3),
///   'debug':   z.boolean().withDefault(false),
/// });
///
/// configSchema.parse({});  // {timeout: 30, retries: 3, debug: false}
/// ```
///
/// ## Default on failure
///
/// Because [defaultValue] is also used when the [base] schema fails, this
/// schema **silently swallows validation errors** for non-null input. If you
/// need to log or inspect the issues before falling back, use
/// [ZemaSchema.catchError] instead — it receives the issue list before
/// returning the fallback.
///
/// ```dart
/// // withDefault: errors discarded silently
/// z.int().withDefault(-1).parse('oops');   // -1, no diagnostics
///
/// // catchError: errors visible before fallback
/// z.int().catchError((issues) {
///   logger.warn(issues);
///   return -1;
/// }).parse('oops');                         // -1, with logging
/// ```
///
/// See also:
/// - [ZemaSchema.withDefault] — the fluent API method that constructs this.
/// - [ZemaSchema.catchError] — for dynamic fallbacks with access to issues.
/// - [OptionalSchema] — produces `null` instead of a static fallback.
final class DefaultSchema<I, O> extends ZemaSchema<I?, O> {
  /// The schema used to validate non-null input.
  final ZemaSchema<I, O> base;

  /// The fallback value returned when input is `null` or base validation fails.
  final O defaultValue;

  const DefaultSchema(this.base, this.defaultValue);

  @override
  ZemaResult<O> safeParse(I? value) {
    if (value == null) return success(defaultValue);

    final result = base.safeParse(value);
    if (result.isFailure) return success(defaultValue);

    return result;
  }
}
