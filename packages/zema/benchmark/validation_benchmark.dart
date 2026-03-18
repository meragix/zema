import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:zema/zema.dart';

// ---------------------------------------------------------------------------
// Primitives
// ---------------------------------------------------------------------------

class StringBenchmark extends BenchmarkBase {
  static final _schema = z.string().min(5).max(100).email();
  static const _data = 'alice@example.com';

  StringBenchmark() : super('String.email');

  @override
  void run() => _schema.safeParse(_data);
}

class IntegerBenchmark extends BenchmarkBase {
  static final _schema = z.integer().gte(0).lte(120);
  static const _data = 30;

  IntegerBenchmark() : super('Integer.range');

  @override
  void run() => _schema.safeParse(_data);
}

// ---------------------------------------------------------------------------
// Object — flat
// ---------------------------------------------------------------------------

class FlatObjectBenchmark extends BenchmarkBase {
  static final _schema = z.object({
    'name':   z.string().min(2),
    'email':  z.string().email(),
    'age':    z.integer().gte(0).lte(120),
    'active': z.boolean(),
  });

  static final _data = {
    'name':   'Alice',
    'email':  'alice@example.com',
    'age':    30,
    'active': true,
  };

  FlatObjectBenchmark() : super('Object.flat(4 fields)');

  @override
  void run() => _schema.safeParse(_data);
}

// ---------------------------------------------------------------------------
// Object — nested
// ---------------------------------------------------------------------------

class NestedObjectBenchmark extends BenchmarkBase {
  static final _coordinates = z.object({'lat': z.double(), 'lng': z.double()});
  static final _address = z.object({'city': z.string(), 'coordinates': _coordinates});
  static final _schema  = z.object({'name': z.string(), 'address': _address});

  static final _data = {
    'name': 'Alice',
    'address': {
      'city': 'Paris',
      'coordinates': {'lat': 48.8566, 'lng': 2.3522},
    },
  };

  NestedObjectBenchmark() : super('Object.nested(3 levels)');

  @override
  void run() => _schema.safeParse(_data);
}

// ---------------------------------------------------------------------------
// Array
// ---------------------------------------------------------------------------

class ArrayBenchmark extends BenchmarkBase {
  static final _schema = z.array(z.string().email());
  static final _data = List.generate(50, (i) => 'user$i@example.com');

  ArrayBenchmark() : super('Array(50 emails)');

  @override
  void run() => _schema.safeParse(_data);
}

class ArrayOfObjectsBenchmark extends BenchmarkBase {
  static final _item = z.object({
    'id':    z.integer().positive(),
    'email': z.string().email(),
  });
  static final _schema = z.array(_item);
  static final _data = List.generate(
    20,
    (i) => {'id': i + 1, 'email': 'user$i@example.com'},
  );

  ArrayOfObjectsBenchmark() : super('Array.of(objects, 20 items)');

  @override
  void run() => _schema.safeParse(_data);
}

// ---------------------------------------------------------------------------
// Union — linear scan
// ---------------------------------------------------------------------------

class UnionLinearBenchmark extends BenchmarkBase {
  static final _schema = z.union([
    z.literal('pending'),
    z.literal('active'),
    z.literal('archived'),
  ]);

  UnionLinearBenchmark() : super('Union.linear(3 literals)');

  @override
  void run() {
    _schema.safeParse('pending');
    _schema.safeParse('active');
    _schema.safeParse('archived');
  }
}

// ---------------------------------------------------------------------------
// Union — discriminated
// ---------------------------------------------------------------------------

class UnionDiscriminatedBenchmark extends BenchmarkBase {
  static final _schema = z.union([
    z.object({'type': z.literal('click'),    'x': z.integer(), 'y': z.integer()}),
    z.object({'type': z.literal('keypress'), 'key': z.string()}),
    z.object({'type': z.literal('scroll'),   'delta': z.double()}),
  ]).discriminatedBy('type');

  static final _click    = {'type': 'click',    'x': 100, 'y': 200};
  static final _keypress = {'type': 'keypress', 'key': 'Enter'};
  static final _scroll   = {'type': 'scroll',   'delta': 3.5};

  UnionDiscriminatedBenchmark() : super('Union.discriminated(3 schemas)');

  @override
  void run() {
    _schema.safeParse(_click);
    _schema.safeParse(_keypress);
    _schema.safeParse(_scroll);
  }
}

// ---------------------------------------------------------------------------
// Schema reuse: top-level definition vs inline (anti-pattern comparison)
// ---------------------------------------------------------------------------

// Correct: schema defined once at top level (what the benchmark measures)
final _reuseSchema = z.object({'email': z.string().email(), 'age': z.integer()});

class SchemaReuseBenchmark extends BenchmarkBase {
  static final _data = {'email': 'x@example.com', 'age': 25};

  SchemaReuseBenchmark() : super('Object.reuse(top-level schema)');

  @override
  void run() => _reuseSchema.safeParse(_data);
}

class SchemaInlineBenchmark extends BenchmarkBase {
  static final _data = {'email': 'x@example.com', 'age': 25};

  SchemaInlineBenchmark() : super('Object.inline(schema rebuilt per call)');

  @override
  void run() {
    // Intentionally recreates the schema on every iteration.
    // This benchmark exists to quantify the construction overhead.
    z.object({'email': z.string().email(), 'age': z.integer()}).safeParse(_data);
  }
}

// ---------------------------------------------------------------------------
// Failure path
// ---------------------------------------------------------------------------

class FailureBenchmark extends BenchmarkBase {
  static final _schema = z.object({
    'name':  z.string().min(2),
    'email': z.string().email(),
    'age':   z.integer().gte(18),
  });

  // All three fields fail
  static final _data = {'name': 'X', 'email': 'bad', 'age': 5};

  FailureBenchmark() : super('Object.failure(3 errors collected)');

  @override
  void run() => _schema.safeParse(_data);
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

void main() {
  // ignore: avoid_print
  print('Zema validation benchmarks\n');

  StringBenchmark().report();
  IntegerBenchmark().report();
  FlatObjectBenchmark().report();
  NestedObjectBenchmark().report();
  ArrayBenchmark().report();
  ArrayOfObjectsBenchmark().report();
  UnionLinearBenchmark().report();
  UnionDiscriminatedBenchmark().report();

  // ignore: avoid_print
  print('\n-- Schema construction cost --');
  SchemaReuseBenchmark().report();
  SchemaInlineBenchmark().report();

  // ignore: avoid_print
  print('\n-- Failure path --');
  FailureBenchmark().report();
}
