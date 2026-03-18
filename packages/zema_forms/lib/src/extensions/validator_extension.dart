import 'package:zema/zema.dart';

/// Form-mode bridge extensions on [ZemaSchema].
///
/// These extensions convert any [ZemaSchema] into a function that is
/// compatible with Flutter's [TextFormField.validator] signature:
/// `String? Function(String?)`.
///
/// Use these when you want to validate individual fields against a schema
/// without a [ZemaFormController], for example inside an existing [Form]
/// widget that already manages its own state.
///
/// ```dart
/// final emailSchema = z.string().email();
///
/// TextFormField(
///   validator: emailSchema.toValidator(),
/// )
/// ```
///
/// For full form management with per-field error notifiers and typed output,
/// use [ZemaFormController] and [ZemaTextField] instead.
extension ZemaValidatorExtension<I, O> on ZemaSchema<I, O> {
  /// Returns a [TextFormField]-compatible validator function.
  ///
  /// The returned function calls [safeParse] with the raw string value and:
  /// - Returns the first error [ZemaIssue.message] when validation fails.
  /// - Returns `null` when validation succeeds (as required by Flutter).
  ///
  /// Empty strings and `null` are passed to the schema as-is. Wrap the schema
  /// with `.optional()` if an empty/absent value should be considered valid.
  ///
  /// ```dart
  /// TextFormField(
  ///   validator: z.string().min(2).toValidator(),
  /// )
  ///
  /// // Optional field: null and '' both pass.
  /// TextFormField(
  ///   validator: z.string().email().optional().toValidator(),
  /// )
  /// ```
  String? Function(String?) toValidator() {
    return (String? value) {
      final result = safeParse(value as I);
      return result.isFailure ? result.errors.first.message : null;
    };
  }

  /// Returns a [TextFormField]-compatible validator that reports all error
  /// messages joined by [separator].
  ///
  /// Useful for schemas with multiple constraints where you want to surface
  /// every failure at once rather than just the first.
  ///
  /// ```dart
  /// TextFormField(
  ///   validator: z.string().min(8).max(64).toFullValidator(),
  /// )
  /// ```
  ///
  /// Defaults to `'\n'` as the separator so each message appears on its own
  /// line inside the `errorText` widget.
  String? Function(String?) toFullValidator({String separator = '\n'}) {
    return (String? value) {
      final result = safeParse(value as I);
      if (!result.isFailure) return null;
      return result.errors.map((e) => e.message).join(separator);
    };
  }
}
