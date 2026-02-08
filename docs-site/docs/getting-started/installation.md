---
sidebar_position: 1
---

# Installation

Get started with Zema in less than 5 minutes.

## Requirements

- Dart SDK ≥ 3.5.0

## Core Package

Add Zema to your `pubspec.yaml`:

```yaml
dependencies:
  zema: ^1.0.0
```

Then run:

```bash
dart pub get
# or
flutter pub get
```

<!-- ## Plugins (Optional)

Install only the plugins you need:

### HTTP Validation

```yaml
dependencies:
  zema_http: ^1.0.0
  dio: ^5.4.0  # or http: ^1.2.0
```

### Form Management

```yaml
dependencies:
  zema_form: ^1.0.0
```

### Local Storage

```yaml
dependencies:
  zema_hive: ^1.0.0
  hive: ^2.2.3
```

### Settings Storage

```yaml
dependencies:
  zema_shared_preferences: ^1.0.0
  shared_preferences: ^2.2.0
```

### Firestore

```yaml
dependencies:
  zema_firestore: ^1.0.0
  cloud_firestore: ^4.13.0
```

### State Management

```yaml
dependencies:
  zema_riverpod: ^1.0.0
  flutter_riverpod: ^2.4.0
``` -->

## Verify Installation

Create a simple schema to verify everything works:

```dart
import 'package:zema/zema.dart';

void main() {
  final schema = z.object({
    'name': z.string(),
    'age': z.integer(),
  });

  final result = schema.parse({
    'name': 'Alice',
    'age': 30,
  });

  print(result.isSuccess); // true
}
```

## Next Steps

- [Quick Start →](./quick-start)
- [Core Concepts →](./core-concepts)