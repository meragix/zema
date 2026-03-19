import 'package:flutter/widgets.dart';
import 'package:zema_forms/src/controller/zema_form_controller.dart';

/// Provides a [ZemaFormController] to all descendant [ZemaTextField] widgets.
///
/// [ZemaForm] is an [InheritedWidget] that acts as a pure lookup scope. It
/// does not own reactive state and never triggers rebuilds on its own. It only
/// makes the controller available to descendants via [ZemaForm.of].
///
/// Using [ZemaForm] is optional. You can always pass the controller explicitly
/// to each [ZemaTextField] via its `controller` parameter. [ZemaForm] exists
/// to eliminate prop-drilling in large forms.
///
/// ## With ZemaForm (no prop drilling)
///
/// ```dart
/// ZemaForm(
///   controller: _ctrl,
///   child: Column(
///     children: [
///       ZemaTextField(field: 'email'),
///       ZemaTextField(field: 'password'),
///       ElevatedButton(
///         onPressed: () => _ctrl.submit(),
///         child: const Text('Sign in'),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## Without ZemaForm (explicit controller)
///
/// ```dart
/// ZemaTextField(field: 'email', controller: _ctrl)
/// ZemaTextField(field: 'password', controller: _ctrl)
/// ```
///
/// Both patterns produce identical runtime behaviour.
class ZemaForm<T> extends InheritedWidget {
  /// Creates a [ZemaForm] scope.
  const ZemaForm({
    required this.controller,
    required super.child,
    super.key,
  });

  /// The controller made available to all descendants.
  final ZemaFormController<T> controller;

  /// Returns the nearest [ZemaFormController] of type [T] from the widget
  /// tree, or `null` when there is no [ZemaForm] ancestor.
  ///
  /// This call does not register a dependency on [ZemaForm] — the controller
  /// reference is expected to be stable for the lifetime of the form state.
  static ZemaFormController<T>? of<T>(BuildContext context) {
    return context.getInheritedWidgetOfExactType<ZemaForm<T>>()?.controller;
  }

  /// Returns the nearest [ZemaFormController] of type [T] from the widget
  /// tree.
  ///
  /// Throws a [FlutterError] when no [ZemaForm] ancestor is found. Use this
  /// inside widgets that require the scope to be present.
  static ZemaFormController<T> ofRequired<T>(BuildContext context) {
    final ctrl = of<T>(context);
    if (ctrl != null) return ctrl;
    throw FlutterError.fromParts(<DiagnosticsNode>[
      ErrorSummary('ZemaForm.ofRequired<$T> called outside a ZemaForm scope.'),
      ErrorDescription(
        'No ZemaForm<$T> ancestor was found above '
        '${context.widget.runtimeType}.',
      ),
      ErrorHint(
        'Wrap the form in a ZemaForm<$T> widget, or pass the controller '
        'explicitly to each ZemaTextField via the controller parameter.',
      ),
    ]);
  }

  // Pure lookup scope: the controller reference never changes after creation,
  // so there is nothing to notify descendants about.
  @override
  bool updateShouldNotify(ZemaForm<T> oldWidget) => false;
}
