---
sidebar_position: 1
description: Install Zema and its plugins in your Dart or Flutter project
---

# Installation

Get started with Zema in less than 5 minutes.

## Requirements

- **Dart SDK**: >= 3.5.0
- **Flutter**: >= 3.18.0 (for Flutter apps only)

---

## Core Package

The core `zema` package provides the schema definition and validation engine.

### Add Dependency

```yaml title="pubspec.yaml"
dependencies:
  zema: ^0.6.0
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
  final schema = z.object({
    'name': z.string(),
    'age': z.integer().gte(0),
  });

  final result = schema.safeParse({
    'name': 'Alice',
    'age': 30,
  });

  if (result.isSuccess) {
    print('Zema is working!');
    print('User data: ${result.value}');
  }
}
```

Run it:

```bash
dart run test_zema.dart
# Output: Zema is working!
```

---

## Plugins

Zema provides optional plugins for common use cases. Install only what you need.

### Flutter Forms

Type-safe form validation for Flutter.

```yaml title="pubspec.yaml"
dependencies:
  zema: ^0.6.0
  zema_forms: ^0.2.0
```

### Cloud Firestore

Runtime validation for Cloud Firestore documents.

```yaml title="pubspec.yaml"
dependencies:
  zema: ^0.6.0
  zema_firestore: ^0.2.0
  cloud_firestore: ^5.0.0
```

### Hive Local Storage

Validated Hive storage without TypeAdapters or code generation.

```yaml title="pubspec.yaml"
dependencies:
  zema: ^0.6.0
  zema_hive: ^0.2.0
  hive_ce: ^2.19.3
```

---

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

### "Package zema not found"

**Solution**: Clear pub cache and reinstall

```bash
dart pub cache repair
dart pub get
```

---

### Still Having Issues?

- [GitHub Issues](https://github.com/meragix/zema/issues)
