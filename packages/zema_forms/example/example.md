# zema_forms example

A sign-up form driven by a single Zema schema. Errors appear after a field
loses focus or on submit, only the field in error rebuilds, and focus jumps
to the first invalid field when `submit()` fails.

The full runnable app (login, register and profile pages) lives in
[`zema_forms_example`](https://github.com/meragix/zema/tree/main/packages/zema_forms/example/zema_forms_example).

```dart
import 'package:flutter/material.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

// TextField always sends a String: coerce numeric fields.
final signUpSchema = z.object({
  'email': z.string().email(),
  'age': z.coerce().integer(min: 18, max: 120),
  'password': z.string().min(8),
});

class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  late final _form = ZemaFormController(schema: signUpSchema);

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  void _submit() {
    // Validated, coerced output, or null (errors shown, focus moved).
    final data = _form.submit();
    if (data == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome ${data['email']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZemaForm(
      controller: _form,
      child: Column(
        children: [
          const ZemaTextField(
            field: 'email',
            decoration: InputDecoration(labelText: 'Email'),
          ),
          const ZemaTextField(
            field: 'age',
            decoration: InputDecoration(labelText: 'Age'),
            keyboardType: TextInputType.number,
          ),
          const ZemaTextField(
            field: 'password',
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
          ),
          FilledButton(onPressed: _submit, child: const Text('Sign up')),
        ],
      ),
    );
  }
}
```
