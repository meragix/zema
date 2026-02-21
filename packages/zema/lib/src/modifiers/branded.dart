import 'package:meta/meta.dart';
import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

extension ZSchemaBranding<I, O> on ZemaSchema<I, O> {
  ZemaSchema<I, Branded<O, B>> brand<B>() => BrandedSchema<I, O, B>(this);
}

/// Branded type wrapper (zero runtime cost via extension type in Dart 3.3+)
@immutable
final class Branded<T, Brand> {
  final T value;
  const Branded(this.value);

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Branded<T, Brand> && value == other.value);

  @override
  int get hashCode => value.hashCode;
}

final class BrandedSchema<I, O, B> extends ZemaSchema<I, Branded<O, B>> {
  final ZemaSchema<I, O> base;

  const BrandedSchema(this.base);

  @override
  ZemaResult<Branded<O, B>> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return failure(result.errors);
    return success(Branded(result.value));
  }
}
