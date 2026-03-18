import 'package:flutter/widgets.dart';
import 'package:zema/zema.dart';

/// Controls form state for a [ZemaObject]-backed form.
///
/// [ZemaFormController] is the single source of truth for a form. It owns:
/// - One [TextEditingController] per field, accessed via [controllerFor].
/// - One [ValueNotifier]<[List]<[ZemaIssue]>> per field, accessed via [errorsFor].
///
/// Each field widget subscribes only to its own error notifier. Validation
/// failures cause surgical rebuilds: only the field in error rebuilds, not
/// the entire form.
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
///   _ctrl.dispose(); // required — releases TextEditingControllers and ValueNotifiers
///   super.dispose();
/// }
/// ```
///
/// ## Reactive mode (default)
///
/// Wire [ZemaTextField] widgets directly. Validation runs on each keystroke
/// once the field has been modified.
///
/// ```dart
/// ZemaTextField(field: 'email', controller: _ctrl)
/// ```
///
/// ## Form-mode bridge
///
/// Use [validatorFor] to drop into Flutter's native [Form] widget with zero
/// migration cost:
///
/// ```dart
/// TextFormField(
///   controller: _ctrl.controllerFor('email'),
///   validator:  _ctrl.validatorFor('email'),
/// )
/// ```
///
/// ## Non-string fields
///
/// [TextField] always produces [String]. For numeric or boolean fields, use
/// the coercion layer so the schema handles the conversion:
///
/// ```dart
/// z.object({
///   'age': z.coerce().integer().gte(0),
/// })
/// ```
///
/// If you use `z.integer()` directly (without coerce), the schema receives a
/// [String] and fails with `invalid_type`. This is intentional and documented.
class ZemaFormController<T> {
  /// Creates a controller for [schema].
  ///
  /// [validateOnChange] controls when per-field errors become visible:
  /// - `true` (default): validate on every keystroke after the first edit.
  /// - `false`: defer all validation until [submit] is called.
  ///
  /// [initialValues] pre-populates fields before the first build. Values are
  /// plain strings; coercion (if needed) is applied when validating.
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
  ///
  /// Access field schemas via `schema.shape[field]` when you need to validate
  /// a single field outside of this controller.
  final ZemaObject<T> schema;

  /// When `true` (default), each field is validated on every change once it
  /// has been modified at least once. When `false`, validation only runs on
  /// [submit].
  final bool validateOnChange;

  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, ValueNotifier<List<ZemaIssue>>> _fieldErrors = {};
  final Set<String> _dirtyFields = {};
  bool _submitted = false;

  // ---------------------------------------------------------------------------
  // Field accessors
  // ---------------------------------------------------------------------------

  /// Returns (and lazily creates) the [TextEditingController] for [field].
  ///
  /// Call this once per field, typically inside [State.initState] or directly
  /// in the build method via [ZemaTextField]. The controller is wired
  /// internally to trigger per-field validation. Do not attach additional
  /// validation listeners manually.
  ///
  /// The same instance is returned on every subsequent call for the same
  /// [field].
  ///
  /// ```dart
  /// TextField(controller: _ctrl.controllerFor('email'))
  /// ```
  TextEditingController controllerFor(String field) {
    if (_textControllers.containsKey(field)) {
      return _textControllers[field]!;
    }
    final tc = TextEditingController();
    _textControllers[field] = tc;
    // Pre-create the error notifier so errorsFor() always has an instance
    // whether it is called before or after controllerFor().
    _fieldErrors.putIfAbsent(
      field,
      () => ValueNotifier<List<ZemaIssue>>(const []),
    );
    tc.addListener(() => _onFieldChanged(field, tc.text));
    return tc;
  }

  /// Returns (and lazily creates) the error [ValueNotifier] for [field].
  ///
  /// The same instance is returned on every subsequent call for the same
  /// [field]. Wrap the field widget in a [ValueListenableBuilder] subscribed
  /// here — only that specific field rebuilds when its errors change.
  ///
  /// ```dart
  /// ValueListenableBuilder<List<ZemaIssue>>(
  ///   valueListenable: _ctrl.errorsFor('email'),
  ///   builder: (context, issues, _) {
  ///     return Text(issues.firstOrNull?.message ?? '');
  ///   },
  /// )
  /// ```
  ValueNotifier<List<ZemaIssue>> errorsFor(String field) {
    return _fieldErrors.putIfAbsent(
      field,
      () => ValueNotifier<List<ZemaIssue>>(const []),
    );
  }

