---
sidebar_position: 1
description: Install Zema and its plugins in your Dart or Flutter project
---

# Installation

Get started with Zema in less than 5 minutes.

## Requirements

- **Dart SDK**: ≥ 3.3.0
- **Flutter**: ≥ 3.10.0 (for Flutter apps only)

:::info Why Dart 3.3+?
Zema uses [Extension Types](https://dart.dev/language/extension-types), a Dart 3.3+ feature that provides zero-cost type-safe wrappers. This enables Zema to deliver runtime validation with minimal performance overhead.
:::

---

## Core Package

The core `zema` package provides the schema definition and validation engine.

### Add Dependency

```yaml title="pubspec.yaml"
dependencies:
  zema: ^1.0.0
```

### Install

```bash
# For Dart projects
dart pub get

# For Flutter projects
flutter pub get
```

### Verify Installation

Create a test file to verify Zema is working:

```dart title="test_zema.dart"
import 'package:zema/zema.dart';

void main() {
  // Define a schema
  final userSchema = z.object({
    'name': z.string(),
    'age': z.integer().min(0),
  });

  // Validate data
  final result = userSchema.parse({
    'name': 'Alice',
    'age': 30,
  });

  if (result.isSuccess) {
    print('✅ Zema is working!');
    print('User data: ${result.value}');
  }
}
```

Run it:

```bash
dart run test_zema.dart
# Output: ✅ Zema is working!
```

---

## Plugins (Optional)

Zema provides plugins for common use cases. Install only what you need.

### HTTP Validation (Comming Soon)

Validate API responses from Dio, package:http, or Chopper.

```yaml title="pubspec.yaml"
dependencies:
  zema_fetch: ^1.0.0
  
  # Choose your HTTP client
  dio: ^5.4.0           # Option 1: Dio
  # http: ^1.2.0        # Option 2: package:http
  # chopper: ^7.0.0     # Option 3: Chopper
```

**Tree-shaking imports** (recommended for smaller bundle size):

```dart
// Import only what you need
import 'package:zema_fetch/dio.dart';        // Dio only
// import 'package:zema_fetch/http.dart';     // package:http only
// import 'package:zema_fetch/chopper.dart';  // Chopper only
```

[→ Learn more about zema_fetch](/docs/plugins/zema_http/overview)

---

<!-- ### Form Management

Type-safe form validation for Flutter.

```yaml title="pubspec.yaml"
dependencies:
  zema_form: ^1.0.0
```

[→ Learn more about zema_form](/docs/plugins/zema_form/overview)

---

### Local Storage (Hive)

Validated Hive storage without TypeAdapters.

```yaml title="pubspec.yaml"
dependencies:
  zema_hive: ^1.0.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0  # For Flutter apps
```

[→ Learn more about zema_hive](/docs/plugins/zema_hive/overview)

---

### Settings Storage

Type-safe reactive settings with SharedPreferences.

```yaml title="pubspec.yaml"
dependencies:
  zema_shared_preferences: ^1.0.0
  shared_preferences: ^2.2.0
```

[→ Learn more about zema_shared_preferences](/docs/plugins/zema_shared_preferences/overview)

---

### Firestore

Runtime validation for Cloud Firestore documents.

```yaml title="pubspec.yaml"
dependencies:
  zema_firestore: ^1.0.0
  cloud_firestore: ^4.13.0
```

[→ Learn more about zema_firestore](/docs/plugins/zema_firestore/overview)

---

### State Management (Riverpod)

Validated state with Riverpod providers.

```yaml title="pubspec.yaml"
dependencies:
  zema_riverpod: ^1.0.0
  flutter_riverpod: ^2.4.0
```

[→ Learn more about zema_riverpod](/docs/plugins/zema_riverpod/overview)

--- -->

## IDE Setup

### VS Code

Install the Dart extension for syntax highlighting and autocomplete:

1. Install [Dart Extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.dart-code)
2. Zema schemas will have full IntelliSense support

### IntelliJ / Android Studio

Dart support is built-in. No additional setup required.

---

## Next Steps

import DocCard from '@theme/DocCard';

<div className="row">
  <div className="col col--6">
    <a href="./quick-start" className="card">
      <h3>Quick Start →</h3>
      <p>Build your first validated app in 5 minutes</p>
    </a>
  </div>
  <div className="col col--6">
    <a href="./core-concepts" className="card">
      <h3>Core Concepts →</h3>
      <p>Learn the fundamentals of schema-first validation</p>
    </a>
  </div>
</div>

---

## Troubleshooting

### "Extension types are not supported"

**Solution**: Ensure you're using Dart SDK ≥ 3.3.0

```bash
dart --version
# Should show: Dart SDK version: 3.x.x
```

Update if needed:

```bash
# Via Flutter
flutter upgrade

# Via Dart SDK directly
brew upgrade dart-sdk  # macOS
# or download from https://dart.dev/get-dart
```

---

### "Package zema not found"

**Solution**: Clear pub cache and reinstall

```bash
dart pub cache repair
dart pub get
```

---

### Still Having Issues?

- [GitHub Issues](https://github.com/your-org/zema/issues)
- [Discord Community](https://discord.gg/zema)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/zema)
