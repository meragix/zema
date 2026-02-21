import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

final class DefaultSchema<I, O> extends ZemaSchema<I?, O> {
  final ZemaSchema<I, O> base;
  final O defaultValue;

  const DefaultSchema(this.base, this.defaultValue);

  @override
  ZemaResult<O> safeParse(I? value) {
    if (value == null) return success(defaultValue);

    final result = base.safeParse(value);
    if (result.isFailure) return success(defaultValue);

    return result;
  }
}
