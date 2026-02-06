
/// Base schema interface with full type propagation
abstract class ZemaSchema<Input, Output> {
  const ZSchema();

  Output parse(Input value) {
    final result = safeParse(value);
    if (result.$2 != null) throw result.$2!;
    return result.$1!;
  }

  ZemaResult<Output> safeParse(Input value);
}