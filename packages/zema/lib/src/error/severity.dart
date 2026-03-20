/// Indicates the severity level of a [ZemaIssue].
///
/// Most validation issues are [error], they cause the parse to fail and
/// the result to be a [ZemaFailure]. A [warning] issue is informational:
/// the parse still succeeds and the warning is surfaced through
/// [ZemaResult.warnings].
///
/// Use [ZemaSchemaRefinement.refineWarn] to produce warning-level issues
/// that do not block the parse from succeeding.
///
/// ```dart
/// final passwordSchema = z.string()
///     .min(8)
///     .refineWarn(
///       (s) => s.contains(RegExp(r'[A-Z]')),
///       message: 'Adding uppercase letters improves password strength.',
///       code: 'weak_password',
///     );
///
/// final result = passwordSchema.safeParse('hello123');
/// // ZemaSuccess — parse succeeds
/// print(result.hasWarnings); // true
/// print(result.warnings.first.code); // 'weak_password'
/// ```
enum ZemaSeverity {
  /// The issue is a hard failure, the parse returns [ZemaFailure].
  error,

  /// The issue is informational, the parse returns [ZemaSuccess] but
  /// [ZemaResult.warnings] is non-empty.
  warning,
}
