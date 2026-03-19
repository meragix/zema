import 'package:flutter/material.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

// Schema defined at file scope — one allocation, reused for every form build.
final _loginSchema = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
});

/// Demonstrates:
/// - [ZemaForm] scope (no prop-drilling to each field)
/// - [ZemaTextField] reactive mode
/// - First-contact UX: errors only appear after the field loses focus
/// - [ZemaFormController.submit] auto-focuses the first field in error
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final _ctrl = ZemaFormController(schema: _loginSchema);
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
        _successMessage = 'Signed in as ${data['email']}';
      });
    } else {
      setState(() => _successMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ZemaForm(
            controller: _ctrl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionHeader(
                  title: 'Basic reactive form',
                  subtitle:
                      'Errors appear after a field loses focus or Submit is tapped.',
                ),
                const SizedBox(height: 24),
                ZemaTextField(
                  field: 'email',
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'you@example.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                ZemaTextField(
                  field: 'password',
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 8 characters',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSubmit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _onSubmit,
                  child: const Text('Sign in'),
                ),
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  _SuccessBanner(message: _successMessage!),
                ],
              ],
            ),
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
