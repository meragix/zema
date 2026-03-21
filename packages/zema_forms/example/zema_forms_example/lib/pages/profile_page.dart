import 'package:flutter/material.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

// bio is optional: empty string is valid (ZemaObject passes null for empty
// optional fields when the text field has no input).
final _profileSchema = z.object({
  'name': z.string().min(2).max(50),
  'bio': z.string().max(200).optional(),
});

// Simulated existing user data.
const _existingUser = {
  'name': 'Ada Lovelace',
  'bio': 'First programmer. Notes on the Analytical Engine, 1843.',
};

/// Demonstrates:
/// - [ZemaFormController.initialValues] to pre-populate fields
/// - Form-mode bridge: [ZemaFormController.validatorFor] with native
///   [TextFormField] — zero migration cost for existing forms
/// - [ZemaFormController.setValue] to reload data programmatically
/// - [ZemaFormController.reset] to discard changes
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final _ctrl = ZemaFormController(
    schema: _profileSchema,
    initialValues: {
      'name': _existingUser['name']!,
      'bio': _existingUser['bio']!,
    },
  );

  String? _successMessage;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onSave() {
    // Form-mode bridge: validate via Flutter's Form.validate(), then retrieve
    // the typed output from the controller.
    if (_formKey.currentState!.validate()) {
      final data = _ctrl.submit();
      if (data != null) {
        setState(() {
          _successMessage = 'Profile saved: ${data['name']}';
        });
      }
    }
  }

  void _onReload() {
    // setValue updates a field programmatically and triggers validation
    // if validateOnChange is true.
    _ctrl.setValue('name', _existingUser['name']!);
    _ctrl.setValue('bio', _existingUser['bio']!);
    setState(() => _successMessage = null);
  }

  void _onReset() {
    _ctrl.reset();
    setState(() => _successMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionHeader(
                title: 'Form-mode bridge',
                subtitle: 'Uses validatorFor() with native TextFormField. '
                    'Fields are pre-populated via initialValues.',
              ),
              const SizedBox(height: 24),

              // Form-mode: standard Flutter Form + TextFormField.
              // validatorFor(field) returns String? Function(String?) —
              // the exact signature TextFormField.validator expects.
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _ctrl.controllerFor('name'),
                      validator: _ctrl.validatorFor('name'),
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ctrl.controllerFor('bio'),
                      validator: _ctrl.validatorFor('bio'),
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.edit_outlined),
                        helperText: 'Optional. Max 200 characters.',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _onSave(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _onSave,
                      child: const Text('Save profile'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onReload,
                            child: const Text('Reload'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onReset,
                            child: const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_successMessage != null) ...[
                const SizedBox(height: 16),
                _SuccessBanner(message: _successMessage!),
              ],

              const SizedBox(height: 24),
              const _InfoCard(
                title: 'Why validatorFor?',
                body: 'Existing apps using Flutter\'s Form widget can adopt '
                    'Zema schemas incrementally. Replace validators one field '
                    'at a time — no need to rewrite the whole form.',
              ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(body, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
