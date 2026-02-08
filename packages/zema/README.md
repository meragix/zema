# Zema

[![pub package](https://img.shields.io/pub/v/zema.svg)](https://pub.dev/packages/zema)
[![package publisher](https://img.shields.io/pub/publisher/zema.svg)](https://pub.dev/packages/zema/publisher)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

Zema is a Dart validation library inspired by [Zod](https://zod.dev), with best-in-class type inference and zero-cost abstractions.

## Features

- 🎯 **100% Type-Safe**: Full generic inference, no `dynamic`
- ⚡ **Zero-Cost Abstractions**: `final class` + const singletons
- 🔥 **Dart 3.5+ Native**: Records, pattern matching, sealed classes
- 🌊 **Fluent API**: Chainable like Zod
- 📊 **Multi-Error Collection**: See all validation errors at once
- 🔄 **Coercion System**: Parse environment variables effortlessly
- ⚡ **Async Support**: `refineAsync` for database checks

## 🚀 Quick Start

```yaml
dependencies:
  zema: ^0.1.0
```

```dart
import 'package:zema/zema.dart';

final userSchema = z.object({
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.number().positive().optional(),
});

final user = userSchema.parse({
  'name': 'John',
  'email': 'john@example.com',
  'age': 30,
});
```

## 📚 Documentation

- [Zema Documentation](https://zema.meragix.dev)
- [API Reference](https://pub.dev/documentation/zema/latest/)

## 📄 License

MIT License - see [LICENSE](LICENSE)
