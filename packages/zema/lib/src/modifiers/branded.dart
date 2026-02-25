import 'package:meta/meta.dart';
import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

/// Extension that adds [brand] to every [ZemaSchema].
///
/// Call `.brand<B>()` on any schema to wrap its output in a [Branded] type,
/// distinguishing it from other schemas that produce the same underlying type.
///
/// See [Branded] for full documentation and usage examples.
extension ZSchemaBranding<I, O> on ZemaSchema<I, O> {
  /// Wraps the output of this schema in [Branded]`<O, B>`, applying nominal
  /// typing to an otherwise structurally identical type.
  ///
  /// See [Branded] for details.
  ZemaSchema<I, Branded<O, B>> brand<B>() => BrandedSchema<I, O, B>(this);
}

/// A nominally-typed wrapper that distinguishes values at compile time even
/// when the underlying type is the same.
///
/// Dart uses **structural** typing — two values of type `String` are
/// interchangeable regardless of what they represent. [Branded] adds a
/// phantom [Brand] type parameter that the compiler treats as distinct,
/// preventing accidental mixing of semantically different values:
///
/// ```dart
/// // Two abstract marker classes — never instantiated
/// abstract class _UserIdBrand {}
/// abstract class _TeamIdBrand {}
///
/// // Two branded schemas that both validate strings
/// final userIdSchema = z.string().uuid().brand<_UserIdBrand>();
/// final teamIdSchema = z.string().uuid().brand<_TeamIdBrand>();
///
/// final userId = userIdSchema.parse('550e8400-…');
/// // userId is Branded<String, _UserIdBrand>
///
/// final teamId = teamIdSchema.parse('660f9511-…');
/// // teamId is Branded<String, _TeamIdBrand>
///
/// // Compiler error — cannot pass a team ID where a user ID is expected
/// void greet(Branded<String, _UserIdBrand> id) { … }
/// greet(teamId); // compile-time error!
/// ```
///
/// ## Runtime cost
///
/// [Branded] is a thin `@immutable` wrapper with no allocations beyond the
/// wrapper object itself. Equality, hash code, and `toString` all delegate
/// directly to [value].
///
/// ## Unwrapping
///
/// Access the raw value via [value]:
///
/// ```dart
/// final userId = userIdSchema.parse(rawString);
/// db.fetchUser(userId.value); // String
/// ```
///
/// See also:
/// - [ZSchemaBranding.brand] — the extension method that produces this wrapper.
/// - [BrandedSchema] — the internal schema implementation.
@immutable
final class Branded<T, Brand> {
  /// The underlying validated value.
  final T value;

  const Branded(this.value);

  @override
  String toString() => value.toString();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Branded<T, Brand> && value == other.value);

  @override
  int get hashCode => value.hashCode;
}

/// Internal schema that validates with [base] and wraps the output in
/// [Branded]`<O, B>`.
///
/// Constructed by [ZSchemaBranding.brand] — do not instantiate directly.
final class BrandedSchema<I, O, B> extends ZemaSchema<I, Branded<O, B>> {
  /// The underlying schema whose output is wrapped.
  final ZemaSchema<I, O> base;

  const BrandedSchema(this.base);

  @override
  ZemaResult<Branded<O, B>> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return failure(result.errors);
    return success(Branded(result.value));
  }
}
