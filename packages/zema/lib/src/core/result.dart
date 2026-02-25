import 'package:meta/meta.dart';
import 'package:zema/src/error/issue.dart';

/// The result of a Zema validation — either a success or a failure.
///
/// [ZemaResult] is a sealed type with exactly two variants:
/// - [ZemaSuccess] — validation passed; holds the validated [T] value.
/// - [ZemaFailure] — validation failed; holds one or more [ZemaIssue]s.
///
/// ## Pattern matching (recommended)
///
/// ```dart
/// final result = userSchema.safeParse(json);
///
/// switch (result) {
///   case ZemaSuccess(:final value):
///     saveToDatabase(value);
///   case ZemaFailure(:final errors):
///     for (final issue in errors) {
///       print('${issue.pathString}: ${issue.message}');
///     }
/// }
/// ```
///
/// ## Functional style
///
/// Use [when] for an exhaustive, expression-oriented handler:
///
/// ```dart
/// final message = result.when(
///   success: (value) => 'Hello, ${value['name']}!',
///   failure: (errors) => 'Error: ${errors.first.message}',
/// );
/// ```
///
/// Use [onSuccess] / [onError] for isolated side effects:
///
/// ```dart
/// result
///   ..onSuccess((v) => cache.store(v))
///   ..onError((e)  => logger.warn(e));
/// ```
///
/// ## Mapping to a typed model
///
/// When [T] is `Map<String, dynamic>` (the default output of [ZemaObject]),
/// use [mapTo] to convert it to a typed class without unwrapping manually:
///
/// ```dart
/// final user = result.mapTo(User.fromJson);
/// // user is ZemaResult<User>
/// ```
///
/// See also:
/// - [ZemaSuccess] — the success variant.
/// - [ZemaFailure] — the failure variant.
/// - [success], [failure], [singleFailure] — factory helpers for schema authors.
sealed class ZemaResult<T> {
  const ZemaResult();

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  /// `true` when this result is a [ZemaSuccess].
  bool get isSuccess => this is ZemaSuccess<T>;

  /// `true` when this result is a [ZemaFailure].
  bool get isFailure => this is ZemaFailure<T>;

  // ---------------------------------------------------------------------------
  // Accessors
  // ---------------------------------------------------------------------------

  /// The validated value.
  ///
  /// Throws a [StateError] when called on a [ZemaFailure]. Prefer pattern
  /// matching or [when] over accessing this property directly to avoid
  /// runtime errors.
  ///
  /// ```dart
  /// if (result.isSuccess) {
  ///   print(result.value); // safe here
  /// }
  /// ```
  T get value => switch (this) {
        ZemaSuccess(value: final v) => v,
        ZemaFailure() =>
          throw StateError('Cannot get value from a failed ZemaResult.'),
      };

  /// The list of validation issues.
  ///
  /// Returns an empty list when called on a [ZemaSuccess]. Never returns `null`.
  ///
  /// ```dart
  /// if (result.isFailure) {
  ///   print(result.errors.length); // number of issues
  /// }
  /// ```
  List<ZemaIssue> get errors => switch (this) {
        ZemaSuccess() => const [],
        ZemaFailure(errors: final e) => e,
      };

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  /// Maps a successful `Map<String, dynamic>` value to a typed model [R].
  ///
  /// Passes the validated map to [mapper] and wraps the result in a new
  /// [ZemaSuccess]. If this result is a [ZemaFailure], the errors are
  /// forwarded unchanged and [mapper] is never called.
  ///
  /// Throws a [StateError] if [T] is not a `Map` type.
  ///
  /// ```dart
  /// final result = userSchema.safeParse(json).mapTo(User.fromJson);
  /// // result is ZemaResult<User>
  /// ```
  ///
  /// See also:
  /// - [mapToOrNull] — returns `null` on failure instead of a [ZemaFailure].
  /// - [mapToOrElse] — lets you provide an explicit fallback on failure.
  ZemaResult<R> mapTo<R>(R Function(Map<String, dynamic>) mapper) {
    return switch (this) {
      ZemaSuccess(value: final v) => ZemaSuccess(_mapValue(v, mapper)),
      ZemaFailure(errors: final e) => ZemaFailure(e),
    };
  }

  /// Maps a successful `Map<String, dynamic>` value to [R], or calls
  /// [onError] with the issues on failure.
  ///
  /// Unlike [mapTo], this unwraps the result entirely and returns a plain [R]
  /// — useful when you want to fold both branches into a single value without
  /// keeping the [ZemaResult] wrapper.
  ///
  /// ```dart
  /// final dto = result.mapToOrElse(
  ///   UserDto.fromJson,
  ///   onError: (issues) => UserDto.empty(),
  /// );
  /// ```
  ///
  /// See also:
  /// - [mapTo] — keeps the [ZemaResult] wrapper on failure.
  /// - [mapToOrNull] — returns `null` on failure.
  R mapToOrElse<R>(
    R Function(Map<String, dynamic>) mapper, {
    required R Function(List<ZemaIssue>) onError,
  }) {
    return switch (this) {
      ZemaSuccess(value: final v) => _mapValue(v, mapper),
      ZemaFailure(errors: final e) => onError(e),
    };
  }

  /// Maps a successful `Map<String, dynamic>` value to [R], or returns `null`
  /// on failure.
  ///
  /// A convenient shorthand when you simply want `null` instead of an
  /// explicit failure branch.
  ///
  /// ```dart
  /// final user = result.mapToOrNull(User.fromJson);
  /// if (user != null) { ... }
  /// ```
  ///
  /// See also:
  /// - [mapTo] — preserves the failure variant.
  /// - [mapToOrElse] — provides a custom fallback on failure.
  R? mapToOrNull<R>(R Function(Map<String, dynamic>) mapper) {
    return switch (this) {
      ZemaSuccess(value: final v) => _mapValue(v, mapper),
      ZemaFailure() => null,
    };
  }

