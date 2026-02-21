// ignore_for_file: avoid_print

import 'package:zema/zema.dart';

void main() {
  // Simple validation
  final emailSchema = z.string().trim().email().min(5);
  final result = emailSchema.safeParse('  test@example.com  ');
  print(result.value); // test@example.com

  // Object with transformation
  final userSchema = z.object({
    'name': z.string().min(2),
    'age': z.int().gte(0),
    'email': z.string().email(),
  });

  final userData = {
    'name': 'Alice',
    'age': 30,
    'email': 'alice@example.com',
  };

  final userResult = userSchema.safeParse(userData);
  if (userResult.isSuccess) {
    print('Valid user: ${userResult.value}');
  }

  // Array validation
  final numbersSchema = z.array(z.int().positive()).min(1);
  print(numbersSchema.safeParse([1, 2, 3]).value); // [1, 2, 3]

  // Coercion for env vars
  final portSchema = z.coerce().integer(min: 1, max: 65535).withDefault(3000);
  print(portSchema.safeParse('8080').value); // 8080
  print(portSchema.safeParse(null).value); // 3000 (default)
}
