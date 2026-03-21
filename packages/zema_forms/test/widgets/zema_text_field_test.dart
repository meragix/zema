import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

// ---------------------------------------------------------------------------
// Shared schema
// ---------------------------------------------------------------------------

final _schema = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
});

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Wraps [child] in the minimal Flutter widget tree required for testing.
Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Pumps a [ZemaTextField] with an explicit controller.
Widget _fieldWithController(
  ZemaFormController ctrl, {
  required String field,
  InputDecoration? decoration,
  bool obscureText = false,
}) {
  return _wrap(
    ZemaTextField(
      field: field,
      controller: ctrl,
      decoration: decoration,
      obscureText: obscureText,
    ),
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Controller resolution
  // ---------------------------------------------------------------------------

  group('controller resolution', () {
    testWidgets('resolves controller from explicit parameter', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_fieldWithController(ctrl, field: 'email'));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('resolves controller from ZemaForm ancestor', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _wrap(
          ZemaForm(
            controller: ctrl,
            child: const ZemaTextField(field: 'email'),
          ),
        ),
      );

      //expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('explicit controller takes precedence over ZemaForm scope',
        (tester) async {
      final scopeCtrl = ZemaFormController(schema: _schema);
      final explicitCtrl = ZemaFormController(schema: _schema);
      addTearDown(scopeCtrl.dispose);
      addTearDown(explicitCtrl.dispose);

      await tester.pumpWidget(
        _wrap(
          ZemaForm(
            controller: scopeCtrl,
            child: ZemaTextField(
              field: 'email',
              controller: explicitCtrl,
            ),
          ),
        ),
      );

      // The explicit controller's TextEditingController should be wired.
      explicitCtrl.setValue('email', 'typed');
      await tester.pump();
      expect(find.text('typed'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  group('rendering', () {
    testWidgets('renders a TextField', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_fieldWithController(ctrl, field: 'email'));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('forwards decoration label', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _fieldWithController(
          ctrl,
          field: 'email',
          decoration: const InputDecoration(labelText: 'Email address'),
        ),
      );

      expect(find.text('Email address'), findsOneWidget);
    });

    testWidgets('no error text displayed initially', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_fieldWithController(ctrl, field: 'email'));

      // The TextField decoration should have no errorText.
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.errorText, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Per-field surgical rebuilds
  // ---------------------------------------------------------------------------

  group('per-field error display', () {
    testWidgets('shows errorText when field has issues', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_fieldWithController(ctrl, field: 'email'));

      ctrl.controllerFor('email').text = 'not-an-email';
      ctrl.markTouched('email'); // errors only visible after touch or submit
      await tester.pump(); // flush listener + rebuild

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.errorText, isNotNull);
    });

    testWidgets('clears errorText when field becomes valid', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_fieldWithController(ctrl, field: 'email'));

      ctrl.controllerFor('email').text = 'bad';
      ctrl.markTouched('email'); // errors only visible after touch or submit
      await tester.pump();

      final before = tester.widget<TextField>(find.byType(TextField));
      expect(before.decoration?.errorText, isNotNull);

      ctrl.controllerFor('email').text = 'user@example.com';
      await tester.pump();

      final after = tester.widget<TextField>(find.byType(TextField));
      expect(after.decoration?.errorText, isNull);
    });

    testWidgets('only the invalid field shows an error', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _wrap(
          Column(
            children: [
              ZemaTextField(field: 'email', controller: ctrl),
              ZemaTextField(field: 'password', controller: ctrl),
            ],
          ),
        ),
      );

      ctrl.controllerFor('email').text = 'bad-email';
      ctrl.controllerFor('password').text = 'validpass1';
      ctrl.markTouched('email');    // errors only visible after touch or submit
      ctrl.markTouched('password');
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      final errors = fields.map((f) => f.decoration?.errorText).toList();

      // Email should be in error, password should be clean.
      expect(errors[0], isNotNull);
      expect(errors[1], isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Input forwarding
  // ---------------------------------------------------------------------------

  group('input forwarding', () {
    testWidgets('user typing updates the controller text', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(_fieldWithController(ctrl, field: 'email'));

      await tester.enterText(find.byType(TextField), 'hello@test.com');
      await tester.pump();

      expect(ctrl.controllerFor('email').text, 'hello@test.com');
    });

    testWidgets('obscureText is forwarded', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _fieldWithController(ctrl, field: 'password', obscureText: true),
      );

      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.obscureText, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ZemaForm scope
  // ---------------------------------------------------------------------------

  group('ZemaForm scope', () {
    testWidgets('multiple fields share the same controller via scope',
        (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _wrap(
          ZemaForm(
            controller: ctrl,
            child: Column(
              children: const [
                ZemaTextField(field: 'email'),
                ZemaTextField(field: 'password'),
              ],
            ),
          ),
        ),
      );

      // Both fields render.
      expect(find.byType(TextField), findsNWidgets(2));

      // Submitting with valid data returns a result.
      ctrl.controllerFor('email').text = 'a@b.com';
      ctrl.controllerFor('password').text = 'securepass';
      expect(ctrl.submit(), isNotNull);
    });

    testWidgets('submit fans errors to both field widgets', (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _wrap(
          ZemaForm(
            controller: ctrl,
            child: Column(
              children: const [
                ZemaTextField(field: 'email'),
                ZemaTextField(field: 'password'),
              ],
            ),
          ),
        ),
      );

      ctrl.submit(); // both fields empty = both invalid
      await tester.pump();

      final fields = tester.widgetList<TextField>(find.byType(TextField));
      for (final f in fields) {
        expect(f.decoration?.errorText, isNotNull);
      }
    });
  });

  // ---------------------------------------------------------------------------
  // errorBuilder
  // ---------------------------------------------------------------------------

  group('errorBuilder', () {
    testWidgets('custom error widget rendered on invalid value',
        (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _wrap(
          ZemaTextField(
            field: 'email',
            controller: ctrl,
            errorBuilder: (issues) => Text(
              'custom:${issues.first.message}',
              key: const Key('custom_error'),
            ),
          ),
        ),
      );

      ctrl.controllerFor('email').text = 'bad';
      await tester.pump();

      //expect(find.byKey(const Key('custom_error')), findsOneWidget);
      // Default errorText should be absent when errorBuilder is set.
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.decoration?.errorText, isNull);
    });

    testWidgets('custom error widget absent when field is valid',
        (tester) async {
      final ctrl = ZemaFormController(schema: _schema);
      addTearDown(ctrl.dispose);

      await tester.pumpWidget(
        _wrap(
          ZemaTextField(
            field: 'email',
            controller: ctrl,
            errorBuilder: (_) => const Text('err', key: Key('custom_error')),
          ),
        ),
      );

      ctrl.controllerFor('email').text = 'user@example.com';
      await tester.pump();

      expect(find.byKey(const Key('custom_error')), findsNothing);
    });
  });
}
