---
sidebar_position: 1
---

# Plugins

Zema plugins are separate packages that extend the core library. Each plugin targets one integration layer. The core library has no Flutter; plugins add those.

## Available plugins

### zema_forms

Bind schemas to Flutter form widgets. Per-field validation with surgical rebuilds.

```dart
final ctrl = ZemaFormController(schema: loginSchema);
```

[Documentation](./flutter_zema/overview)

### zema_firestore

Validate Cloud Firestore documents via `withConverter`. Every read is validated, every write converts `DateTime` to `Timestamp`.

```dart
final usersRef = db.collection('users').withZema(userSchema);
```

[Documentation](./zema_fetch/overview)

### zema_hive

Validate Hive documents on read and write. No `TypeAdapter`, no code generation.

```dart
final userBox = box.withZema(userSchema);
```

### zema_standard_schema

Bridge any Zema schema into the [Standard Schema](https://standardschema.dev) contract. Use with CLI frameworks like Mamba or any consumer that accepts `StandardSchemaV1`.

```dart
final standard = emailSchema.asStandard;
```

[Documentation](./zema_standard_schema/overview)

## Installing a plugin

Plugins are independent pub packages. Add only what you use:

```yaml
dependencies:
  zema: ^0.6.0
  zema_forms: ^0.1.0
  zema_firestore: ^0.1.0
  zema_hive: ^0.1.0
  zema_standard_schema: ^0.1.0
```

Core-only projects (non-Flutter, pure Dart) depend only on `zema`.

## Design principles

- The plugin depends on `package:zema`. `package:zema` never depends on the plugin.
- Schemas defined in the core library work unchanged in every plugin.
- Plugins add adapters or widgets. They do not re-implement validation logic.
- Each plugin ships its own `pubspec.yaml` and lives under `packages/`.
