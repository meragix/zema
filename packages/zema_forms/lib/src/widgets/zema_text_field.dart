import 'package:flutter/material.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/src/controller/zema_form_controller.dart';
import 'package:zema_forms/src/widgets/zema_form.dart';

/// A [TextField] wired to a [ZemaFormController] field.
///
/// [ZemaTextField] is a [StatefulWidget]. It owns a [FocusNode] and registers
/// it with the controller so that:
///
/// - Errors are only rendered after the field has lost focus at least once,
///   or after [ZemaFormController.submit] has been called.
/// - A failed [submit] automatically requests focus on the first field in error.
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
/// ## Error visibility
///
/// Errors are hidden until the user leaves the field (`onBlur`) or calls
/// [ZemaFormController.submit]. This prevents showing "Email invalide" after
/// typing only the first character.
///
/// Use [errorBuilder] to replace the default `errorText` with a custom widget.
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
class ZemaTextField<T> extends StatefulWidget {
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
  /// `errorText` is managed internally and is overridden by visible validation
  /// errors. All other [InputDecoration] properties are forwarded as-is.
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
  /// behaviour. Receives the list of visible [ZemaIssue]s for this field.
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
  State<ZemaTextField<T>> createState() => _ZemaTextFieldState<T>();
}

class _ZemaTextFieldState<T> extends State<ZemaTextField<T>> {
  final FocusNode _focusNode = FocusNode();
  ZemaFormController<T>? _resolved;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveController();
  }

  @override
  void didUpdateWidget(ZemaTextField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _resolved?.unregisterFocusNode(widget.field);
      _resolveController();
    }
  }

  void _resolveController() {
    final ctrl = widget.controller ?? ZemaForm.of<T>(context);
    assert(
      ctrl != null,
      'ZemaTextField(field: "${widget.field}") could not find a '
      'ZemaFormController. Either provide the controller parameter directly, '
      'or wrap this widget in a ZemaForm.',
    );
    if (_resolved != ctrl) {
      _resolved = ctrl;
      ctrl!.registerFocusNode(widget.field, _focusNode);
    }
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _resolved?.markTouched(widget.field);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _resolved?.unregisterFocusNode(widget.field);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _resolved!;

    return ListenableBuilder(
      listenable: Listenable.merge([
        ctrl.errorsFor(widget.field),
        ctrl.touchedFor(widget.field),
        ctrl.isSubmitted,
      ]),
      builder: (context, _) {
        final errors = ctrl.errorsFor(widget.field).value;
        final touched = ctrl.touchedFor(widget.field).value;
        final submitted = ctrl.isSubmitted.value;
        final visibleErrors =
            (touched || submitted) ? errors : const <ZemaIssue>[];

        if (widget.errorBuilder != null && visibleErrors.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(ctrl, visibleErrors: const []),
              widget.errorBuilder!(visibleErrors),
            ],
          );
        }

        return _buildTextField(ctrl, visibleErrors: visibleErrors);
      },
    );
  }

  TextField _buildTextField(
    ZemaFormController<T> ctrl, {
    required List<ZemaIssue> visibleErrors,
  }) {
    final effectiveDecoration =
        (widget.decoration ?? const InputDecoration()).copyWith(
      errorText: visibleErrors.isNotEmpty ? visibleErrors.first.message : null,
    );

    return TextField(
      focusNode: _focusNode,
      controller: ctrl.controllerFor(widget.field),
      decoration: effectiveDecoration,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      onSubmitted: widget.onSubmitted,
      onTap: widget.onTap,
    );
  }
}
