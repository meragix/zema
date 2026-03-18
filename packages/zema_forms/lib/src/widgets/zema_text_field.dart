import 'package:flutter/material.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/src/controller/zema_form_controller.dart';
import 'package:zema_forms/src/widgets/zema_form.dart';

/// A [TextField] wired to a [ZemaFormController] field.
///
/// [ZemaTextField] is a [StatelessWidget]. It subscribes to the per-field
/// error notifier from the controller, so only this widget rebuilds when its
/// validation state changes. No other field in the form is touched.
///
/// ## Controller resolution
///
/// The controller is resolved in order:
/// 1. The explicit [controller] parameter, if provided.
/// 2. The nearest [ZemaForm] ancestor in the widget tree.
///
/// An [AssertionError] is thrown in debug mode when neither source is present.
///
/// ## Basic usage (with ZemaForm scope)
///
/// ```dart
/// ZemaForm(
///   controller: _ctrl,
///   child: Column(
///     children: [
///       ZemaTextField(field: 'email'),
///       ZemaTextField(field: 'password', obscureText: true),
///     ],
///   ),
/// )
/// ```
///
/// ## Explicit controller
///
/// ```dart
/// ZemaTextField(
///   field: 'email',
///   controller: _ctrl,
///   decoration: const InputDecoration(labelText: 'Email'),
/// )
/// ```
///
/// ## Decoration
///
/// All [InputDecoration] properties are forwarded to the underlying
/// [TextField]. The `errorText` property is managed internally and overrides
/// any value you set via [decoration]. Use [errorBuilder] to customise how
/// the error message is rendered when the default `errorText` is not enough.
///
/// ## Coercion
///
/// [TextField] always produces a [String]. For numeric schema fields use the
/// coercion layer so the schema handles the String-to-number conversion:
///
/// ```dart
/// z.object({
///   'age': z.coerce().integer().gte(0),
/// })
/// ```
class ZemaTextField<T> extends StatelessWidget {
  /// Creates a [ZemaTextField] bound to [field] in the active
  /// [ZemaFormController].
  const ZemaTextField({
    required this.field,
    this.controller,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.autofocus = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.onSubmitted,
    this.onTap,
    this.errorBuilder,
    super.key,
  });

  /// The key in [ZemaFormController.schema] that this field validates.
  final String field;

  /// The controller that manages this field's state.
  ///
  /// When `null`, the controller is resolved from the nearest [ZemaForm]
  /// ancestor. One of the two must be present.
  final ZemaFormController<T>? controller;

  /// Decoration forwarded to the underlying [TextField].
  ///
  /// `errorText` is managed internally and is overridden by validation errors.
  /// All other [InputDecoration] properties are forwarded as-is.
  final InputDecoration? decoration;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType? keyboardType;

  /// {@macro flutter.widgets.editableText.textInputAction}
  final TextInputAction? textInputAction;

  /// {@macro flutter.widgets.editableText.obscureText}
  final bool obscureText;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.readOnly}
  final bool readOnly;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int? maxLines;

  /// {@macro flutter.widgets.editableText.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.editableText.maxLength}
  final int? maxLength;

  /// Called when the user submits the field (e.g. presses the keyboard action
  /// button). The [String] argument is the current field value.
  final void Function(String)? onSubmitted;

  /// Called when the field is tapped.
  final void Function()? onTap;

  /// Custom error renderer. When provided, replaces the default `errorText`
  /// behaviour. Receives the list of [ZemaIssue]s for this field.
  ///
  /// ```dart
  /// ZemaTextField(
  ///   field: 'email',
  ///   errorBuilder: (issues) => Text(
  ///     issues.first.message,
  ///     style: const TextStyle(color: Colors.red, fontSize: 11),
  ///   ),
  /// )
  /// ```
  final Widget Function(List<ZemaIssue> issues)? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final resolved = controller ?? ZemaForm.of<T>(context);
    assert(
      resolved != null,
      'ZemaTextField(field: "$field") could not find a ZemaFormController. '
      'Either provide the controller parameter directly, or wrap this widget '
      'in a ZemaForm.',
    );

    final ctrl = resolved!;

    return ValueListenableBuilder<List<ZemaIssue>>(
      valueListenable: ctrl.errorsFor(field),
      builder: (context, issues, _) {
        if (errorBuilder != null && issues.isNotEmpty) {
          // Custom error rendering: stack the TextField above the custom widget.
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(ctrl, issues: const []),
              errorBuilder!(issues),
            ],
          );
        }

        return _buildTextField(ctrl, issues: issues);
      },
    );
  }

  TextField _buildTextField(
    ZemaFormController<T> ctrl, {
    required List<ZemaIssue> issues,
  }) {
    final effectiveDecoration = (decoration ?? const InputDecoration()).copyWith(
      errorText: issues.isNotEmpty ? issues.first.message : null,
    );

    return TextField(
      controller: ctrl.controllerFor(field),
      decoration: effectiveDecoration,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      autocorrect: autocorrect,
      autofocus: autofocus,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onSubmitted: onSubmitted,
      onTap: onTap,
    );
  }
}
