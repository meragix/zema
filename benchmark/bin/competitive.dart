// Competitive benchmark: zema vs acanthis, ez_validator, luthor, zard
//
// Run:
//   cd benchmark && dart pub get && dart run bin/competitive.dart
//
// Each benchmark class pre-builds its schema once (static final) and measures
// only the parse/validate call in run(). This reflects real-world usage where
// schemas are defined at the top level and reused across many calls.
//
// Scenarios:
//   1. String.email     — validate an email string
//   2. Integer.range    — validate an integer within [0, 120]
//   3. Object.flat      — validate a 4-field flat map
//   4. Object.failure   — validate an invalid 3-field map (error path)

// ignore_for_file: avoid_print

import 'package:benchmark_harness/benchmark_harness.dart';

// zema — this library
import 'package:zema/zema.dart';

// acanthis — Zod-inspired, uses top-level functions
import 'package:acanthis/acanthis.dart' as acanthis;

// ez_validator — Flutter form validator, EzValidator<T> / EzSchema
import 'package:ez_validator/ez_validator.dart';

// luthor — uses the `l` singleton
import 'package:luthor/luthor.dart';

// zard — Zod-inspired, uses z factory (aliased to avoid conflict with zema's z)
import 'package:zard/zard.dart' as zard;

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

const _kEmail = 'alice@example.com';
const _kAge = 30;

final _kFlatMap = <String, dynamic>{
  'name': 'Alice',
  'email': 'alice@example.com',
  'age': 30,
  'active': true,
};

final _kInvalidMap = <String, dynamic>{
  'name': 'X', // too short
  'email': 'not-an-email',
  'age': -5, // below 0
};

// ─────────────────────────────────────────────────────────────────────────────
// 1. String.email
// ─────────────────────────────────────────────────────────────────────────────

class ZemaStringEmail extends BenchmarkBase {
  static final _s = z.string().email();
  ZemaStringEmail() : super('zema         | String.email');
  @override
  void run() => _s.safeParse(_kEmail);
}

class AcanthisStringEmail extends BenchmarkBase {
  static final _s = acanthis.string().email();
  AcanthisStringEmail() : super('acanthis     | String.email');
  @override
  void run() => _s.tryParse(_kEmail);
}

class LuthorStringEmail extends BenchmarkBase {
  static final _s = l.string().email();
  LuthorStringEmail() : super('luthor       | String.email');
  @override
  void run() => _s.validateValue(_kEmail);
}

class ZardStringEmail extends BenchmarkBase {
  static final _s = zard.z.string().email();
  ZardStringEmail() : super('zard         | String.email');
  @override
  void run() => _s.safeParse(_kEmail);
}

