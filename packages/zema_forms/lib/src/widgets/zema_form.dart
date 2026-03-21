import 'package:flutter/widgets.dart';
import 'package:zema_forms/src/controller/zema_form_controller.dart';

/// Provides a [ZemaFormController] to all descendant [ZemaTextField] widgets.
///
/// [ZemaForm] acts as a pure lookup scope. It does not own reactive state and
/// never triggers rebuilds on its own. It only makes the controller available
/// to descendants via [ZemaForm.of].
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
class ZemaForm<T> extends StatelessWidget {
  /// Creates a [ZemaForm] scope.
  const ZemaForm({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller made available to all descendants.
  final ZemaFormController<T> controller;

  /// The widget below this widget in the tree.
  final Widget child;

  /// Returns the nearest [ZemaFormController] from the widget tree, or `null`
  /// when there is no [ZemaForm] ancestor.
  ///
  /// This call does not register a dependency on [ZemaForm] — the controller
  /// reference is expected to be stable for the lifetime of the form state.
  ///
  /// The type parameter [T] is used only for the return type cast. The lookup
  /// itself is type-agnostic, so [ZemaTextField] widgets without an explicit
  /// type argument find the scope correctly regardless of the controller's `T`.
  static ZemaFormController<T>? of<T>(BuildContext context) {
    // ignore: unnecessary_cast
    return context.getInheritedWidgetOfExactType<_ZemaFormScope>()?.controller
        as ZemaFormController<T>?;
  }

  /// Returns the nearest [ZemaFormController] from the widget tree.
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

  @override
  Widget build(BuildContext context) {
    return _ZemaFormScope(controller: controller, child: child);
  }
}

// Private non-generic inherited widget used as the actual scope carrier.
//
// Using a non-generic type for the InheritedWidget lookup avoids the
// type-exact-match pitfall: getInheritedWidgetOfExactType<ZemaForm<T>>()
// would fail when ZemaTextField<dynamic> searches for ZemaForm<Map<…>>.
class _ZemaFormScope extends InheritedWidget {
  const _ZemaFormScope({
    required this.controller,
    required super.child,
  });

  // Stored without a type argument so the lookup in `ZemaForm.of` is
  // type-agnostic. The caller casts to the desired ZemaFormController<T>.
  // ignore: prefer_typing_uninitialized_variables
  final ZemaFormController controller;

  // The controller reference is stable for the lifetime of the form, so there
  // is never anything to notify descendants about.
  @override
  bool updateShouldNotify(_ZemaFormScope old) => false;
}
