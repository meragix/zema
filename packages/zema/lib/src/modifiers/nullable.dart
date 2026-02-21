import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

final class NullableSchema<I, O> extends ZemaSchema<I?, O?> {
  final ZemaSchema<I, O> base;

  const NullableSchema(this.base);

  @override
  ZemaResult<O?> safeParse(I? value) {
    if (value == null) return failure([]);
    return base.safeParse(value);
  }
}