class EzStringEmail extends BenchmarkBase {
  static final _s = EzValidator<String>().email();
  EzStringEmail() : super('ez_validator | String.email');
  @override
  void run() => _s.validate(_kEmail);
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Integer.range  [0, 120]
// ─────────────────────────────────────────────────────────────────────────────

class ZemaIntRange extends BenchmarkBase {
  static final _s = z.integer().gte(0).lte(120);
  ZemaIntRange() : super('zema         | Integer.range');
  @override
  void run() => _s.safeParse(_kAge);
}

class AcanthisIntRange extends BenchmarkBase {
  static final _s = acanthis.integer().gte(0).lte(120);
  AcanthisIntRange() : super('acanthis     | Integer.range');
  @override
  void run() => _s.tryParse(_kAge);
}

class LuthorIntRange extends BenchmarkBase {
  static final _s = l.int().min(0).max(120);
  LuthorIntRange() : super('luthor       | Integer.range');
  @override
  void run() => _s.validateValue(_kAge);
}

class ZardIntRange extends BenchmarkBase {
  static final _s = zard.z.int().min(0).max(120);
  ZardIntRange() : super('zard         | Integer.range');
  @override
  void run() => _s.safeParse(_kAge);
}

class EzIntRange extends BenchmarkBase {
  static final _s = EzValidator<int>().min(0).max(120);
  EzIntRange() : super('ez_validator | Integer.range');
  @override
  void run() => _s.validate(_kAge);
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. Object.flat  (4 fields, success path)
// ─────────────────────────────────────────────────────────────────────────────

class ZemaObjectFlat extends BenchmarkBase {
  static final _s = z.object({
    'name': z.string().min(2),
    'email': z.string().email(),
    'age': z.integer().gte(0).lte(120),
    'active': z.boolean(),
  });
  ZemaObjectFlat() : super('zema         | Object.flat');
  @override
  void run() => _s.safeParse(_kFlatMap);
}

class AcanthisObjectFlat extends BenchmarkBase {
  static final _s = acanthis.object({
    'name': acanthis.string().min(2),
    'email': acanthis.string().email(),
    'age': acanthis.integer().gte(0).lte(120),
    'active': acanthis.boolean(),
  });
  AcanthisObjectFlat() : super('acanthis     | Object.flat');
  @override
  void run() => _s.tryParse(_kFlatMap);
}

class LuthorObjectFlat extends BenchmarkBase {
  static final _s = l.schema({
    'name': l.string().min(1),
    'email': l.string().email(),
    'age': l.int().min(0).max(120),
    'active': l.boolean(),
  });
  LuthorObjectFlat() : super('luthor       | Object.flat');
  @override
  void run() => _s.validateSchema(_kFlatMap);
}

class ZardObjectFlat extends BenchmarkBase {
  static final _s = zard.z.map({
    'name': zard.z.string().min(2),
    'email': zard.z.string().email(),
    'age': zard.z.int().min(0).max(120),
    'active': zard.z.bool(),
  });
  ZardObjectFlat() : super('zard         | Object.flat');
  @override
  void run() => _s.safeParse(_kFlatMap);
}

class EzObjectFlat extends BenchmarkBase {
  static final _s = EzSchema.shape({
    'name': EzValidator<String>().minLength(2),
    'email': EzValidator<String>().email(),
    'age': EzValidator<int>().min(0).max(120),
    'active': EzValidator<bool>().required(),
  });
  EzObjectFlat() : super('ez_validator | Object.flat');
  @override
  void run() => _s.validateSync(_kFlatMap);
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Object.failure  (3 fields, all invalid — error-collection path)
// ─────────────────────────────────────────────────────────────────────────────

class ZemaObjectFailure extends BenchmarkBase {
  static final _s = z.object({
    'name': z.string().min(2),
    'email': z.string().email(),
    'age': z.integer().gte(0),
  });
  ZemaObjectFailure() : super('zema         | Object.failure');
  @override
  void run() => _s.safeParse(_kInvalidMap);
}

class AcanthisObjectFailure extends BenchmarkBase {
  static final _s = acanthis.object({
    'name': acanthis.string().min(2),
    'email': acanthis.string().email(),
    'age': acanthis.integer().gte(0),
  });
  AcanthisObjectFailure() : super('acanthis     | Object.failure');
  @override
  void run() => _s.tryParse(_kInvalidMap);
}

class LuthorObjectFailure extends BenchmarkBase {
  static final _s = l.schema({
    'name': l.string().min(2),
    'email': l.string().email(),
    'age': l.int().min(0),
  });
  LuthorObjectFailure() : super('luthor       | Object.failure');
  @override
  void run() => _s.validateSchema(_kInvalidMap);
}

class ZardObjectFailure extends BenchmarkBase {
  static final _s = zard.z.map({
    'name': zard.z.string().min(2),
    'email': zard.z.string().email(),
    'age': zard.z.int().min(0),
  });
  ZardObjectFailure() : super('zard         | Object.failure');
  @override
  void run() => _s.safeParse(_kInvalidMap);
}

class EzObjectFailure extends BenchmarkBase {
  static final _s = EzSchema.shape({
    'name': EzValidator<String>().minLength(2),
    'email': EzValidator<String>().email(),
    'age': EzValidator<int>().min(0),
  });
  EzObjectFailure() : super('ez_validator | Object.failure');
  @override
  void run() => _s.validateSync(_kInvalidMap);
}

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

void _header(String title) {
  final line = '─' * 52;
  print('\n$line');
  print('  $title');
  print(line);
}

void main() {
  print('Zema competitive benchmarks\n');
  print('Results in µs/iteration — lower is better.\n');
  print('Schemas are defined once (static final) and reused.');

  _header('1 · String.email');
  ZemaStringEmail().report();
  AcanthisStringEmail().report();
  LuthorStringEmail().report();
  ZardStringEmail().report();
  EzStringEmail().report();

  _header('2 · Integer.range [0, 120]');
  ZemaIntRange().report();
  AcanthisIntRange().report();
  LuthorIntRange().report();
  ZardIntRange().report();
  EzIntRange().report();

  _header('3 · Object.flat (4 fields, success path)');
  ZemaObjectFlat().report();
  AcanthisObjectFlat().report();
  LuthorObjectFlat().report();
  ZardObjectFlat().report();
  EzObjectFlat().report();

  _header('4 · Object.failure (3 invalid fields, error-collection path)');
  ZemaObjectFailure().report();
  AcanthisObjectFailure().report();
  LuthorObjectFailure().report();
  ZardObjectFailure().report();
  EzObjectFailure().report();

  print('');
}
