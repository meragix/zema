import 'package:standard_schema/standard_schema.dart';
import 'package:zema/zema.dart';

/// Maps a [ZemaIssue] to a [StandardIssue].
///
/// Only [message] and [path] are part of the Standard Schema V1 spec.
/// Zema-specific fields ([code], [receivedValue], [meta]) are not projected
/// because the upstream contract does not define them.
StandardIssue zemaIssueToStandard(ZemaIssue issue) {
  return StandardIssue(
    message: issue.message,
    path: issue.path,
  );
}

/// Maps a list of [ZemaIssue]s to [StandardIssue]s,
/// filtering out warning-level issues (non-blocking in Zema).
List<StandardIssue> zemaIssuesToStandard(List<ZemaIssue> issues) {
  return issues
      .where((i) => i.severity == ZemaSeverity.error)
      .map(zemaIssueToStandard)
      .toList(growable: false);
}
