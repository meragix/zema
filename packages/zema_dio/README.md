# zema_dio

[![pub.dev](https://img.shields.io/pub/v/zema_dio.svg)](https://pub.dev/packages/zema_dio)

Zema schema validation extension for [Dio](https://pub.dev/packages/dio) HTTP responses.

Adds `.parse()` and `.safeParse()` directly on `Response`, so you can validate the decoded JSON body against any Zema schema without an extra step.

## Installation

```yaml
dependencies:
  zema: ^0.4.0
  zema_dio: ^0.1.0
  dio: ^5.4.0
```

## Usage

```dart
import 'package:dio/dio.dart';
import 'package:zema/zema.dart';
import 'package:zema_dio/zema_dio.dart';

final userSchema = z.object({
  'id':    z.integer(),
  'name':  z.string().min(1),
  'email': z.string().email(),
});

final dio = Dio();

// --- parse(): returns T or throws ZemaException ---
try {
  final response = await dio.get('/users/1');
  final user = response.parse(userSchema);
  print(user['email']);
} on ZemaException catch (e) {
  print(e.issues); // List<ZemaIssue>
}

// --- safeParse(): returns ZemaResult<T>, never throws ---
final response = await dio.get('/users/1');
final result = response.safeParse(userSchema);

switch (result) {
  case ZemaSuccess(:final value):
    print(value['email']);
  case ZemaFailure(:final errors):
    for (final issue in errors) {
      print('${issue.path}: ${issue.message}');
    }
}
```

## API

| Method      | Signature                                             | Behaviour                                              |
|-------------|-------------------------------------------------------|--------------------------------------------------------|
| `parse`     | `T parse<T>(ZemaSchema<dynamic, T>)`                  | Returns `T` or throws `ZemaException`                  |
| `safeParse` | `ZemaResult<T> safeParse<T>(ZemaSchema<dynamic, T>)`  | Returns `ZemaSuccess` or `ZemaFailure`, never throws   |

Both methods validate `Response.data` — the JSON body already decoded by Dio.

## Related packages

- [`zema`](https://pub.dev/packages/zema) — core schema library
- [`zema_http`](https://pub.dev/packages/zema_http) — same extension for `package:http`
- [`zema_forms`](https://pub.dev/packages/zema_forms) — Flutter form integration