  // ---------------------------------------------------------------------------
  // Side effects
  // ---------------------------------------------------------------------------

  /// Calls [action] with the validated value if this is a [ZemaSuccess];
  /// does nothing on [ZemaFailure].
  ///
  /// Returns `void` — intended for side effects such as logging or caching.
  ///
  /// ```dart
  /// result.onSuccess((user) => cache.put('user', user));
  /// ```
  void onSuccess(void Function(T) action) {
    if (this case ZemaSuccess(value: final v)) action(v);
  }

  /// Calls [action] with the list of issues if this is a [ZemaFailure];
  /// does nothing on [ZemaSuccess].
  ///
  /// Returns `void` — intended for side effects such as logging or reporting.
  ///
  /// ```dart
  /// result.onError((issues) => analytics.report(issues));
  /// ```
  void onError(void Function(List<ZemaIssue>) action) {
    if (this case ZemaFailure(errors: final e)) action(e);
  }

  // ---------------------------------------------------------------------------
  // Exhaustive handlers
  // ---------------------------------------------------------------------------

  /// Exhaustively handles both variants and returns [R].
  ///
  /// Exactly one of [success] or [failure] is called, making this a safe
  /// alternative to manual pattern matching when you need an expression result.
  ///
  /// ```dart
  /// final label = result.when(
  ///   success: (value) => 'Valid: $value',
  ///   failure: (errors) => 'Invalid (${errors.length} issues)',
  /// );
  /// ```
  R when<R>({
    required R Function(T value) success,
    required R Function(List<ZemaIssue> errors) failure,
  }) {
    return switch (this) {
      ZemaSuccess(value: final v) => success(v),
      ZemaFailure(errors: final e) => failure(e),
    };
  }

  /// Handles one or both variants, falling back to [orElse] for unhandled cases.
  ///
  /// Unlike [when], neither [success] nor [failure] is required — pass only
  /// the handler(s) you care about and let [orElse] cover the rest.
  ///
  /// ```dart
  /// final label = result.maybeWhen(
  ///   success: (value) => 'Valid: $value',
  ///   orElse: () => 'Something went wrong',
  /// );
  /// ```
  R maybeWhen<R>({
    required R Function() orElse,
    R Function(T value)? success,
    R Function(List<ZemaIssue> errors)? failure,
  }) {
    return switch (this) {
      ZemaSuccess(value: final v) => success?.call(v) ?? orElse(),
      ZemaFailure(errors: final e) => failure?.call(e) ?? orElse(),
    };
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  R _mapValue<R>(dynamic value, R Function(Map<String, dynamic>) mapper) {
    if (value is Map<String, dynamic>) return mapper(value);
    if (value is Map) return mapper(Map<String, dynamic>.from(value));
    throw StateError(
      'mapTo requires a Map<String, dynamic> value, '
      'but got ${value.runtimeType}.',
    );
  }
}

// =============================================================================
// Variants
// =============================================================================

/// A successful [ZemaResult] holding the validated value.
///
/// Construct via [success] (preferred in schema implementations) or directly:
///
/// ```dart
/// ZemaSuccess('Alice')
/// ```
@immutable
final class ZemaSuccess<T> extends ZemaResult<T> {
  @override
  final T value;

  const ZemaSuccess(this.value);

  @override
  String toString() => 'ZemaSuccess($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ZemaSuccess<T> && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A failed [ZemaResult] holding one or more [ZemaIssue]s.
///
/// Construct via [singleFailure] (one issue) or [failure] (many issues),
/// both preferred in schema implementations, or directly:
///
/// ```dart
/// ZemaFailure([ZemaIssue(code: 'too_short', message: '...')])
/// ZemaFailure.single(ZemaIssue(code: 'invalid_type', message: '...'))
/// ```
@immutable
final class ZemaFailure<T> extends ZemaResult<T> {
  @override
  final List<ZemaIssue> errors;

  const ZemaFailure(this.errors);

  /// Creates a [ZemaFailure] wrapping a single [issue].
  ZemaFailure.single(ZemaIssue issue) : errors = [issue];

  @override
  String toString() => 'ZemaFailure($errors)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZemaFailure<T> && errors == other.errors;

  @override
  int get hashCode => errors.hashCode;
}

// =============================================================================
// Factory helpers (for use inside schema implementations)
// =============================================================================

/// Creates a [ZemaSuccess] wrapping [value].
///
/// Use this inside [ZemaSchema.safeParse] implementations to signal that
/// validation passed:
///
/// ```dart
/// @override
/// ZemaResult<String> safeParse(dynamic value) {
///   if (value is! String) return singleFailure(...);
///   return success(value);
/// }
/// ```
ZemaResult<T> success<T>(T value) => ZemaSuccess(value);

/// Creates a [ZemaFailure] wrapping a list of [errors].
///
/// Use this when a schema collects **multiple** issues before returning,
/// such as an object schema that validates every field before giving up:
///
/// ```dart
/// if (issues.isNotEmpty) return failure(issues);
/// return success(cleaned);
/// ```
ZemaResult<T> failure<T>(List<ZemaIssue> errors) => ZemaFailure(errors);

/// Creates a [ZemaFailure] wrapping a single [issue].
///
/// Use this when a schema fails fast on the first problem and there is no
/// need to collect further issues:
///
/// ```dart
/// if (value is! String) {
///   return singleFailure(ZemaIssue(
///     code: 'invalid_type',
///     message: 'Expected a string.',
///   ));
/// }
/// ```
ZemaResult<T> singleFailure<T>(ZemaIssue issue) => ZemaFailure.single(issue);
