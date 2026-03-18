// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:zema/zema.dart';

extension type User(Map<String, dynamic> _) {
  int get id => _['id'] as int;
  String get name => _['name'] as String;
  String get email => _['email'] as String;
  int? get age => _['age'] as int?;
}

final userSchema = z.objectAs<User>(
  {
    'id': z.integer(),
    'name': z.string().min(1),
    'email': z.string().email(),
    'age': z.integer().gte(18, message: 'Must be 18 or older').optional(),
  },
  (map) => User(map),
);

void main() {
  // Fetch data
  final response = jsonEncode({
    'id': 1,
    'name': 'Leanne Graham',
    'email': 'sincere@april.biz',
    //'age': 16,
  });

  // Decode JSON
  final json = jsonDecode(response);

  // Validate with Zema
  final result = userSchema.safeParse(json);

  // Handle result
  if (result.isSuccess) {
    final user = result.value;

    print('✅ Valid user:');
    print('   ID: ${user.id}');
    print('   Name: ${user.name}');
    print('   Email: ${user.email}');
  } else {
    print('❌ Validation failed:');
    for (final error in result.errors) {
      final field = error.path.isEmpty ? 'root' : error.path.join('.');
      print('   $field: ${error.message}');
    }
  }
}
