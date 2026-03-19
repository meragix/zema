import 'package:flutter/widgets.dart';
import 'package:zema/zema.dart';

/// Controls form state for a [ZemaObject]-backed form.
///
/// [ZemaFormController] is the single source of truth for a form. It owns:
/// - One [TextEditingController] per field, accessed via [controllerFor].
/// - One [ValueNotifier]<[List]<[ZemaIssue]>> per field, accessed via [errorsFor].
/// - One [ValueNotifier]<[bool]> per field for touched state, via [touchedFor].
/// - A global [isSubmitted] notifier shared across all fields.
/// - A [FocusNode] registry used to auto-focus the first field in error after
///   a failed [submit].
///
/// ## "First contact" UX
///
/// Errors are validated internally on every keystroke (when [validateOnChange]
/// is `true`), but [ZemaTextField] only renders them when:
///
/// ```
/// (isTouched || isSubmitted) && errors.isNotEmpty
/// ```
///
/// A field becomes touched when it loses focus for the first time.
/// [isSubmitted] becomes `true` on the first call to [submit], which reveals
/// all remaining errors at once and moves focus to the first failing field.
///
/// ## Lifecycle
///
/// ```dart
/// final _schema = z.object({
///   'email':    z.string().email(),
///   'password': z.string().min(8),
/// });
///
/// late final _ctrl = ZemaFormController(schema: _schema);
///
/// @override
/// void dispose() {
///   _ctrl.dispose(); // required — releases TextEditingControllers and notifiers
///   super.dispose();
/// }
/// ```
///
/// ## Reactive mode (default)
///
/// Wire [ZemaTextField] widgets directly. Validation runs on each keystroke;
/// errors appear only after the user leaves the field or submits.
///
/// ```dart
/// ZemaTextField(field: 'email', controller: _ctrl)
/// ```
///
/// ## Form-mode bridge
///
/// Use [validatorFor] to drop into Flutter's native [Form] widget:
///
/// ```dart
/// TextFormField(
///   controller: _ctrl.controllerFor('email'),
///   validator:  _ctrl.validatorFor('email'),
/// )
/// ```
class ZemaFormController<T> {
  /// Creates a controller for [schema].
  ///
  /// [validateOnChange] controls when per-field validation runs:
  /// - `true` (default): validate on every keystroke after the first edit.
  /// - `false`: defer all validation until [submit] is called.
  ///
  /// Errors only become visible after the field is touched (loses focus) or
  /// [submit] is called, regardless of [validateOnChange].
  ///
  /// [initialValues] pre-populates fields before the first build.
  ZemaFormController({
    required this.schema,
    this.validateOnChange = true,
    Map<String, String>? initialValues,
  }) {
    if (initialValues != null) {
      for (final entry in initialValues.entries) {
        controllerFor(entry.key).text = entry.value;
      }
    }
  }

  /// The schema that describes the form shape and all validation rules.
  final ZemaObject<T> schema;

  /// When `true` (default), each field is validated on every keystroke.
  /// When `false`, validation only runs on [submit].
  ///
  /// In both cases, errors are only shown after the field is touched or
  /// [submit] is called.
  final bool validateOnChange;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, ValueNotifier<List<ZemaIssue>>> _fieldErrors = {};
  final Map<String, ValueNotifier<bool>> _fieldTouched = {};
  final Map<String, FocusNode> _focusNodes = {};

  /// `true` after the first call to [submit]. Resets to `false` on [reset].
  ///
  /// [ZemaTextField] listens to this notifier to reveal errors on all fields
  /// simultaneously when the user submits the form.
  final ValueNotifier<bool> isSubmitted = ValueNotifier(false);

  /// All issues produced by the most recent failed [submit] call.
  ///
  /// Empty when the form has not been submitted yet, when the last [submit]
  /// succeeded, or after [reset] is called.
  ///
  /// Use this to drive a form-level error banner that remains visible even
  /// when the first field in error is hidden (inside a collapsed section,
  /// a non-selected tab, etc.):
  ///
  /// ```dart
  /// ValueListenableBuilder<List<ZemaIssue>>(
  ///   valueListenable: _ctrl.submitErrors,
  ///   builder: (context, issues, _) {
  ///     if (issues.isEmpty) return const SizedBox.shrink();
  ///     return ErrorBanner(
  ///       message: '${issues.length} field(s) require attention.',
  ///     );
  ///   },
  /// )
  /// ```
  final ValueNotifier<List<ZemaIssue>> submitErrors =
      ValueNotifier(const []);

