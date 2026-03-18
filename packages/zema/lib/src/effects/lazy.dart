import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

/// A schema that defers construction of its inner schema to the first parse
/// call, breaking circular dependencies caused by self-referential types.
///
/// Created by [Zema.lazy] — do not instantiate directly.
///
/// ## Why lazy is needed
///
/// Schemas are eagerly evaluated. A tree node schema that contains an array
/// of itself would require `nodeSchema` to exist before it is assigned,
/// which causes a runtime error:
///
/// ```dart
/// // ✗ Circular dependency — nodeSchema referenced before it is assigned
/// final nodeSchema = z.object({
///   'value':    z.integer(),
///   'children': z.array(nodeSchema),
/// });
/// ```
///
/// Wrapping the reference in a lambda defers its resolution to parse time:
///
/// ```dart
/// // ✓ Correct
/// late final ZemaSchema<dynamic, dynamic> nodeSchema;
///
/// nodeSchema = z.object({
///   'value':    z.integer(),
///   'children': z.array(z.lazy(() => nodeSchema)).optional(),
/// });
/// ```
///
/// ## Caching
///
/// The factory function is called exactly once — on the first [safeParse].
/// The resolved schema is cached and reused for every subsequent call.
///
/// ## Async limitation
///
/// [LazySchema] does not override [ZemaSchema.safeParseAsync]. The base
/// implementation delegates to [safeParse], so async refinements on the inner
/// schema will not run through a lazy wrapper. Apply `.refineAsync()` outside
/// the lazy boundary if async validation is needed.
///
/// See also:
/// - [Zema.lazy] — the factory method that constructs this schema.
final class LazySchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> Function() _fn;
  ZemaSchema<I, O>? _cached;

  LazySchema(this._fn);

  ZemaSchema<I, O> get _schema => _cached ??= _fn();

  @override
  ZemaResult<O> safeParse(I value) => _schema.safeParse(value);
}
