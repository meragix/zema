import 'package:meta/meta.dart';

/// Function signature for custom error message generators
typedef ZemaErrorMapFunc = String? Function(ZemaIssue issue, ZemaErrorContext ctx);

/// Context provided to error map functions
@immutable
final class ZemaErrorContext {
  /// The default message that would be used
  final String defaultMessage;

  /// Error code
  final String code;

  /// Metadata from the issue
  final Map<String, dynamic>? meta;

  const ZemaErrorContext({
    required this.defaultMessage,
    required this.code,
    this.meta,
  });
}

/// Global error map registry
class ZemaErrorMap {
  static ZemaErrorMapFunc? _globalErrorMap;
  static String _locale = 'en';

  /// Set global error map function
  static void setErrorMap(ZemaErrorMapFunc errorMap) {
    _globalErrorMap = errorMap;
  }

  /// Clear global error map
  static void clearErrorMap() {
    _globalErrorMap = null;
  }

  /// Set global locale
  static void setLocale(String locale) {
    _locale = locale;
  }

  /// Get current locale
  static String get locale => _locale;

  /// Apply error map to an issue
  static ZemaIssue applyErrorMap(ZemaIssue issue) {
    if (_globalErrorMap == null) return issue;

    final ctx = ZemaErrorContext(
      defaultMessage: issue.message,
      code: issue.code,
      meta: issue.meta,
    );

    final customMessage = _globalErrorMap!(issue, ctx);
    if (customMessage == null) return issue;

    return issue.withMessage(customMessage);
  }
}