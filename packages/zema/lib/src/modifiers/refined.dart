import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/error/severity.dart';

/// Extension that adds [refine], [refineAsync], [refineWarn], and
/// [superRefine] to every [ZemaSchema].
///
/// These methods let you attach **custom validation logic** on top of any
/// existing schema without creating a new schema class.
///
/// ## Choosing the right method
///
/// | Method | Async | Issues | Best for |
/// |---|---|---|---|
/// | [refine] | No | 1 (error) | Simple predicates |
/// | [refineAsync] | Yes | 1 (error) | I/O checks (DB, network) |
/// | [refineWarn] | No | 1 (warning) | Advisory checks that don't block |
/// | [superRefine] | No | N (full control) | Multi-issue custom logic |
extension ZemaSchemaRefinement<I, O> on ZemaSchema<I, O> {
  /// Adds a synchronous custom validation rule via a boolean [predicate].
  ///
  /// The predicate runs **after** the base schema succeeds. If it returns
  /// `false`, a single issue is produced with the given [message] (default:
  /// `'Custom validation failed'`) and [code] (default: `'custom_error'`).
  ///
  /// ```dart
  /// // Ensure a string is a palindrome
  /// final palindrome = z.string().refine(
  ///   (s) => s == s.split('').reversed.join(),
  ///   message: 'Must be a palindrome',
  ///   code: 'not_palindrome',
  /// );
  ///
  /// palindrome.parse('racecar'); // 'racecar'
  /// palindrome.parse('hello');   // fails — not_palindrome
  ///
  /// // Compound rule on an object
  /// final rangeSchema = z.object({
  ///   'min': z.integer(),
  ///   'max': z.integer(),
  /// }).refine(
  ///   (m) => (m['min'] as int) < (m['max'] as int),
  ///   message: 'min must be less than max',
  /// );
  /// ```
  ///
  /// Note: chained `.refine()` calls are sequential — the first failure stops
  /// the chain. To collect multiple issues in a single pass, use [superRefine].
  ///
  /// See also:
  /// - [refineAsync] — for predicates that require async I/O.
  /// - [refineWarn] — for advisory checks that don't block the parse.
  /// - [superRefine] — for producing multiple issues or accessing a context.
  ZemaSchema<I, O> refine(
    bool Function(O) predicate, {
    String? message,
    String? code,
  }) =>
      _RefinedSchema(
        this,
        predicate,
        message ?? 'Custom validation failed',
        code ?? 'custom_error',
      );

  /// Adds an asynchronous custom validation rule via a boolean [predicate].
  ///
  /// The predicate runs **after** the base schema succeeds, **only** when
  /// [ZemaSchema.safeParseAsync] (or [ZemaSchema.parseAsync]) is called.
  ///
  /// **Breaking change from 0.5.0**: Calling the synchronous
  /// [ZemaSchema.safeParse] on a schema that has async refinements now returns
  /// a [ZemaFailure] with code `async_refinement_skipped` instead of silently
  /// bypassing the async predicate. Always use `safeParseAsync()` or
  /// `parseAsync()` when the chain contains `.refineAsync()`.
  ///
  /// If the predicate returns `false`, a single issue with [message] and
  /// [code] is produced. If it throws, an `async_refinement_error` issue is
  /// produced with the exception message.
  ///
  /// ```dart
  /// final uniqueEmail = z.string().email().refineAsync(
  ///   (email) async => !(await db.emailExists(email)),
  ///   message: 'This email is already registered.',
  ///   code: 'email_taken',
  /// );
  ///
  /// // Must use the async path to trigger the DB check
  /// final result = await uniqueEmail.safeParseAsync(input);
  /// ```
  ///
  /// See also:
  /// - [refine] — the synchronous equivalent.
  /// - [ZemaSchema.safeParseAsync] — required to exercise async refinements.
  ZemaSchema<I, O> refineAsync(
    Future<bool> Function(O) predicate, {
    String? message,
    String? code,
  }) =>
      _AsyncRefinedSchema(
        this,
        predicate,
        message ?? 'Async validation failed',
        code ?? 'async_custom_error',
      );

  /// Adds a warning-level refinement that does **not** fail the parse.
  ///
  /// If [predicate] returns `false`, the parse still succeeds but a
  /// [ZemaSeverity.warning] issue is added to [ZemaResult.warnings]. Use this
  /// for advisory checks such as password strength hints, deprecation notices,
  /// or soft data-quality rules in Flutter forms.
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
  /// print(result.isSuccess);       // true — parse succeeded
  /// print(result.hasWarnings);     // true
  /// print(result.warnings.first.message); // advisory message
  /// ```
  ///
  /// See also:
  /// - [refine] — the error-level equivalent.
  /// - [ZemaResult.warnings] — where warning issues are surfaced.
  ZemaSchema<I, O> refineWarn(
    bool Function(O) predicate, {
    String? message,
    String? code,
  }) =>
      _WarnRefinedSchema(
        this,
        predicate,
        message ?? 'Validation warning',
        code ?? 'custom_warning',
      );

