# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[unreleased]: https://github.com/meragix/zema/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/meragix/zema/releases/tag/zema-v0.2.0
[0.1.0]: https://github.com/meragix/zema/releases/tag/zema-v0.1.0
[0.0.1-dev.1]: https://github.com/meragix/zema/releases/tag/zema-v0.0.1-dev.1
