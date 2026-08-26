/// Standard Schema adapter for Zema.
///
/// Exports [ZemaStandardAdapter] and the [ZemaStandardSchemaExtension]
/// extension to bridge any [ZemaSchema] into a [StandardSchemaV1]-compliant
/// object usable by Standard Schema consumers (CLI frameworks, form libs, etc.).
library;

export 'src/adapter.dart';
export 'src/issue_mapper.dart' show zemaIssueToStandard, zemaIssuesToStandard;
