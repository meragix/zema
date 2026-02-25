import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

/// A schema that intercepts failures from [base] and converts them into a
/// fallback success value via [handler].
///
/// Created by calling [ZemaSchema.catchError] on any schema — do not
/// instantiate directly.
///
/// ## Behaviour
///
/// | Base result | Output |
/// |---|---|
/// | success | forwarded unchanged |
/// | failure | `success(handler(errors))` — failure is swallowed |
///
/// [handler] receives the full list of [ZemaIssue]s that [base] produced,
/// giving you complete context to compute the fallback. The resulting schema
/// **always succeeds** — it never propagates a failure to the caller.
///
/// ## When to use
///
/// Use [CatchSchema] when you need a recoverable fallback and want access
/// to the issues before deciding what to return. For a static value that
/// requires no inspection of the issues, prefer [ZemaSchema.withDefault]
/// instead — it is simpler and clearer in intent.
///
/// ```dart
/// // Static fallback — use withDefault
/// z.int().withDefault(-1)
///
/// // Dynamic fallback based on issues — use catchError
/// z.int().catchError((issues) {
///   logger.warn('Falling back: ${issues.first.message}');
///   return -1;
/// });
///
/// // Produce a different fallback depending on the issue code
/// z.string().email().catchError((issues) {
///   final isTypeError = issues.any((e) => e.code == 'invalid_type');
///   return isTypeError ? '' : 'fallback@example.com';
/// });
/// ```
///
/// ## Note on async
///
/// [CatchSchema] only wraps the synchronous [ZemaSchema.safeParse] path.
/// The inherited [ZemaSchema.safeParseAsync] delegates to `safeParse`,
/// so the catch behaviour applies to async calls as well without any extra
/// work — as long as [base] itself does not override `safeParseAsync`.
///
/// See also:
/// - [ZemaSchema.catchError] — the fluent API method that constructs this.
/// - [ZemaSchema.withDefault] — static fallback with no access to issues.
final class CatchSchema<I, O> extends ZemaSchema<I, O> {
  /// The schema whose failures are intercepted.
  final ZemaSchema<I, O> base;

  /// Called with the failure's issues to produce the fallback output value.
  final O Function(List<ZemaIssue>) handler;

  const CatchSchema(this.base, this.handler);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) {
      return success(handler(result.errors));
    }
    return result;
  }
}
