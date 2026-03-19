# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## 0.1.0

Initial release.

### Added

- `ZemaFormController<T>` — manages form state for a `ZemaObject`-backed form.
  - Per-field `TextEditingController` and `ValueNotifier<List<ZemaIssue>>` for surgical rebuilds.
  - `isTouched` per-field state via `touchedFor(field)` and `markTouched(field)`. Errors are only visible after the field has lost focus or `submit()` has been called.
  - `isSubmitted`: global `ValueNotifier<bool>` that reveals all errors at once on first submit.
  - `submitErrors`: `ValueNotifier<List<ZemaIssue>>` holding all issues from the last failed `submit()`. Drives form-level error banners.
  - `FocusNode` registry: `registerFocusNode` / `unregisterFocusNode`. On a failed `submit()`, focus moves automatically to the first field in error (schema declaration order). Hidden fields (`canRequestFocus == false`) are skipped silently; iteration stops at the canonical first error regardless.
  - `submit()` — validates the full form, fans errors to per-field notifiers, auto-focuses first error field, returns typed output `T` or `null`.
  - `validatorFor(field)` — form-mode bridge returning `String? Function(String?)` for use with `TextFormField.validator`.
  - `setValue`, `hasErrors`, `reset`, `dispose`.
  - `validateOnChange` flag (default `true`). When `false`, validation runs only on `submit()`.
  - `initialValues` constructor parameter for pre-populating fields.

- `ZemaTextField<T>` — `StatefulWidget` wrapping `TextField`.
  - Owns and manages a `FocusNode`. Registers/unregisters with the controller automatically.
  - Calls `markTouched(field)` on blur via focus listener.
  - Uses `ListenableBuilder` over `Listenable.merge([errorsFor, touchedFor, isSubmitted])` for surgical rebuilds: only the field in error rebuilds.
  - Errors rendered via `InputDecoration.errorText` or a custom `errorBuilder`.
  - Resolves controller from explicit `controller` parameter or nearest `ZemaForm` ancestor.

- `ZemaForm` — `InheritedWidget` scope providing a `ZemaFormController` to descendants.
  - `updateShouldNotify` always returns `false`: zero rebuild overhead.
  - `ZemaForm.of<T>(context)` for O(1) lookup.

- Dispose order in `ZemaFormController.dispose()` is intentional: `TextEditingController`s first (removes write sources), per-field notifiers next, global notifiers (`isSubmitted`, `submitErrors`) last. Prevents orphaned listeners against already-disposed global state during fast screen teardown.
