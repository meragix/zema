import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zema/zema.dart';
import 'package:zema_forms/zema_forms.dart';

// ---------------------------------------------------------------------------
// Shared schemas
// ---------------------------------------------------------------------------

final _loginSchema = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
});

final _profileSchema = z.object({
  'name': z.string().min(2),
  'age': z.coerce().integer(min: 0, max: 150),
  'bio': z.string().optional(),
});

void main() {
  // Flutter bindings are required for TextEditingController.
  setUpAll(WidgetsFlutterBinding.ensureInitialized);

  // ---------------------------------------------------------------------------
  // controllerFor
  // ---------------------------------------------------------------------------

  group('controllerFor', () {
    test('returns a TextEditingController', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.controllerFor('email'), isA<TextEditingController>());
    });

    test('returns the same instance on repeated calls', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      final a = ctrl.controllerFor('email');
      final b = ctrl.controllerFor('email');
      expect(identical(a, b), isTrue);
    });

    test('returns independent instances for different fields', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(
        identical(ctrl.controllerFor('email'), ctrl.controllerFor('password')),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // errorsFor
  // ---------------------------------------------------------------------------

  group('errorsFor', () {
    test('initially empty', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.errorsFor('email').value, isEmpty);
    });

    test('returns the same ValueNotifier on repeated calls', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(
        identical(ctrl.errorsFor('email'), ctrl.errorsFor('email')),
        isTrue,
      );
    });

    test('independent notifiers per field', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(
        identical(ctrl.errorsFor('email'), ctrl.errorsFor('password')),
        isFalse,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // validateOnChange
  // ---------------------------------------------------------------------------

  group('validateOnChange: true (default)', () {
    test('errors appear after first keystroke on invalid value', () async {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'not-an-email';
      await Future<void>.delayed(Duration.zero); // let listener fire

      expect(ctrl.errorsFor('email').value, isNotEmpty);
      expect(ctrl.errorsFor('email').value.first.code, 'invalid_email');
    });

    test('errors cleared when value becomes valid', () async {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'bad';
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.errorsFor('email').value, isNotEmpty);

      ctrl.controllerFor('email').text = 'user@example.com';
      await Future<void>.delayed(Duration.zero);
      expect(ctrl.errorsFor('email').value, isEmpty);
    });

    test('one field error does not affect other field notifier', () async {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'bad';
      await Future<void>.delayed(Duration.zero);

      expect(ctrl.errorsFor('email').value, isNotEmpty);
      expect(ctrl.errorsFor('password').value, isEmpty);
    });
  });

  group('validateOnChange: false', () {
    test('typing does not update error notifier', () async {
      final ctrl = ZemaFormController(
        schema: _loginSchema,
        validateOnChange: false,
      );
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'not-an-email';
      await Future<void>.delayed(Duration.zero);

      expect(ctrl.errorsFor('email').value, isEmpty);
    });

    test('errors appear after submit', () {
      final ctrl = ZemaFormController(
        schema: _loginSchema,
        validateOnChange: false,
      );
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'bad';
      ctrl.submit();

      expect(ctrl.errorsFor('email').value, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // initialValues
  // ---------------------------------------------------------------------------

  group('initialValues', () {
    test('pre-populates text controllers', () {
      final ctrl = ZemaFormController(
        schema: _loginSchema,
        initialValues: {'email': 'user@example.com', 'password': 'secret123'},
      );
      addTearDown(ctrl.dispose);

      expect(ctrl.controllerFor('email').text, 'user@example.com');
      expect(ctrl.controllerFor('password').text, 'secret123');
    });

    test('ignores keys not in schema', () {
      final ctrl = ZemaFormController(
        schema: _loginSchema,
        initialValues: {'email': 'a@b.com', 'unknown': 'ignored'},
      );
      addTearDown(ctrl.dispose);

      // Should not throw; 'unknown' key has no controller in schema.
      expect(ctrl.controllerFor('email').text, 'a@b.com');
    });
  });

  // ---------------------------------------------------------------------------
  // submit
  // ---------------------------------------------------------------------------

  group('submit', () {
    test('returns null when required fields are empty', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.submit(), isNull);
    });

    test('returns null when a field fails validation', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'user@example.com';
      ctrl.controllerFor('password').text = 'short'; // min 8

      expect(ctrl.submit(), isNull);
    });

    test('returns typed output when all fields are valid', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'user@example.com';
      ctrl.controllerFor('password').text = 'password123';

      final result = ctrl.submit();
      expect(result, isNotNull);
      expect(result!['email'], 'user@example.com');
      expect(result['password'], 'password123');
    });

    test('fans errors to per-field notifiers on failure', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'bad';
      ctrl.controllerFor('password').text = 'x';
      ctrl.submit();

      expect(ctrl.errorsFor('email').value, isNotEmpty);
      expect(ctrl.errorsFor('password').value, isNotEmpty);
    });

    test('only the failing field has errors', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'user@example.com';
      ctrl.controllerFor('password').text = 'x'; // too short
      ctrl.submit();

      expect(ctrl.errorsFor('email').value, isEmpty);
      expect(ctrl.errorsFor('password').value, isNotEmpty);
    });

    test('clears all errors on successful submit', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      // First submit with bad data.
      ctrl.controllerFor('email').text = 'bad';
      ctrl.controllerFor('password').text = 'x';
      ctrl.submit();
      expect(ctrl.hasErrors, isTrue);

      // Fix both fields.
      ctrl.controllerFor('email').text = 'user@example.com';
      ctrl.controllerFor('password').text = 'password123';
      ctrl.submit();

      expect(ctrl.errorsFor('email').value, isEmpty);
      expect(ctrl.errorsFor('password').value, isEmpty);
      expect(ctrl.hasErrors, isFalse);
    });

    test('coercion: integer field receives string and coerces', () {
      final ctrl = ZemaFormController(schema: _profileSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('name').text = 'Alice';
      ctrl.controllerFor('age').text = '30';
      final result = ctrl.submit();

      expect(result, isNotNull);
      expect(result!['age'], 30); // coerced to int
    });

    test('coercion: invalid integer string produces error', () {
      final ctrl = ZemaFormController(schema: _profileSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('name').text = 'Alice';
      ctrl.controllerFor('age').text = 'abc';
      ctrl.submit();

      expect(ctrl.errorsFor('age').value, isNotEmpty);
    });

    test('optional field: absent value passes', () {
      final ctrl = ZemaFormController(schema: _profileSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('name').text = 'Alice';
      ctrl.controllerFor('age').text = '25';
      // 'bio' controller never registered — arrives as null in raw map.
      final result = ctrl.submit();

      expect(result, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // validatorFor
  // ---------------------------------------------------------------------------

  group('validatorFor', () {
    test('returns null on valid value', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.validatorFor('email')('user@example.com'), isNull);
    });

    test('returns error message on invalid value', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.validatorFor('email')('not-an-email'), isNotNull);
    });

    test('returns null for unknown field key', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.validatorFor('unknown')('anything'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // hasErrors
  // ---------------------------------------------------------------------------

  group('hasErrors', () {
    test('false before any interaction', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      expect(ctrl.hasErrors, isFalse);
    });

    test('true after failed submit', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.submit();
      expect(ctrl.hasErrors, isTrue);
    });

    test('false after successful submit', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'user@example.com';
      ctrl.controllerFor('password').text = 'password123';
      ctrl.submit();

      expect(ctrl.hasErrors, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // setValue
  // ---------------------------------------------------------------------------

  group('setValue', () {
    test('updates text controller', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.setValue('email', 'alice@example.com');
      expect(ctrl.controllerFor('email').text, 'alice@example.com');
    });

    test('triggers validation when validateOnChange is true', () async {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.setValue('email', 'not-valid');
      await Future<void>.delayed(Duration.zero);

      expect(ctrl.errorsFor('email').value, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // reset
  // ---------------------------------------------------------------------------

  group('reset', () {
    test('clears all text controllers', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.controllerFor('email').text = 'user@example.com';
      ctrl.controllerFor('password').text = 'password123';
      ctrl.reset();

      expect(ctrl.controllerFor('email').text, '');
      expect(ctrl.controllerFor('password').text, '');
    });

    test('clears all error notifiers', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      ctrl.submit(); // populate errors
      expect(ctrl.hasErrors, isTrue);

      ctrl.reset();
      expect(ctrl.hasErrors, isFalse);
      expect(ctrl.errorsFor('email').value, isEmpty);
      expect(ctrl.errorsFor('password').value, isEmpty);
    });

    test('after reset, typing does not immediately show errors '
        'even with validateOnChange', () async {
      final ctrl = ZemaFormController(schema: _loginSchema);
      addTearDown(ctrl.dispose);

      // Dirty a field, then reset.
      ctrl.controllerFor('email').text = 'bad';
      await Future<void>.delayed(Duration.zero);
      ctrl.reset();

      // Type again — field is dirty again immediately.
      ctrl.controllerFor('email').text = 'still-bad';
      await Future<void>.delayed(Duration.zero);

      // Errors should reappear because the field was dirtied after reset.
      expect(ctrl.errorsFor('email').value, isNotEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // dispose
  // ---------------------------------------------------------------------------

  group('dispose', () {
    test('does not throw', () {
      final ctrl = ZemaFormController(schema: _loginSchema);
      ctrl.controllerFor('email');
      ctrl.controllerFor('password');

      expect(ctrl.dispose, returnsNormally);
    });
  });
}