  // ---------------------------------------------------------------------------
  // Submission
  // ---------------------------------------------------------------------------

  /// Validates the entire form against [schema] and returns the coerced output.
  ///
  /// On the first call, all fields are marked dirty so every error becomes
  /// visible, regardless of whether the user has touched those fields. Each
  /// field's [errorsFor] notifier is updated, triggering only the widgets
  /// that are in error to rebuild.
  ///
  /// Returns `null` when any field fails validation. Returns the typed output
  /// [T] on success; all field error notifiers are cleared.
  ///
  /// ```dart
  /// ElevatedButton(
  ///   onPressed: () {
  ///     final data = _ctrl.submit();
  ///     if (data != null) {
  ///       api.createUser(data);
  ///     }
  ///   },
  ///   child: const Text('Submit'),
  /// )
  /// ```
  T? submit() {
    _submitted = true;

    // Collect raw values from every registered TextEditingController.
    // Fields declared in the schema but not yet registered (no widget built)
    // receive null so the schema can apply optional/default modifiers correctly.
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
        final field = issue.path.isNotEmpty
            ? issue.path.first.toString()
            : '__root__';
        (byField[field] ??= []).add(issue);
      }
      // Mark every field dirty and publish its errors (empty list = no error).
      for (final key in schema.shape.keys) {
        _dirtyFields.add(key);
        errorsFor(key).value = byField[key] ?? const [];
      }
      return null;
    }

    // Validation succeeded: clear all field errors.
    for (final notifier in _fieldErrors.values) {
      notifier.value = const [];
    }
    return result.value;
  }

  // ---------------------------------------------------------------------------
  // Form-mode bridge
  // ---------------------------------------------------------------------------

  /// Returns a [TextFormField]-compatible validator function for [field].
  ///
  /// The returned `String? Function(String?)` validates [field]'s raw string
  /// against its schema and returns the first error message, or `null` when
  /// valid. Pass it directly to `TextFormField.validator`.
  ///
  /// Use this when integrating [ZemaFormController] into an existing [Form]
  /// widget without migrating to [ZemaTextField]:
  ///
  /// ```dart
  /// TextFormField(
  ///   controller: _ctrl.controllerFor('email'),
  ///   validator:  _ctrl.validatorFor('email'),
  /// )
  /// ```
  ///
  /// Validation is driven by `GlobalKey<FormState>.currentState!.validate()`.
  /// Combine with [submit] to retrieve the typed output after validation.
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
  bool get hasErrors =>
      _fieldErrors.values.any((n) => n.value.isNotEmpty);

  /// Sets the text value of [field] programmatically.
  ///
  /// Triggers the field's change listener, so if [validateOnChange] is `true`
  /// the field is validated immediately.
  ///
  /// Use this to pre-populate fields from external state after the controller
  /// has been created (prefer [initialValues] in the constructor when the
  /// values are known up front).
  ///
  /// ```dart
  /// _ctrl.setValue('email', currentUser.email);
  /// ```
  void setValue(String field, String value) {
    controllerFor(field).text = value;
  }

  /// Resets all fields to empty strings and clears every validation error.
  ///
  /// Also resets the internal submitted flag, so error visibility returns to
  /// the pre-submit state (errors hidden until the next keystroke or submit).
  void reset() {
    _submitted = false;
    _dirtyFields.clear();
    for (final tc in _textControllers.values) {
      tc.text = '';
    }
    for (final notifier in _fieldErrors.values) {
      notifier.value = const [];
    }
  }

  /// Releases all [TextEditingController]s and [ValueNotifier]s owned by this
  /// controller.
  ///
  /// Must be called from [State.dispose]. Not calling [dispose] leaks the
  /// listeners attached to each [TextEditingController].
  ///
  /// ```dart
  /// @override
  /// void dispose() {
  ///   _ctrl.dispose();
  ///   super.dispose();
  /// }
  /// ```
  void dispose() {
    for (final tc in _textControllers.values) {
      tc.dispose();
    }
    for (final notifier in _fieldErrors.values) {
      notifier.dispose();
    }
    _textControllers.clear();
    _fieldErrors.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _onFieldChanged(String field, String rawValue) {
    _dirtyFields.add(field);
    if (validateOnChange || _submitted) {
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
