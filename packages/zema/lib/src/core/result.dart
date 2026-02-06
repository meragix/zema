import 'package:zema/src/error/exception.dart';
import 'package:zema/src/error/issue.dart';

/// Extension type wrapper over (T?, List&lt;ZemaIssue&gt;?) record
///
/// Provides utility getters without allocating additional objects.
/// This is a compile-time only wrapper with ZERO runtime cost.
extension type ZemaResult<T>._((T?, List<ZemaIssue>?) _record) {
  /// Create a success result
  ZemaResult.success(T data) : this._((data, null));

  /// Create a failure result
  ZemaResult.failure(List<ZemaIssue> issues) : this._((null, issues));

  /// The validated data (null if validation failed)
  T? get data => _record.$1;

  /// The list of validation issues (null if validation succeeded)
  List<ZemaIssue>? get issues => _record.$2;

  /// Whether validation succeeded
  bool get isSuccess => _record.$2 == null;

  /// Whether validation failed
  bool get isFailure => _record.$2 != null;

  /// Whether there are any issues
  bool get hasIssues => _record.$2 != null && _record.$2!.isNotEmpty;

  /// Get data or throw exception
  T get dataOrThrow {
    if (_record.$2 != null) {
      throw ZemaException(_record.$2!);
    }
    return _record.$1 as T;
  }

  /// Get data or return default value
  T dataOr(T defaultValue) => _record.$1 ?? defaultValue;

  /// Access the underlying record (for pattern matching)
  (T?, List<ZemaIssue>?) get asRecord => _record;
}

ZemaResult<T> _success<T>(T data) => ZemaResult.success(data);
ZemaResult<T> _failure<T>(List<ZemaIssue> issues) => ZemaResult.failure(issues);
ZemaResult<T> _singleFailure<T>(ZemaIssue issue) => ZemaResult.failure([issue]);
