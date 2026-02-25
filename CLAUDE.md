# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Zema is a Zod-like schema validation library for Dart, providing type-safe runtime validation with a fluent, declarative API. The monorepo uses [Melos](https://melos.invertase.dev/) and currently contains one package: `packages/zema`.

## Commands

```bash
# First-time setup
dart pub global activate melos
melos bootstrap

# Run tests (from workspace root)
melos test
# or
make test

# Run a single test file directly
dart test packages/zema/test/unit/primitives/string_test.dart

# Static analysis
melos analyze

# Format code
melos format

# Check formatting (CI mode)
melos format:check

# Run all CI checks
make ci

# Generate coverage
melos test:coverage
```

## Architecture

### Core Abstractions (`packages/zema/lib/src/core/`)

**`ZemaSchema<Input, Output>`** is the root abstract class. Every schema extends it and must implement `safeParse(Input value) → ZemaResult<Output>`. The base class provides:

- `parse()` — throws `ZemaException` on failure
- `safeParse()` / `safeParseAsync()` — returns `ZemaResult`
- Chainable modifier methods: `.optional()`, `.nullable()`, `.withDefault()`, `.catchError()`
- Transformation methods: `.transform()`, `.pipe()`, `.preprocess()`

**`ZemaResult<T>`** is a sealed class with two subtypes: `ZemaSuccess<T>` and `ZemaFailure<T>`. Use pattern matching or `.when()` to handle both cases. Helper constructors `success()`, `failure()`, and `singleFailure()` are top-level functions in `result.dart`.

### Entry Point (`packages/zema/lib/src/factory.dart`)

`z` (and its alias `zema`) is a `const` singleton instance of the `Zema` factory class. All schema construction starts here: `z.string()`, `z.object({})`, `z.array(z.int())`, etc.

### Schema Layers

| Layer | Location | Types |
|---|---|---|
| Primitives | `src/primitives/` | `ZemaString`, `ZemaInt`, `ZemaDouble`, `ZemaBool`, `ZemaDateTime`, `ZemaLiteral` |
| Complex | `src/complex/` | `ZemaObject<T>`, `ZemaArray<T>`, `ZemaUnion<T>`, `ZemaMap<K,V>` |
| Coercion | `src/coercion/` | `ZemaCoerce` (accessed via `z.coerce()`) |
| Modifiers | `src/modifiers/` | `OptionalSchema`, `NullableSchema`, `DefaultSchema`, `BrandedSchema` |
| Transformers | `src/transformers/` | `TransformedSchema`, `PipedSchema`, `PreprocessedSchema`, `CatchSchema` |
| Refinement | `src/modifiers/refined.dart` | `.refine()`, `.refineAsync()`, `.superRefine()` extensions |
| Custom | `src/custom/` | `CustomSchema` (via `z.custom()`) |
| Effects | `src/effects/` | `LazySchema` (via `z.lazy()`) |

### Immutability Pattern

All schemas use `const` constructors and are fully immutable. Fluent API methods (`.min()`, `.email()`, `.trim()`, etc.) return **new schema instances** — they never mutate state. When adding new validators to a primitive schema, copy all existing fields and set the new one.

### Error System (`packages/zema/lib/src/error/`)

- **`ZemaIssue`** — immutable value object: `code` (string), `message`, `path` (list), `receivedValue`, `meta`
- **`ZemaErrorMap`** — global registry for custom error messages and locale. Set via `ZemaErrorMap.setErrorMap(fn)` and `ZemaErrorMap.setLocale('fr')`
- **`ZemaI18n`** — translation system with built-in `en` and `fr` locales. Register custom locales via `ZemaI18n.registerTranslations(locale, map)`
- Error codes are string constants: `'invalid_type'`, `'too_short'`, `'too_long'`, `'invalid_email'`, `'invalid_enum'`, etc.

### `ZemaObject` Features

`ZemaObject<T>` accepts an optional `constructor` parameter to map the validated `Map<String, dynamic>` to a typed class. Key methods: `.extend()`, `.pick()`, `.omit()`, `.makeStrict()` (rejects unknown keys).

## Code Style

The project uses `package:lints/recommended.yaml` with strict analyzer settings:

- `strict-casts`, `strict-inference`, `strict-raw-types` all enabled
- `prefer_single_quotes` — use single quotes for strings
- `require_trailing_commas` — required in function calls/definitions
- `type_annotate_public_apis` — all public API must be typed
- `prefer_const_constructors` / `prefer_const_declarations`

## Testing

Tests live in `packages/zema/test/` split into `unit/` and `integration/`. Test files use `dart test` conventions. The shared `test_utils.dart` provides `throwsZemaException([String? messageContains])` matcher for testing parse failures.

To run a single test file:

```bash
dart test packages/zema/test/unit/primitives/string_test.dart
```