  /// Adds a custom validation rule with full control over the issues produced.
  ///
  /// Unlike [refine], the [validator] function receives the validated output
  /// and a [ValidationContext], and returns a list of [ZemaIssue]s (or `null`
  /// to signal success). This lets you:
  /// - Produce **multiple** issues in a single pass.
  /// - Set custom `code`, `path`, `meta`, and `receivedValue` on each issue.
  /// - Implement inter-field validation on an object.
  ///
  /// ```dart
  /// final passwordSchema = z.object({
  ///   'password': z.string(),
  ///   'confirm':  z.string(),
  /// }).superRefine((map, ctx) {
  ///   if (map['password'] != map['confirm']) {
  ///     return [
  ///       ZemaIssue(
  ///         code: 'passwords_mismatch',
  ///         message: 'Passwords do not match.',
  ///         path: ['confirm'],
  ///       ),
  ///     ];
  ///   }
  ///   return null; // success
  /// });
  /// ```
  ///
  /// Return `null` or an empty list to indicate that no issues were found.
  ///
  /// See also:
  /// - [refine] — simpler API for single-issue predicates.
  /// - [ValidationContext] — the context object passed to the validator.
  ZemaSchema<I, O> superRefine(
    List<ZemaIssue>? Function(O, ValidationContext) validator,
  ) =>
      _SuperRefinedSchema(this, validator);
}

// =============================================================================
// Internal schema implementations
// =============================================================================

final class _RefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final bool Function(O) predicate;
  final String message;
  final String code;

  const _RefinedSchema(this.base, this.predicate, this.message, this.code);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return result;

    final output = result.value;
    if (!predicate(output)) {
      return singleFailure(ZemaIssue(code: code, message: message));
    }

    return success(output, warnings: result.warnings);
  }
}

final class _AsyncRefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final Future<bool> Function(O) predicate;
  final String message;
  final String code;

  const _AsyncRefinedSchema(this.base, this.predicate, this.message, this.code);

  /// Calling [safeParse] on a schema that contains async refinements is a
  /// programming error — the async predicate would be silently skipped,
  /// producing a false success. This method returns a [ZemaFailure] with
  /// code `async_refinement_skipped` to surface the mistake immediately.
  ///
  /// Use [safeParseAsync] or [parseAsync] instead.
  @override
  ZemaResult<O> safeParse(I value) {
    return singleFailure(
      const ZemaIssue(
        code: 'async_refinement_skipped',
        message: 'This schema contains async refinements. '
            'Call safeParseAsync() or parseAsync() instead of '
            'safeParse() or parse().',
      ),
    );
  }

  @override
  Future<ZemaResult<O>> safeParseAsync(I value) async {
    final result = await base.safeParseAsync(value);
    if (result.isFailure) return result;

    final output = result.value;

    try {
      final isValid = await predicate(output);
      if (!isValid) {
        return singleFailure(ZemaIssue(code: code, message: message));
      }
      return success(output, warnings: result.warnings);
    } catch (e) {
      return singleFailure(
        ZemaIssue(
          code: 'async_refinement_error',
          message: 'Async validation failed: $e',
        ),
      );
    }
  }
}

final class _WarnRefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final bool Function(O) predicate;
  final String message;
  final String code;

  const _WarnRefinedSchema(this.base, this.predicate, this.message, this.code);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return result;

    final output = result.value;
    final baseWarnings = result.warnings;

    if (!predicate(output)) {
      return success(
        output,
        warnings: [
          ...baseWarnings,
          ZemaIssue(
            code: code,
            message: message,
            severity: ZemaSeverity.warning,
          ),
        ],
      );
    }

    return result;
  }
}

/// Context object passed to [ZemaSchemaRefinement.superRefine] validators.
///
/// Carries the field path and any metadata associated with the current
/// validation call. Currently used as a carrier for future extensibility —
/// inspect [path] and [meta] when constructing issues manually.
///
/// ```dart
/// schema.superRefine((value, ctx) {
///   if (someCondition) {
///     return [
///       ZemaIssue(
///         code: 'my_code',
///         message: 'Something is wrong.',
///         path: [...ctx.path, 'fieldName'],
///         meta: ctx.meta,
///       ),
///     ];
///   }
///   return null;
/// });
/// ```
class ValidationContext {
  /// Path segments leading to the current value being validated.
  final List<String> path;

  /// Arbitrary metadata provided by the schema or its parent.
  final Map<String, dynamic> meta;

  ValidationContext({
    this.path = const [],
    this.meta = const {},
  });

  void addIssue({required String code, required String message}) {
    // Store issue in context
  }
}

final class _SuperRefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final List<ZemaIssue>? Function(O, ValidationContext) validator;

  const _SuperRefinedSchema(this.base, this.validator);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return result;

    final output = result.value;
    final ctx = ValidationContext();
    final issues = validator(output, ctx);

    if (issues != null && issues.isNotEmpty) {
      return failure(issues);
    }

    return success(output, warnings: result.warnings);
  }
}
