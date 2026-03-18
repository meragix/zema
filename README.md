# Zema

<!-- <div align="center"> -->
  <!-- <a href="https://zema.meragix.dev">
    <img src="https://zema.meragix.dev/logo.png" alt="Zema Logo" width="200">
  </a>
  <h1>Schema validation for Dart</h1>
  <p>Inspired by <a href="https://zod.dev">Zod</a>. Define schemas once, parse anywhere. All errors are collected in a single pass.</p> -->

[![CI](https://github.com/meragix/zema/workflows/CI/badge.svg)](https://github.com/meragix/zema/actions)
[![Coverage](https://img.shields.io/codecov/c/github/meragix/zema)](https://codecov.io/gh/meragix/zema)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

<!-- </div> -->

Schema validation for Dart, inspired by [Zod](https://zod.dev). Define schemas once, parse anywhere. All errors are collected in a single pass.

---

## Packages

| Package | Likes | Downloads | Analysis |
| ------- | ----- | --------- | -------- |
| [![zema](https://img.shields.io/pub/v/zema.svg?label=zema)](https://pub.dev/packages/zema) | [![likes](https://img.shields.io/pub/likes/zema)](https://pub.dev/packages/zema/score) | [![dm](https://img.shields.io/pub/dm/zema)](https://pub.dev/packages/zema/score) | [![pub points](https://img.shields.io/pub/points/zema)](https://pub.dev/packages/zema/score) |

## Quick Start

```yaml
# pubspec.yaml
dependencies:
  zema: ^0.3.0
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
  'name':  'Alice',
  'email': 'alice@example.com',
});

// safeParse() never throws — returns ZemaResult<T>
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

MIT License  — see [LICENSE](LICENSE)
