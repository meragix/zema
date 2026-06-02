import 'package:test/test.dart';
import 'package:zema/zema.dart';

void main() {
  group('Nested Formatting Validation', () {
    test('formats deeply nested objects and arrays correctly', () {
      final schema = z.object({
        'company': z.object({
          'name': z.string().min(2),
          'departments': z
              .array(
                z.object({
                  'name': z.string().min(2),
                  'employees': z
                      .array(
                        z.object({
                          'email': z.string().email(),
                          'age': z.int().gte(18),
                        }),
                      )
                      .min(1),
                }),
              )
              .min(1),
        }),
      });

      final invalidData = {
        'company': {
          'name': 'A', // error: too_small
          'departments': [
            {
              'name': 'IT',
              'employees': <Map<String,
                  dynamic>>[], // error: too_small (from array min(1))
            },
            {
              'name': 'X', // error: too_small
              'employees': [
                {
                  'email': 'valid@example.com',
                  'age': 25,
                },
                {
                  'email': 'invalid-email', // error: email
                  'age': 16, // error: too_small
                },
              ],
            },
          ],
        },
      };

      final result = schema.safeParse(invalidData);
      expect(result.isFailure, isTrue);

      final formatted = result.errors.format();

      // Assert root level exists
      expect(formatted, contains('company'));

      final company = formatted['company'] as Map<String, dynamic>;

      // Assert simple nested field
      expect(company, contains('name'));
      expect((company['name'] as Map<String, dynamic>)['_errors'], isNotEmpty);

      // Assert array level exists
      expect(company, contains('departments'));
      final departments = company['departments'] as Map<String, dynamic>;

      // Assert index 0 of array
      expect(departments, contains('0'));
      final dept0 = departments['0'] as Map<String, dynamic>;
      expect(dept0, contains('employees'));
      expect(
          (dept0['employees'] as Map<String, dynamic>)['_errors'], isNotEmpty,);

      // Assert index 1 of array
      expect(departments, contains('1'));
      final dept1 = departments['1'] as Map<String, dynamic>;
      expect(dept1, contains('name'));
      expect((dept1['name'] as Map<String, dynamic>)['_errors'], isNotEmpty);

      expect(dept1, contains('employees'));
      final employees1 = dept1['employees'] as Map<String, dynamic>;

      // Assert index 1 of nested array
      expect(employees1, contains('1'));
      final emp1_1 = employees1['1'] as Map<String, dynamic>;

      expect(emp1_1, contains('email'));
      expect((emp1_1['email'] as Map<String, dynamic>)['_errors'], isNotEmpty);

      expect(emp1_1, contains('age'));
      expect((emp1_1['age'] as Map<String, dynamic>)['_errors'], isNotEmpty);

      // Verify we correctly extracted exactly 5 structural error lists
      final allExtractedErrors = [
        (company['name'] as Map<String, dynamic>)['_errors'],
        (dept0['employees'] as Map<String, dynamic>)['_errors'],
        (dept1['name'] as Map<String, dynamic>)['_errors'],
        (emp1_1['email'] as Map<String, dynamic>)['_errors'],
        (emp1_1['age'] as Map<String, dynamic>)['_errors'],
      ];

      for (final errs in allExtractedErrors) {
        expect(errs, isA<List<String>>());
      }

      expect(result.errors.length, equals(5));
    });
  });
}
