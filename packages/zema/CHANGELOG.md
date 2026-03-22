# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Performance

- `ZemaString`, `ZemaInt`, `ZemaDouble`: issue list is now allocated lazily; no heap allocation on the success path
- `ZemaObject`: `allIssues` list is now allocated lazily; same benefit on both success and failure paths
- `ZemaI18n`: active translations map is cached after the first lookup; locale changes still invalidate the cache automatically

## [0.5.0] - 2026-03-21

### Added

- `ZemaSeverity` enum (`error`, `warning`) and `ZemaIssue.severity` field (defaults to `error`)
- `ZemaMetaKeys`: compile-time constants for `ZemaIssue.meta` keys (`min`, `max`, `actual`, `expected`, `received`, `allowed`, `type`, `multipleOf`, `pattern`, `length`)
- `ZemaIssue.expected` (`String?`): expected type/value; populated on all built-in `invalid_type` issues
- `ZemaResult.warnings` / `ZemaResult.hasWarnings`: warning issues from a successful parse
- `ZemaSchemaRefinement.refineWarn()`: advisory refinement; parse succeeds, issue added to `warnings`
- `z.string().dateTime()`: validates ISO 8601 format; output stays `String`; produces `invalid_datetime_string`
- `z.coerce().dateTime({DateTime? after, DateTime? before})`: coerces `String`, `int` (Unix ms), or `DateTime`
- `ZemaSchema.parseInIsolate()`: offloads `safeParse()` to a background `Isolate` (built-in primitives only; closures are not isolate-sendable)
- Strict coercion mode (`strict` parameter) on all coercion schemas; see Breaking Changes for `z.coerce().string()` default
- i18n translations (en + fr) for `invalid_datetime_string` and `async_refinement_skipped`

### Changed

- `ZemaIssue` copy helpers, `operator==`, `hashCode`, and `toString()` updated for `expected` and `severity`
- `ZemaSuccess` carries a `warnings` list (`const []` by default); `success()` factory accepts optional `warnings`
- `z.coerce().boolean/integer/float` signatures gain a `strict` parameter (backward-compatible)

### Breaking Changes

- **`safeParse()` / `parse()` on async schemas** now returns `ZemaFailure(code: 'async_refinement_skipped')` instead of silently bypassing the predicate. Migrate: use `safeParseAsync()` / `parseAsync()`.
- **`z.coerce().string()`** defaults to `strict: true`: arbitrary objects now fail with `invalid_coercion`. Migrate: pass `strict: false` to restore the old behaviour.

## [0.4.0] - 2026-03-18

### Added

- `ZemaInt.nonNegative()`: accepts zero and positive integers (`value >= 0`)
- `ZemaDouble.nonNegative()`: accepts zero and positive doubles (`value >= 0.0`)
- `ZemaObject.merge()`:  merges fields from another `ZemaObject` instance (fields from the argument win on conflict)
- `ZemaUnion.discriminatedBy()` : fast-path validation using a named literal field to select the matching schema directly

### Tests

- Rewrote `object_schema_test.dart`: full coverage of `ZemaObject` including `extend()`, `merge()`, `pick()`, `omit()`, `makeStrict()`, `objectAs()`, and nested error paths
- Rewrote `array_schema_test.dart`: full coverage of `ZemaArray` including length constraints and nested object errors
- Rewrote `modifiers_test.dart`: full coverage of `optional()`, `nullable()`, `withDefault()`, `catchError()`, and `brand()`
- Added `union_test.dart`: covers linear scan, `discriminatedBy()` fast-path, and error meta fields
- Added `double_test.dart`: covers type validation, range constraints, `positive()`, `negative()`, `nonNegative()`, and `finite()`
- Extended `int_test.dart` with `nonNegative()` tests

## [0.3.0] - 2026-02-21

### Added

- `.optional()` modifier for nullable values
- `.nullable()` modifier for explicit null support
- `.default()` modifier for fallback values
- `.literal()` modifier for fallback values
- `.transform()` implementation
- `.datatime()` implementation
- `.map()` implementation
- `.union()` implementation
- `.custom()` implementation
- `.catch()` implementation
- `.prepreces()` implementation
- `.pipe()` implementation

### Change

- update ZemaArray with `.min()` and `.max()` support
- update ZemaSchema by adding modifiers

## [0.2.0] - 2026-02-10

### Added

- Comprehensive README with examples
- API documentation (dartdoc comments)
- Quick start guide
- Usage examples for all types
- 100+ unit tests
- >85% code coverage
- Integration tests

## [0.1.0] - 2026-02-08

### Added

- Core architecture design
- String validation with `.min()`, `.max()`, `.email()`, `.url()`, `.regex()`
- Number validation with `.min()`, `.max()`, `.positive()`, `.negative()`, `.int()`
- Boolean validation
- Object validation with `z.object({})`
- Array validation with `z.array()`
- `.safeParse()` method that returns result object
- `.parse()` method that throws on validation error

## [0.0.1-dev.1] - 2026-02-06

### Added

- Initial project setup
- Monorepo structure with Melos 7.x

[unreleased]: https://github.com/meragix/zema/compare/zema-0.5.0...HEAD
[0.5.0]: https://github.com/meragix/zema/compare/zema-0.4.0...zema-0.5.0
[0.4.0]: https://github.com/meragix/zema/compare/zema-0.3.0...zema-0.4.0
[0.3.0]: https://github.com/meragix/zema/compare/zema-0.2.0...zema-0.3.0
[0.2.0]: https://github.com/meragix/zema/compare/zema-0.1.0...zema-0.2.0
[0.1.0]: https://github.com/meragix/zema/compare/zema-0.0.1-dev.1...zema-0.1.0
[0.0.1-dev.1]: https://github.com/meragix/zema/releases/tag/zema-0.0.1-dev.1
