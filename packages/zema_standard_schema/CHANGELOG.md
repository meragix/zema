## 0.1.0

### Added

- `ZemaStandardAdapter` class that wraps a `ZemaSchema` as a `StandardSchemaV1`
- `ZemaStandardSchemaExtension` extension with `.asStandard` getter on `ZemaSchema`
- `zemaIssueToStandard()` function to map a single `ZemaIssue` to a `StandardIssue`
- `zemaIssuesToStandard()` function to map a list of `ZemaIssue`s, filtering out warnings
- Full test suite with 12 tests covering adapter, extension, and issue mapping
