<br />
<div align="center">
  <a href="https://github.com/meragix/zema">
    <img src="assets/logo.png" alt="Zema logo" width="80" height="80">
  </a>

  <h3 align="center">Zema</h3>

  <p align="center">
    Validate untrusted data in Dart and Flutter.
    <br />
    One schema for API responses, forms, Firestore and local storage. Every error in one pass. No build_runner.
    <br />
    <a href="https://zema.meragix.dev"><strong>Read the docs »</strong></a>
    <br />
    <br />
    <a href="https://pub.dev/packages/zema"><img src="https://img.shields.io/pub/v/zema.svg" alt="pub version"></a>
    <a href="https://pub.dev/packages/zema/score"><img src="https://img.shields.io/pub/likes/zema" alt="pub likes"></a>
    <a href="https://github.com/meragix/zema/actions/workflows/ci.yaml"><img src="https://github.com/meragix/zema/actions/workflows/ci.yaml/badge.svg" alt="CI"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="MIT license"></a>
  </p>
</div>

```dart
import 'package:zema/zema.dart';

final signUp = z.object({
  'email': z.string().email(),
  'password': z.string().min(8),
  'age': z.integer().gte(18).optional(),
});

final result = signUp.safeParse({'email': 'ada@', 'password': '123'});

for (final issue in result.errors) {
  print('${issue.pathString}: ${issue.message}');
}
// email: Invalid email format
// password: Must be at least 8 characters
```

`User.fromJson()` trusts its input and throws a `TypeError` on the first bad field. Zema checks data where it enters your app, reports **every** problem with its path and a translated message, and hands you clean, typed values. It is pure Dart, works on Flutter mobile, desktop and **web**, on the server and in CLIs, and needs no code generation.

The API follows [Zod](https://zod.dev): if you have used it in TypeScript, you already know Zema.

## Packages

| Package | Use it to | Version |
| --- | --- | --- |
| [zema](packages/zema) | Define and run schemas | [![pub](https://img.shields.io/pub/v/zema.svg)](https://pub.dev/packages/zema) |
| [zema_forms](packages/zema_forms) | Drive Flutter forms from a schema: errors on blur, per-field rebuilds, focus on the first error | [![pub](https://img.shields.io/pub/v/zema_forms.svg)](https://pub.dev/packages/zema_forms) |
| [zema_firestore](packages/zema_firestore) | Validate every Firestore read through `withConverter` | [![pub](https://img.shields.io/pub/v/zema_firestore.svg)](https://pub.dev/packages/zema_firestore) |
| [zema_hive](packages/zema_hive) | Validate Hive CE reads and writes, migrate old documents on read | [![pub](https://img.shields.io/pub/v/zema_hive.svg)](https://pub.dev/packages/zema_hive) |
| [zema_standard_schema](packages/zema_standard_schema) | Expose schemas through the Standard Schema contract | [![pub](https://img.shields.io/pub/v/zema_standard_schema.svg)](https://pub.dev/packages/zema_standard_schema) |

## One schema, every boundary

```dart
// Typed model without build_runner: an extension type over the validated map.
extension type Todo(Map<String, dynamic> data) implements Object {
  String get id => data['id'] as String;
  String get title => data['title'] as String;
  bool get done => data['done'] as bool;
}

final todoSchema = z.objectAs<Todo>(
  {
    'id': z.string(),
    'title': z.string().trim().min(1),
    'done': z.boolean().withDefault(false),
  },
  Todo.new,
);

// API response
final Todo todo = todoSchema.parse(jsonDecode(body));

// Flutter form (zema_forms):   ZemaFormController(schema: todoSchema)
// Firestore (zema_firestore):  collection('todos').withZema(todoSchema)
// Hive (zema_hive):            box.withZema(todoSchema)
```

## Why Zema?

- **Exhaustive errors.** No short-circuit: every failing field is reported, with a machine-readable `code`, a `path` and a `message`. `errors.format()` turns them into a nested map for form UIs.
- **Messages for humans.** English and French built in, register any locale, override any message globally or per schema.
- **Composable.** `extend`, `merge`, `pick`, `omit`, discriminated unions, recursive schemas, `transform`, `pipe`, `preprocess`, coercion for env vars and query strings.
- **Works with what you have.** Keep Freezed or json_serializable for your models and let Zema validate the map first (`result.mapTo(User.fromJson)`), or skip code generation entirely with extension types.
- **Safe by default.** `safeParse()` returns a sealed `ZemaSuccess` / `ZemaFailure` for Dart 3 pattern matching. `parse()` throws if you prefer exceptions.

Zema is not the fastest validator on pub.dev; acanthis is about twice as fast on objects in [our benchmark](packages/zema/README.md#performance). A call costs microseconds either way.

## Getting started

```sh
dart pub add zema
```

Then follow the [quick start](https://zema.meragix.dev/getting-started/quick-start), or jump to [Coming from Zod](https://zema.meragix.dev/getting-started/coming-from-zod).

## Contributing

Issues, ideas and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) to set up the workspace (Melos), run the tests and check the documentation snippets.

If Zema is useful to you, a **star** here and a **like on [pub.dev](https://pub.dev/packages/zema)** help other Dart developers find it.

## License

MIT. See [LICENSE](LICENSE).
