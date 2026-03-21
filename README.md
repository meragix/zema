# Zema

<!-- <div align="center"> -->
  <!-- <a href="https://zema.meragix.dev">
    <img src="https://zema.meragix.dev/logo.png" alt="Zema Logo" width="200">
  </a>
  <h1>Schema validation for Dart</h1>
  <p>Inspired by <a href="https://zod.dev">Zod</a>. Define schemas once, parse anywhere. All errors are collected in a single pass.</p> -->
<!-- </div> -->

Schema validation for Dart, inspired by [Zod](https://zod.dev). Define schemas once, parse anywhere. All errors are collected in a single pass.

---

## Packages

| Package | Description | CI | Pub |
| ------- | ----------- | -- | --- |
| [zema](https://pub.dev/packages/zema) | Core schema validation library | [![zema](https://github.com/meragix/zema/actions/workflows/zema.yml/badge.svg)](https://github.com/meragix/zema/actions/workflows/zema.yml) | [![pub](https://img.shields.io/pub/v/zema.svg)](https://pub.dev/packages/zema) |
| [zema_forms](https://pub.dev/packages/zema_forms) | Flutter form widgets and controller | [![zema_forms](https://github.com/meragix/zema/actions/workflows/zema_forms.yml/badge.svg)](https://github.com/meragix/zema/actions/workflows/zema_forms.yml) | [![pub](https://img.shields.io/pub/v/zema_forms.svg)](https://pub.dev/packages/zema_forms) |
| [zema_firestore](https://pub.dev/packages/zema_firestore) | Cloud Firestore integration via `withConverter` | [![zema_firestore](https://github.com/meragix/zema/actions/workflows/zema_firestore.yml/badge.svg)](https://github.com/meragix/zema/actions/workflows/zema_firestore.yml) | [![pub](https://img.shields.io/pub/v/zema_firestore.svg)](https://pub.dev/packages/zema_firestore) |
| [zema_hive](https://pub.dev/packages/zema_hive) | Hive local storage integration | [![zema_hive](https://github.com/meragix/zema/actions/workflows/zema_hive.yml/badge.svg)](https://github.com/meragix/zema/actions/workflows/zema_hive.yml) | [![pub](https://img.shields.io/pub/v/zema_hive.svg)](https://pub.dev/packages/zema_hive) |

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  zema: ^0.5.0
```

```dart
import 'package:zema/zema.dart';

final userSchema = z.object({
  'name': z.string().min(2),
  'email': z.string().email(),
  'age': z.integer().gte(18).optional(),
});

// parse() returns the validated value or throws ZemaException
final user = userSchema.parse({
  'name': 'Alice',
  'email': 'alice@example.com',
});

// safeParse() never throws, returns ZemaResult<T>
final result = userSchema.safeParse(rawInput);

switch (result) {
  case ZemaSuccess(:final value):
    print(value['name']);
  case ZemaFailure(:final errors):
    for (final issue in errors) {
      print('${issue.path.join(".")}: ${issue.message}');
    }
}
```

---

## Documentation

Full documentation is available at [zema.meragix.dev](https://zema.meragix.dev).

---

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## License

This project is licensed under the [LICENSE](LICENSE) License
