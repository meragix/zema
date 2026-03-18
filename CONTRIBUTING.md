# Contributing to Zema

Thank you for taking the time to contribute. This document covers everything you need to get started.

---

## Table of contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Project structure](#project-structure)
- [Development workflow](#development-workflow)
- [Code style](#code-style)
- [Writing tests](#writing-tests)
- [Submitting a pull request](#submitting-a-pull-request)
- [Reporting bugs](#reporting-bugs)

---

## Prerequisites

- Dart SDK `>=3.5.0`
- [Melos](https://melos.invertase.dev/) `^7.4.0`

---

## Setup

```bash
# 1. Fork and clone the repository
git clone https://github.com/meragix/zema.git
cd zema

# 2. Install Melos globally (skip if already installed)
dart pub global activate melos

# 3. Bootstrap the workspace
melos bootstrap
```

---

## Project structure

```text
zema/
├── packages/
│   └── zema/                   # Core validation library
│       ├── lib/src/
│       │   ├── core/           # ZemaSchema, ZemaResult
│       │   ├── primitives/     # ZemaString, ZemaInt, ZemaDouble, ZemaBool, ZemaDateTime, ZemaLiteral
│       │   ├── complex/        # ZemaObject, ZemaArray, ZemaUnion, ZemaMap
│       │   ├── modifiers/      # optional, nullable, default, branded, refined
│       │   ├── transformers/   # transform, pipe, preprocess, catch
│       │   ├── coercion/       # ZemaCoerce
│       │   ├── effects/        # lazy
│       │   ├── custom/         # CustomSchema
│       │   ├── error/          # ZemaIssue, ZemaErrorMap, ZemaI18n
│       │   └── factory.dart    # z / zema singleton
│       └── test/
│           ├── unit/           # Per-class unit tests
│           └── integration/    # Cross-schema integration tests
└── docs/                       # Documentation source
```

---

## Development workflow

```bash
# Run the full test suite
melos test
# or
make test

# Run a single test file
dart test packages/zema/test/unit/primitives/string_test.dart

# Static analysis (must pass with zero warnings)
melos analyze

# Format code
melos format

# Check formatting without modifying files (used in CI)
melos format:check

# Run all CI checks at once
make ci

# Generate coverage report
melos test:coverage
```

---

## Code style

The project uses `package:lints/recommended.yaml` with strict analyzer settings. All of the following are enforced:

- `strict-casts`, `strict-inference`, `strict-raw-types` enabled
- Single quotes for strings
- Trailing commas in function calls and definitions
- All public APIs must have type annotations
- `const` constructors and declarations wherever possible

### Immutability

Every schema is immutable. Fluent API methods return **new instances** — they never mutate state.

```dart
// correct: return a new schema with the constraint applied
ZemaString min(int length) => ZemaString(
  minLength: length,
  maxLength: maxLength,
  // … all other fields forwarded
);

// wrong: mutating a field
ZemaString min(int length) {
  minLength = length; // do not do this
  return this;
}
```

### Adding a new validator to a primitive

1. Add a `final` field to the schema class.
2. Forward it through all existing constructors.
3. Add the fluent method that returns a new instance with the field set.
4. Add validation logic inside `safeParse()`.
5. Add a test group in the corresponding `*_test.dart` file.

### Dart type narrowing in generics

When iterating over `List<ZemaSchema<dynamic, T>>` and you need to narrow to a subtype, cast the loop variable to `dynamic` first:

```dart
// correct: dynamic cast allows is-check to narrow
for (final dynamic schema in schemas) {
  if (schema is ZemaObject<dynamic>) { … }
}
```

---

## Writing tests

Tests live in `packages/zema/test/` under `unit/` or `integration/`. Use `dart test` conventions.

```dart
import 'package:test/test.dart';
import 'package:zema/src/factory.dart';

void main() {
  group('ZemaFoo', () {
    group('constraint name', () {
      test('description of passing case', () {
        final schema = z.foo().bar();
        expect(schema.safeParse(validInput).isSuccess, isTrue);
      });

      test('description of failing case', () {
        final result = schema.safeParse(invalidInput);
        expect(result.isFailure, isTrue);
        expect(result.errors.first.code, equals('expected_error_code'));
      });
    });
  });
}
```

Rules:

- Every new public method needs at least one passing test and one failing test.
- Use `result.errors.first.code` to assert the specific error code, not just that an error occurred.
- Do not mock internal schemas. Test against real schema instances.
- Cover error paths: for `ZemaObject` and `ZemaArray`, assert that `issue.path` contains the correct field name or index.

---

## Submitting a pull request

1. Create a branch from `main`:

   ```bash
   git checkout -b feat/your-feature-name
   ```

2. Make your changes.

3. Ensure all checks pass locally:

   ```bash
   melos analyze
   melos format:check
   melos test
   ```

4. Update `packages/zema/CHANGELOG.md` under `## [Unreleased]` with a concise entry describing what changed.

5. Open a pull request against `main`. Fill in the PR template — describe what changed and why.

### Commit message format

```text
type(scope): short description

type: feat | fix | refactor | test | docs | chore
scope: optional, e.g. string | object | union | i18n
```

Examples:

```text
feat(integer): add nonNegative() constraint
fix(union): discriminatedBy fast-path now handles missing discriminator key
test(object): add coverage for merge() and makeStrict()
docs: update performance guide with async batching example
```

---

## Reporting bugs

Open an issue at [github.com/meragix/zema/issues](https://github.com/meragix/zema/issues) and include:

- Dart SDK version (`dart --version`)
- Zema version
- Minimal reproducible example
- Expected behavior
- Actual behavior or error message
