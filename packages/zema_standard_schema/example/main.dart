// ignore_for_file: avoid_print

import 'package:standard_schema/standard_schema.dart';
import 'package:zema/zema.dart';
import 'package:zema_standard_schema/zema_standard_schema.dart';

/// A consumer that only knows about Standard Schema, not about Zema.
///
/// CLI frameworks, form libraries or config loaders can accept any
/// `StandardSchemaV1` and stay independent of the validation library.
void runCommand(StandardSchemaV1<Object?, Object?> schema, Object? input) {
  final result = schema.standard.validate(input);

  if (result is StandardFailure) {
    for (final issue in result.issues) {
      print('${issue.path.join('.')}: ${issue.message}');
    }
    return;
  }

  print('OK: $input');
}

void main() {
  final userSchema = z.object({
    'name': z.string().min(2),
    'email': z.string().email(),
    'age': z.integer().gte(0),
  });

  // Expose the Zema schema through the Standard Schema contract.
  final standard = userSchema.asStandard;

  runCommand(standard, {'name': 'Ada', 'email': 'ada@example.com', 'age': 36});
  runCommand(standard, {'name': 'A', 'email': 'nope', 'age': -1});
}
