import 'dart:async';

import 'package:standard_schema/standard_schema.dart';
import 'package:zema/zema.dart';

import 'issue_mapper.dart';

/// Wraps a [ZemaSchema] and exposes it as a [StandardSchemaV1].
///
/// Use [ZemaStandardSchemaExtension.asStandard] or construct
/// [ZemaStandardAdapter] directly to bridge any Zema schema into a
/// Standard Schema consumer (e.g. Mamba CLI, a form library).
///
/// ```dart
/// import 'package:zema/zema.dart';
/// import 'package:zema_standard_schema/zema_standard_schema.dart';
///
/// final schema = z.string().email().min(3);
/// final adapter = schema.asStandard;
///
/// // Use with Mamba or any StandardSchemaV1-aware consumer:
/// final result = adapter.standard.validate('not-an-email');
/// ```
final class ZemaStandardAdapter<Input, Output>
    implements StandardSchemaV1<Input, Output> {
  /// Creates an adapter wrapping [schema] as a [StandardSchemaV1].
  const ZemaStandardAdapter(this._schema);

  final ZemaSchema<Input, Output> _schema;

  @override
  StandardSchemaPropsV1<Input, Output> get standard =>
      StandardSchemaPropsV1<Input, Output>(
        vendor: 'zema',
        validate: _validate,
      );

  FutureOr<StandardResult<Output>> _validate(
    Object? value, [
    StandardValidateOptions? _,
  ]) {
    final result = _schema.safeParse(value as Input);
    return switch (result) {
      ZemaSuccess<Output>(:final value) => StandardSuccess(value),
      ZemaFailure<Output>(:final errors) =>
        StandardFailure<Output>(zemaIssuesToStandard(errors)),
    };
  }
}

/// Extension that bridges any [ZemaSchema] to [StandardSchemaV1].
///
/// Adds a single zero-overhead getter [asStandard] so existing Zema
/// schemas can be consumed by Standard Schema-aware tools without any
/// code change to the schema definition itself.
extension ZemaStandardSchemaExtension<I, O> on ZemaSchema<I, O> {
  /// Returns this schema wrapped as a [StandardSchemaV1<I, O>].
  ///
  /// No validation logic is duplicated, calls are forwarded to [safeParse].
  StandardSchemaV1<I, O> get asStandard => ZemaStandardAdapter<I, O>(this);
}
