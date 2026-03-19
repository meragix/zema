import 'package:flutter/material.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

// Coercion: the 'age' field receives a String from TextField and converts it
// to int internally. Using z.integer() (without coerce) would always fail
// because TextField never sends an int.
final _registerSchema = z.object({
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.coerce().integer(min: 18, max: 120),
  'password': z.string().min(8),
});

/// Demonstrates:
/// - [ZemaFormController.submitErrors] driving a form-level error banner
/// - Coercion: [z.coerce] on a numeric text field
/// - [validateOnChange]: `false` — errors only revealed on submit
/// - [ZemaFormController.reset]
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // validateOnChange: false — no per-keystroke errors.
  // All errors are revealed at once when submit() is called.
  late final _ctrl = ZemaFormController(
    schema: _registerSchema,
    validateOnChange: false,
  );

  String? _successMessage;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSubmit() {
    final data = _ctrl.submit();
    if (data != null) {
      setState(() {
        _successMessage =
            'Account created for ${data['name']} (age ${data['age']})';
      });
    } else {
      setState(() => _successMessage = null);
    }
  }

  void _onReset() {
    _ctrl.reset();
    setState(() => _successMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                title: 'Error banner + coercion',
                subtitle:
                    'validateOnChange: false. Errors shown on Submit only. '
                    'The banner covers hidden fields.',
              ),
              const SizedBox(height: 16),

              // Form-level error banner — driven by submitErrors.
              // Remains visible even when the first erroring field is hidden.
              ValueListenableBuilder<List<ZemaIssue>>(
                valueListenable: _ctrl.submitErrors,
                builder: (context, issues, _) {
                  if (issues.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ErrorBanner(
                      message:
                          '${issues.length} field(s) require attention.',
                    ),
                  );
                },
              ),

              ZemaForm(
                controller: _ctrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ZemaTextField(
                      field: 'name',
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    ZemaTextField(
                      field: 'email',
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Numeric field: schema uses z.coerce().integer().
                    // TextField sends a String; coercion converts it to int.
                    ZemaTextField(
                      field: 'age',
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                        helperText: 'Must be 18 or older',
                      ),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    ZemaTextField(
                      field: 'password',
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        helperText: 'At least 8 characters',
                      ),
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _onSubmit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _onSubmit,
                      child: const Text('Create account'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _onReset,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                _SuccessBanner(message: _successMessage!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.green.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
