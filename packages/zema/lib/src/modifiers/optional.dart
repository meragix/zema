import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

final class OptionalSchema<I, O> extends ZemaSchema<I?, O?> {
  final ZemaSchema<I, O> base;

  const OptionalSchema(this.base);

  @override
  ZemaResult<O?> safeParse(I? value) {
    if (value == null) return success(null);
    return base.safeParse(value);
  }

  @override
  Future<ZemaResult<O?>> safeParseAsync(I? value) async {
    if (value == null) return success(null);
    return base.safeParseAsync(value);
  }
}