  // ---------------------------------------------------------------------------
  // Field accessors
  // ---------------------------------------------------------------------------

  /// Returns (and lazily creates) the [TextEditingController] for [field].
  ///
  /// The controller is wired internally to trigger per-field validation.
  /// Do not attach additional validation listeners manually.
  ///
  /// ```dart
  /// TextField(controller: _ctrl.controllerFor('email'))
  /// ```
  TextEditingController controllerFor(String field) {
    if (_textControllers.containsKey(field)) return _textControllers[field]!;

    final tc = TextEditingController();
    _textControllers[field] = tc;
    _fieldErrors.putIfAbsent(
      field,
      () => ValueNotifier<List<ZemaIssue>>(const []),
    );
    tc.addListener(() => _onFieldChanged(field, tc.text));
    return tc;
  }

  /// Returns (and lazily creates) the error [ValueNotifier] for [field].
  ///
  /// Contains the raw validation issues regardless of touched/submitted state.
  /// [ZemaTextField] uses [touchedFor] and [isSubmitted] to decide whether
  /// to render them.
  ValueNotifier<List<ZemaIssue>> errorsFor(String field) {
    return _fieldErrors.putIfAbsent(
      field,
      () => ValueNotifier<List<ZemaIssue>>(const []),
    );
  }

  /// Returns (and lazily creates) the touched [ValueNotifier] for [field].
  ///
  /// `true` once the field has lost focus at least once. [ZemaTextField]
  /// sets this automatically via [markTouched]. You can set it manually to
  /// force-show errors on a field before submit.
  ValueNotifier<bool> touchedFor(String field) {
    return _fieldTouched.putIfAbsent(field, () => ValueNotifier(false));
  }

  /// Marks [field] as touched, making its errors visible.
  ///
  /// Called automatically by [ZemaTextField] when the field loses focus.
  /// Can also be called programmatically, for example when navigating away
  /// from a step in a multi-step form.
  void markTouched(String field) {
    touchedFor(field).value = true;
  }

  // ---------------------------------------------------------------------------
  // FocusNode registry
  // ---------------------------------------------------------------------------

  /// Registers [node] for [field].
  ///
  /// Called automatically by [ZemaTextField] during [State.initState].
  /// [submit] uses the registry to request focus on the first failing field.
  void registerFocusNode(String field, FocusNode node) {
    _focusNodes[field] = node;
  }

