import 'package:meta/meta.dart';
import 'package:zema/src/error/issue.dart';

/// Result of a Zema validation.
///
/// Use pattern matching to handle success/failure:
/// ```dart
/// final result = userSchema.parse(json);
///
/// switch (result) {
///   case ZemaSuccess(:final value):
///     print('Valid user: $value');
///   case ZemaFailure(:final errors):
///     print('Errors: $errors');
/// }
/// ```
sealed class ZemaResult<T> {
  const ZemaResult();

  /// Whether validation succeeded.
  bool get isSuccess => this is ZemaSuccess<T>;

  /// Whether validation failed.
  bool get isFailure => this is ZemaFailure<T>;

  /// Get value (throws if failure).
  T get value => switch (this) {
        ZemaSuccess(value: final v) => v,
        ZemaFailure() =>
          throw StateError('Cannot get value from failed result'),
      };

  /// Get errors (empty list if success).
  List<ZemaIssue> get errors => switch (this) {
        ZemaSuccess() => const [],
        ZemaFailure(errors: final e) => e,
      };

  /// Transform to other type (only for success).
  ///
  /// ```dart
  /// final user = result.mapTo((map) => User.fromJson(map));
  /// ```
  ZemaResult<R> mapTo<R>(R Function(Map<String, dynamic>) mapper) {
    return switch (this) {
      ZemaSuccess(value: final v) => ZemaSuccess(_mapValue(v, mapper)),
      ZemaFailure(errors: final e) => ZemaFailure(e),
    };
  }

  R mapToOrElse<R>(
    R Function(Map<String, dynamic>) mapper, {
    required R Function(List<ZemaIssue>) onError,
  }) {
    return switch (this) {
      ZemaSuccess(value: final v) => _mapValue(v, mapper),
      ZemaFailure(errors: final e) => onError(e),
    };
  }

  R? mapToOrNull<R>(R Function(Map<String, dynamic>) mapper) {
    return switch (this) {
      ZemaSuccess(value: final v) => _mapValue(v, mapper),
      ZemaFailure() => null,
    };
  }

  R _mapValue<R>(dynamic value, R Function(Map<String, dynamic>) mapper) {
    if (value is Map<String, dynamic>) return mapper(value);
    if (value is Map) return mapper(Map<String, dynamic>.from(value));
    throw StateError('Cannot map non-Map value: ${value.runtimeType}');
  }

  void onSuccess(void Function(T) action) {
    if (this case ZemaSuccess(value: final v)) action(v);
  }

  void onError(void Function(List<ZemaIssue>) action) {
    if (this case ZemaFailure(errors: final e)) action(e);
  }

  R when<R>({
    required R Function(T value) success,
    required R Function(List<ZemaIssue> errors) failure,
  }) {
    return switch (this) {
      ZemaSuccess(value: final v) => success(v),
      ZemaFailure(errors: final e) => failure(e),
    };
  }

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
}

/// Success result.
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

/// Failure result.
@immutable
final class ZemaFailure<T> extends ZemaResult<T> {
  @override
  final List<ZemaIssue> errors;

  const ZemaFailure(this.errors);

  /// Create a failure with a single issue.
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

/// Create a success result.
ZemaResult<T> success<T>(T value) => ZemaSuccess(value);

/// Create a failure result with multiple issues.
ZemaResult<T> failure<T>(List<ZemaIssue> errors) => ZemaFailure(errors);

/// Create a failure result with a single issue.
ZemaResult<T> singleFailure<T>(ZemaIssue issue) => ZemaFailure.single(issue);
