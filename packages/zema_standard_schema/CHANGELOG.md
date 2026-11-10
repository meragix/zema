## 0.2.0

- Requires `zema: ^0.7.0`.
- SDK constraint raised to `>=3.8.0`, the minimum already required by `standard_schema`.
- Added a pub.dev example (`example/main.dart`).

## 0.1.0

### Added

- `ZemaStandardAdapter` class that wraps a `ZemaSchema` as a `StandardSchemaV1`
- `ZemaStandardSchemaExtension` extension with `.asStandard` getter on `ZemaSchema`
- `zemaIssueToStandard()` function to map a single `ZemaIssue` to a `StandardIssue`
- `zemaIssuesToStandard()` function to map a list of `ZemaIssue`s, filtering out warnings
- Full test suite with 12 tests covering adapter, extension, and issue mapping
