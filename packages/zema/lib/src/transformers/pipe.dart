import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';

/// A schema that chains two schemas in sequence: [first] validates the raw
/// input, then [second] validates [first]'s output.
///
/// Created by calling [ZemaSchema.pipe] on any schema — do not instantiate
/// directly.
///
/// ## Behaviour
///
/// 1. [first] validates input [I] → [M].
/// 2. If [first] fails, its errors are returned immediately — [second] is
///    never called.
/// 3. If [first] succeeds, its output [M] is passed as input to [second].
/// 4. [second] validates [M] → [O] and its result (success or failure) is
///    returned as the final result.
///
/// ## Type parameters
///
/// - [I] — raw input type accepted by [first].
/// - [M] — intermediate type: output of [first] and input of [second].
/// - [O] — final output type produced by [second].
///
/// ## Async behaviour
///
/// In [safeParseAsync], [first] is awaited via `safeParseAsync`. [second] is
/// then called synchronously via `safeParse` — if [second] also needs async
/// execution, chain another `.pipe()` or override `safeParseAsync` on it.
///
/// ## Examples
///
/// ```dart
/// // Parse a string, coerce to int, then apply range validation
/// z.string()
///     .transform(int.parse)         // String → int (or transform_error)
///     .pipe(z.int().gte(0).lte(100));
///
/// // Validate a raw string is a number string, then parse it
/// z.string().regex(RegExp(r'^\d+$'))
///     .pipe(z.coerce().integer());
/// ```
///
/// ## pipe vs transform
///
/// Use [ZemaSchema.transform] when you only need to map the output value
/// to a new type with no further validation. Use [pipe] when the intermediate
/// value needs to pass through a full schema with its own validation rules.
///
/// See also:
/// - [ZemaSchema.pipe] — the fluent API method that constructs this.
/// - [TransformedSchema] — simpler one-step output mapping.
/// - [PreprocessedSchema] — transforms the *input* before the first schema runs.
final class PipedSchema<I, M, O> extends ZemaSchema<I, O> {
  /// The first schema — validates [I] and produces [M].
  final ZemaSchema<I, M> first;

  /// The second schema — validates [M] (output of [first]) and produces [O].
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
