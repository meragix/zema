/// Flutter form integration for Zema schema validation.
///
/// Provides [ZemaFormController], [ZemaForm], and [ZemaTextField] to bind
/// Zema schemas directly to your Flutter UI with surgical per-field rebuilds
/// and zero boilerplate.
///
/// ## Quick start
///
/// ```dart
/// import 'package:zema/zema.dart';
/// import 'package:zema_forms/zema_forms.dart';
///
/// final _schema = z.object({
///   'email':    z.string().email(),
///   'password': z.string().min(8),
/// });
///
/// class LoginForm extends StatefulWidget { ... }
///
/// class _LoginFormState extends State<LoginForm> {
///   late final _ctrl = ZemaFormController(schema: _schema);
///
///   @override
///   void dispose() {
///     _ctrl.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ZemaForm(
///       controller: _ctrl,
///       child: Column(
///         children: [
///           ZemaTextField(
///             field: 'email',
///             decoration: const InputDecoration(labelText: 'Email'),
///           ),
///           ZemaTextField(
///             field: 'password',
///             obscureText: true,
///             decoration: const InputDecoration(labelText: 'Password'),
///           ),
///           ElevatedButton(
///             onPressed: () {
///               final data = _ctrl.submit();
///               if (data != null) {
///                 // data is fully typed and validated
///               }
///             },
///             child: const Text('Sign in'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
library;

export 'src/controller/zema_form_controller.dart';
export 'src/extensions/validator_extension.dart';
export 'src/widgets/zema_form.dart';
export 'src/widgets/zema_text_field.dart';
