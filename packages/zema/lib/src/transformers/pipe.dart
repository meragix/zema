import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

final class PipedSchema<I, M, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, M> first;
  final ZemaSchema<M, O> second;

  const PipedSchema(this.first, this.second);

  @override
  ZemaResult<O> safeParse(I value) {
    final firstResult = first.safeParse(value);
    if (firstResult.isFailure) return failure(firstResult.errors);

    return second.safeParse(firstResult.value);
  }

  @override
  Future<ZemaResult<O>> safeParseAsync(I value) async {
    final firstResult = await first.safeParseAsync(value);
    if (firstResult.isFailure) return failure(firstResult.errors);

    return second.safeParse(firstResult.value);
  }
}
