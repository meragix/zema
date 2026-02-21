import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

final class LazySchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> Function() _fn;
  ZemaSchema<I, O>? _cached;

  LazySchema(this._fn);

  ZemaSchema<I, O> get _schema => _cached ??= _fn();

  @override
  ZemaResult<O> safeParse(I value) => _schema.safeParse(value);
}
