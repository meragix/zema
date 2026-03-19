---
title: Troubleshooting
description: Common errors, their causes, and how to fix them.
seo:
  title: Troubleshooting 
  description: Diagnose and fix common Zema validation errors, type issues, and configuration problems.
---

## `invalid_type` on a field that is present in the input

**Symptom:** `safeParse` returns an `invalid_type` issue for a field whose value is clearly in the map.

**Common causes:**

1. The Dart runtime type of the value does not match the schema. `z.integer()` rejects `double` values even if the number has no fractional part : `42.0` is a `double`, not an `int`.
2. JSON decoded with `jsonDecode` produces `int` for whole numbers and `double` for fractional ones. If the server occasionally sends `1.0` for an integer field, the schema sees a `double`.

**Fix:** Use `z.coerce().integer()` to accept compatible numeric types, or preprocess the value:

```dart
// Accept both int and whole-number double
z.preprocess(
  (v) => v is double ? v.toInt() : v,
  z.integer(),
);
```

---

## `StateError: Result is a failure` when accessing `.value`

**Symptom:** Calling `result.value` on a `ZemaResult` throws a `StateError`.

**Cause:** `.value` throws when called on a `ZemaFailure`. Always check the result before accessing the value.

**Fix:** Guard with `isSuccess`, or use pattern matching:

```dart
// Guard
if (result.isSuccess) {
  use(result.value);
}

// Pattern matching (exhaustive)
switch (result) {
  case ZemaSuccess(:final value): use(value);
  case ZemaFailure(:final errors): report(errors);
}
```

---

## Schema always fails with `invalid_type` for `Map` input

**Symptom:** A `ZemaObject` schema rejects a `Map` with `invalid_type: expected object, received Map<String, dynamic>`.

**Cause:** This should not happen : `ZemaObject` checks `value is Map`, which is true for any `Map`. If you see this, the value passed to `safeParse` is not actually a `Map` at runtime. Check that JSON decoding completed before validation runs.

**Diagnosis:**

```dart
print(input.runtimeType); // should be _Map<String, dynamic>
final result = schema.safeParse(input);
print(result.errors.first.meta); // prints received type
```

---

## Schema defined inside a function is slow

**Symptom:** Validation is noticeably slow when called in a loop or on every widget rebuild.

**Cause:** Calling `z.object({...})` or `z.string().email()` inside a function constructs new schema instances on every invocation. For hot paths (request handlers, widget `build` methods, tight loops), this adds measurable overhead.

**Fix:** Move schema definitions to the top level or to a `static final` field:

```dart
// Wrong: rebuilt on every call
void validate(Map<String, dynamic> data) {
  final schema = z.object({'email': z.string().email()});
  schema.parse(data);
}

// Correct: defined once
final _schema = z.object({'email': z.string().email()});

void validate(Map<String, dynamic> data) {
  _schema.parse(data);
}
```

---

## `refineAsync` is never reached

**Symptom:** An async refinement is not called even when the input looks valid.

**Cause:** Zema runs all synchronous constraints first. If any synchronous check fails, async refinements are skipped entirely.

**Fix:** Ensure all synchronous constraints pass before testing async behaviour. In tests, use `safeParseAsync()` (not `safeParse()`) to trigger the async path:

```dart
final result = await schema.safeParseAsync(input);
```

---

## `ZemaException` has no `.message` property

**Symptom:** Trying to access `e.message` on a caught `ZemaException` does not compile.

**Cause:** `ZemaException` does not have a single `message` field. It has `issues` : a `List<ZemaIssue>`. Each issue has its own `message`.

**Fix:**

```dart
try {
  schema.parse(input);
} on ZemaException catch (e) {
  // Single summary
  print(e.issues.map((i) => i.message).join(', '));

  // Per-field breakdown
  for (final issue in e.issues) {
    print('${issue.pathString}: ${issue.message}');
  }
}
```

---

## `discriminatedBy()` returns `invalid_union` for a valid input

**Symptom:** A discriminated union fails even though the input has the correct discriminator value and valid fields.

**Cause:** One of these:

1. The discriminator field schema in the object is not a `ZemaLiteral`. `discriminatedBy()` reads the literal value from the schema directly : only `z.literal(value)` works here.
2. The discriminator value in the input is a different Dart type than the literal. `z.literal('click')` will not match the integer `1`.
3. The field name passed to `discriminatedBy()` does not match the key in the shape.

**Diagnosis:**

```dart
// Confirm the discriminator value type
print(input['type'].runtimeType);

// Confirm the schema's literal value
final schema = z.object({'type': z.literal('click'), 'x': z.integer()});
final literal = schema.shape['type'] as ZemaLiteral;
print(literal.value.runtimeType); // should match input
```

---

## `brand()` output is not accepted by a function expecting the branded type

**Symptom:** The compiler rejects a `Branded<String, _MyBrand>` value where `Branded<String, _MyBrand>` is expected.

**Cause:** The brand type `_MyBrand` is likely defined in a different scope than the function parameter. Two `abstract class _MyBrand {}` declarations in different files are distinct types, even if they have the same name.

**Fix:** Define each brand marker class in a single shared file and import it wherever the branded schema or the consuming function is used.

---

## Error messages are in English even after calling `setLocale()`

**Symptom:** `ZemaErrorMap.setLocale('fr')` is called but error messages remain in English.

**Cause:** `setLocale()` takes effect for all subsequent `safeParse()` calls. If schemas were already parsed before the call, or if the call happens after the first validation, earlier results are unaffected.

**Fix:** Call `ZemaErrorMap.setLocale()` at application startup, before any schema is used. In Flutter, place it in `main()` before `runApp()`:

```dart
void main() {
  ZemaErrorMap.setLocale('fr');
  runApp(const MyApp());
}
```

---

## Type inference fails for `z.union()`

**Symptom:** The analyzer reports `couldn't infer type parameter` or `argument type List<Object> can't be assigned`.

**Cause:** When schemas in the union list have different output types (e.g. `ZemaString` and `ZemaInt`), Dart cannot infer a common `T`. The type parameter must be explicit.

**Fix:** Provide an explicit type argument:

```dart
// Fails to infer T
z.union([z.string(), z.integer()])

// Correct: explicit T
z.union<dynamic>([z.string(), z.integer()])

// No inference needed when all schemas share an output type
z.union([z.literal('a'), z.literal('b'), z.literal('c')]) // T = String
```

---

## Still stuck?

- Check the [FAQ](/faq)
- Open an issue on [GitHub](https://github.com/meragix/zema/issues)