  /// Removes the focus node registration for [field].
  ///
  /// Called automatically by [ZemaTextField] during [State.dispose].
  void unregisterFocusNode(String field) {
    _focusNodes.remove(field);
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  /// Validates the entire form against [schema] and returns the typed output.
  ///
  /// Sets [isSubmitted] to `true`, which makes all field errors visible
  /// regardless of touched state. On failure, fans issues out to per-field
  /// notifiers and requests focus on the first failing field (in schema
  /// declaration order). Returns `null` when any field fails.
  ///
  /// On success, clears all error notifiers and returns the coerced output [T].
  ///
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () {
  ///     final data = _ctrl.submit();
  ///     if (data != null) api.createUser(data);
  ///   },
  ///   child: const Text('Submit'),
  /// )
  /// ```
  T? submit() {
    isSubmitted.value = true;

    final raw = <String, dynamic>{
      for (final entry in _textControllers.entries)
        entry.key: entry.value.text,
      for (final key in schema.shape.keys)
        if (!_textControllers.containsKey(key)) key: null,
    };

    final result = schema.safeParse(raw);

    if (result.isFailure) {
      // Group issues by their first path segment (field name).
      final byField = <String, List<ZemaIssue>>{};
      for (final issue in result.errors) {
        final field =
            issue.path.isNotEmpty ? issue.path.first.toString() : '__root__';
        (byField[field] ??= []).add(issue);
      }

      // Publish errors to per-field notifiers.
      for (final key in schema.shape.keys) {
        errorsFor(key).value = byField[key] ?? const [];
      }

      // Expose the full issue list for form-level error banners. This is the
      // only reliable signal when the first field in error is not mounted.
      submitErrors.value = result.errors;

      // Move focus to the first focusable field in error (schema declaration
      // order). canRequestFocus is false when the node is not attached to the
      // widget tree (hidden / conditionally removed fields) or explicitly
      // disabled — skip those silently.
      for (final key in schema.shape.keys) {
        if ((byField[key] ?? const []).isNotEmpty) {
          final node = _focusNodes[key];
          if (node != null && node.canRequestFocus) {
            node.requestFocus();
          }
          break;
        }
      }

      return null;
    }

    for (final notifier in _fieldErrors.values) {
      notifier.value = const [];
    }
    submitErrors.value = const [];
    return result.value;
  }

  // ---------------------------------------------------------------------------
  // Form-mode bridge
  // ---------------------------------------------------------------------------

  /// Returns a [TextFormField]-compatible validator function for [field].
  ///
  /// The returned `String? Function(String?)` validates the raw string against
  /// the field schema and returns the first error message, or `null` when valid.
  ///
  /// ```dart
  /// TextFormField(
  ///   controller: _ctrl.controllerFor('email'),
  ///   validator:  _ctrl.validatorFor('email'),
  /// )
  /// ```
  String? Function(String?) validatorFor(String field) {
    return (String? value) {
      final fieldSchema = schema.shape[field];
      if (fieldSchema == null) return null;
      final result = fieldSchema.safeParse(value);
      return result.isFailure ? result.errors.first.message : null;
    };
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  /// `true` when at least one field currently has one or more validation errors.
  bool get hasErrors => _fieldErrors.values.any((n) => n.value.isNotEmpty);

  /// Sets the text value of [field] programmatically.
  ///
  /// Triggers the field's change listener: if [validateOnChange] is `true`
  /// the field is validated immediately.
  void setValue(String field, String value) {
    controllerFor(field).text = value;
  }

  /// Resets all fields to empty strings and clears every validation error.
  ///
  /// Resets [isSubmitted] and all touched notifiers, returning the form to its
  /// initial pre-interaction state.
  void reset() {
    isSubmitted.value = false;
    submitErrors.value = const [];
    for (final n in _fieldTouched.values) {
      n.value = false;
    }
    for (final tc in _textControllers.values) {
      tc.text = '';
    }
    for (final notifier in _fieldErrors.values) {
      notifier.value = const [];
    }
  }

  /// Releases all [TextEditingController]s, [ValueNotifier]s, and the
  /// [isSubmitted] and [submitErrors] notifiers owned by this controller.
  ///
  /// Must be called from [State.dispose]. Not calling [dispose] leaks the
  /// listeners attached to each [TextEditingController].
  ///
  /// Dispose order is intentional:
  /// 1. [TextEditingController]s first — removes listeners that write to
  ///    [_fieldErrors], preventing writes to already-disposed notifiers.
  /// 2. Per-field notifiers ([_fieldErrors], [_fieldTouched]) — safe once
  ///    their write sources are gone.
  /// 3. Global notifiers ([isSubmitted], [submitErrors]) last — no per-field
  ///    notifier reads from them, so orphaned listeners cannot fire against a
  ///    disposed global state during a fast screen teardown.
  void dispose() {
    for (final tc in _textControllers.values) {
      tc.dispose();
    }
    for (final notifier in _fieldErrors.values) {
      notifier.dispose();
    }
    for (final notifier in _fieldTouched.values) {
      notifier.dispose();
    }
    isSubmitted.dispose();
    submitErrors.dispose();
    _textControllers.clear();
    _fieldErrors.clear();
    _fieldTouched.clear();
    _focusNodes.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onFieldChanged(String field, String rawValue) {
    if (validateOnChange || isSubmitted.value) {
      _validateField(field, rawValue);
    }
  }

  void _validateField(String field, String rawValue) {
    final fieldSchema = schema.shape[field];
    if (fieldSchema == null) return;
    final result = fieldSchema.safeParse(rawValue);
    errorsFor(field).value =
        result.isFailure ? result.errors : const [];
  }
}
