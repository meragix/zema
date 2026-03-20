# zema_forms

Flutter form widgets backed by [Zema](https://pub.dev/packages/zema) schemas.

- Surgical per-field rebuilds: only the field in error rebuilds on each keystroke.
- "First contact" UX: errors appear after the field loses focus or the form is submitted, never on the first character.
- Auto-focus: failed `submit()` moves focus to the first field in error automatically.
- Form-level error banner via `submitErrors` for hidden or conditional fields.
- Works with Flutter's native `Form` widget (zero migration cost).

## Installation

```yaml
dependencies:
  zema: ^0.5.0
  zema_forms: ^0.1.0
```

## Quick start

```dart
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

final _schema = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
});

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  late final _ctrl = ZemaFormController(schema: _schema);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final data = _ctrl.submit();
    if (data != null) {
      // data is Map<String, dynamic> with validated values
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZemaForm(
      controller: _ctrl,
      child: Column(
        children: [
          ZemaTextField(
            field: 'email',
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          ZemaTextField(
            field: 'password',
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: _onSubmit,
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
```

## Error visibility

Errors are validated on every keystroke but shown only when:

- The field has lost focus at least once (`isTouched`), or
- `submit()` has been called (`isSubmitted`).

This prevents showing "Email invalide" after the user types the first character.

## Form-level error banner

When a form has conditional or hidden fields, pair `submit()` with a banner that reads `submitErrors`:

```dart
ValueListenableBuilder<List<ZemaIssue>>(
  valueListenable: _ctrl.submitErrors,
  builder: (context, issues, _) {
    if (issues.isEmpty) return const SizedBox.shrink();
    return Text('${issues.length} field(s) require attention.');
  },
)
```

## Native Form bridge

```dart
TextFormField(
  controller: _ctrl.controllerFor('email'),
  validator: _ctrl.validatorFor('email'),
)
```

## Numeric fields

`TextField` always produces a `String`. Use the coercion layer for numeric fields:

```dart
z.object({
  'age': z.coerce().integer(min: 0, max: 150),
  'price': z.coerce().decimal(),
})
```

## API reference

| Member                        | Description                                                         |
| ----------------------------- | ------------------------------------------------------------------- |
| `ZemaFormController(schema:)` | Create a controller for the given `ZemaObject`                      |
| `controllerFor(field)`        | `TextEditingController` for the field                               |
| `errorsFor(field)`            | `ValueNotifier<List<ZemaIssue>>` for per-field errors               |
| `touchedFor(field)`           | `ValueNotifier<bool>` — `true` after field loses focus              |
| `markTouched(field)`          | Force-mark a field as touched                                       |
| `isSubmitted`                 | `ValueNotifier<bool>` — `true` after first `submit()`               |
| `submitErrors`                | Issues from the last failed `submit()` call; empty on success       |
| `submit()`                    | Validate, auto-focus first error, return typed output or `null`     |
| `validatorFor(field)`         | `String? Function(String?)` for `TextFormField.validator`           |
| `setValue(field, value)`      | Set field text programmatically                                     |
| `hasErrors`                   | `true` when any field has active errors                             |
| `reset()`                     | Clear all text, errors, and state                                   |
| `dispose()`                   | Release all resources                                               |

## Related packages

- [`zema`](https://pub.dev/packages/zema): core schema library
- [`zema_forms`](https://pub.dev/packages/zema_forms): Flutter form integration
- [`zema_hive`](https://pub.dev/packages/zema_hive): Hive integration
