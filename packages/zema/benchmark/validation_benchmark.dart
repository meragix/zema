import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:zema/zema.dart';

class StringValidationBenchmark extends BenchmarkBase {
  late final ZemaString schema;
  late final String testData;

  StringValidationBenchmark() : super('String validation');

  @override
  void setup() {
    schema = z.string().min(5).max(50).email();
    testData = 'test@example.com';
  }

  @override
  void run() {
    schema.safeParse(testData);
  }
}

class ObjectValidationBenchmark extends BenchmarkBase {
  late final ZemaObject schema;
  late final Map<String, dynamic> testData;

  ObjectValidationBenchmark() : super('Object validation');

  @override
  void setup() {
    schema = z.object({
      'name': z.string().min(2),
      'age': z.int().gte(0).lte(150),
      'email': z.string().email(),
      'active': z.boolean(),
    });

    testData = {
      'name': 'Alice',
      'age': 30,
      'email': 'alice@example.com',
      'active': true,
    };
  }

  @override
  void run() {
    schema.safeParse(testData);
  }
}

void main() {
  StringValidationBenchmark().report();
  ObjectValidationBenchmark().report();
}
