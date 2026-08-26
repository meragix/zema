---
sidebar_position: 1
---

# zema_standard_schema

Standard Schema adapter for Zema. Bridges any `ZemaSchema` into a `StandardSchemaV1`-compliant object that CLI frameworks, form libraries, and other Standard Schema consumers can use.

## Installation

```yaml
dependencies:
  zema: ^0.6.0
  zema_standard_schema: ^0.1.0
  standard_schema: ^0.0.1
```

```dart
import 'package:zema/zema.dart';
import 'package:zema_standard_schema/zema_standard_schema.dart';
```

## Quick start

```dart
final emailSchema = z.string().email().min(3);

// Wrap with .asStandard
final standard = emailSchema.asStandard;

// Use with any Standard Schema consumer
final result = standard.standard.validate('not-an-email');
if (result is StandardFailure) {
  for (final issue in result.issues) {
    print('${issue.path.join(".")}: ${issue.message}');
  }
}
```

## How it works

`ZemaStandardAdapter` wraps a `ZemaSchema` and implements `StandardSchemaV1`. When `validate()` is called, it forwards to `safeParse()` and maps the result:

| Zema | Standard Schema |
|------|-----------------|
| `ZemaSuccess(value)` | `StandardSuccess(value)` |
| `ZemaFailure(errors)` | `StandardFailure` with mapped issues |

## Issue mapping

`ZemaIssue` fields are mapped to `StandardIssue` as follows:

| ZemaIssue field | StandardIssue field | Notes |
|-----------------|---------------------|-------|
| `message` | `message` | Direct mapping |
| `path` | `path` | Same structure (String or int) |
| `code` | not mapped | Standard Schema V1 does not define a code field |
| `receivedValue` | not mapped | Debug context, not in the spec |
| `meta` | not mapped | Debug context, not in the spec |

Warning-level issues (`ZemaSeverity.warning`) are filtered out. They remain accessible via `ZemaResult.warnings` when using the Zema API directly.

## Usage with Mamba CLI

```dart
import 'package:zema/zema.dart';
import 'package:zema_standard_schema/zema_standard_schema.dart';

final userSchema = z.object({
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.int().gte(0),
});

// Expose as Standard Schema without modifying the original schema
final standard = userSchema.asStandard;

// Pass to Mamba or any StandardSchemaV1-aware consumer
void validateInput(StandardSchemaV1<Object?, Object?> schema, Object? value) {
  final result = schema.standard.validate(value);
  if (result is StandardFailure) {
    for (final issue in result.issues) {
      print('${issue.path.join(".")}: ${issue.message}');
    }
  }
}
```

## Using the adapter directly

You can also construct `ZemaStandardAdapter` explicitly instead of using the extension:

```dart
final adapter = ZemaStandardAdapter(mySchema);
final result = adapter.standard.validate(input);
```

This is useful when you need to pass the adapter as a `StandardSchemaV1` type without relying on extension methods.

## Limitations

- **Sync only.** `StandardSchemaV1.validate` is synchronous in the spec. The adapter uses `safeParse()` (sync). For async validation, call the Zema API directly.
- **Warnings filtered.** Zema warning-level issues are filtered out because Standard Schema does not have a warning concept.

## API reference

| Member | Description |
|--------|-------------|
| `ZemaStandardAdapter(schema)` | Wraps a `ZemaSchema` as a `StandardSchemaV1` |
| `.standard` | Returns `StandardSchemaPropsV1` with vendor and validate function |
| `schema.asStandard` | Extension getter that returns a `StandardSchemaV1` |
| `zemaIssueToStandard(issue)` | Maps a single `ZemaIssue` to a `StandardIssue` |
| `zemaIssuesToStandard(issues)` | Maps a list of `ZemaIssue`s, filtering out warnings |
