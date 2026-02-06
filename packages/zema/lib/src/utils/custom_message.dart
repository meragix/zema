import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

/// Mixin for schemas that support custom messages
mixin ZemaCustomMessage<I, O> on ZemaSchema<I, O> {
  String? get customMessage => null;

  /// Create a copy with custom message
  // ZemaSchema<I, O> withCustomMessage(String message);

  /// Apply custom message to an issue if set
  ZemaIssue applyCustomMessage(ZemaIssue issue) {
    if (customMessage == null) return issue;
    return issue.withMessage(customMessage!);
  }
}
