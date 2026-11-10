// Compiles every ```dart block of the READMEs and docs against the real
// packages, so published examples cannot drift from the API.
//
// Usage (from the workspace root, after `melos bootstrap`):
//   dart run scripts/check_snippets.dart            # READMEs + docs
//   dart run scripts/check_snippets.dart --readmes  # READMEs + examples (CI gate)
//   dart run scripts/check_snippets.dart docs/content/2.core  # path filter
//
// Rules for snippet authors:
// - In READMEs and examples, all blocks of a file share one scope, in order.
//   In docs pages, each block is compiled on its own.
// - Declarations starting at column 0 (class, mixin, enum, typedef,
//   extension, annotated declarations, `main`) are emitted at the top level.
//   Every other line goes into an `async` function body, so statements,
//   local variables and local functions work as written.
// - Identifiers commonly used as "some input" (`input`, `rawInput`, `json`,
//   `data`, `payload`) are pre-declared as `dynamic`.
// - Put `<!-- snippet:skip -->` on the line right before a fence to opt out
//   (pseudo-code, intentionally failing examples, other languages' code).
// - `import` lines inside a block are hoisted to the top of the file.
// - Only analyzer *errors* fail the check. Lints and inference warnings are
//   ignored because fragments are not meant to be production code.
// - `undefined_identifier` is tolerated: fragments routinely reuse a variable
//   declared in a previous block of the same page (`userSchema`, `box`).
//   Unknown methods, getters, classes, functions and type mismatches still
//   fail, which is what catches API drift.

import 'dart:io';

/// Package used as analysis context, and imports added to every snippet.
class _Target {
  const _Target(this.packageDir, this.imports);

  final String packageDir;
  final List<String> imports;
}

const _core = _Target('packages/zema', ['package:zema/zema.dart']);

const _forms = _Target('packages/zema_forms', [
  'package:flutter/material.dart',
  'package:zema/zema.dart',
  'package:zema_forms/zema_forms.dart',
]);

const _firestore = _Target('packages/zema_firestore', [
  'package:cloud_firestore/cloud_firestore.dart',
  'package:zema/zema.dart',
  'package:zema_firestore/zema_firestore.dart',
]);

const _hive = _Target('packages/zema_hive', [
  'package:hive_ce/hive.dart',
  'package:zema/zema.dart',
  'package:zema_hive/zema_hive.dart',
]);

const _standard = _Target('packages/zema_standard_schema', [
  'package:standard_schema/standard_schema.dart',
  'package:zema/zema.dart',
  'package:zema_standard_schema/zema_standard_schema.dart',
]);

_Target _targetFor(String path) {
  if (path.contains('zema_forms')) return _forms;
  if (path.contains('zema_firestore')) return _firestore;
  if (path.contains('zema_hive')) return _hive;
  if (path.contains('zema_standard_schema')) return _standard;
  return _core;
}

List<String> _markdownFiles() {
  final files = <String>[
    'README.md',
    'packages/zema/README.md',
    'packages/zema_forms/README.md',
    'packages/zema_forms/example/example.md',
    'packages/zema_firestore/README.md',
    'packages/zema_hive/README.md',
    'packages/zema_standard_schema/README.md',
  ];
  final docs = Directory('docs/content');
  if (docs.existsSync()) {
    files.addAll(
      docs
          .listSync(recursive: true)
          .whereType<File>()
          .map((f) => f.path)
          .where((p) => p.endsWith('.md'))
          .toList()
        ..sort(),
    );
  }
  return files;
}

class _Snippet {
  _Snippet(this.source, this.lines);

  final String source;

  /// Each code line with its 1-based line number in [source].
  final List<(String, int)> lines;

  int get line => lines.firstWhere((l) => l.$2 > 0, orElse: () => ('', 0)).$2;
}

List<_Snippet> _extract(String path) {
  final lines = File(path).readAsLinesSync();
  final snippets = <_Snippet>[];
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].trim() != '```dart') continue;
    final skip = i > 0 && lines[i - 1].contains('snippet:skip');
    final buffer = <(String, int)>[];
    i++;
    while (i < lines.length && lines[i].trim() != '```') {
      buffer.add((lines[i], i + 1));
      i++;
    }
    if (!skip) snippets.add(_Snippet(path, buffer));
  }
  return snippets;
}

/// READMEs and examples are read top to bottom: a block can use what an
/// earlier block declared, so they are compiled as one scope. Docs pages
/// keep one scope per block because they often redefine the same names.
List<_Snippet> _scoped(String path, List<_Snippet> blocks) {
  if (path.startsWith('docs/') || blocks.isEmpty) return blocks;
  // Each block opens a nested scope: later blocks see earlier names, and
  // redeclaring a name shadows it legally. Line 0 marks scaffolding.
  return [
    _Snippet(path, [
      for (final b in blocks) ...[('{', 0), ...b.lines],
      for (final _ in blocks) ('}', 0),
    ]),
  ];
}

/// Start of a declaration that must live at the top level of a library.
final _topLevelStart = RegExp(
  r'^(abstract |sealed |final |base |interface )*(class|mixin|enum|typedef|extension)\b'
  r'|^(void|Future<void>) main\('
  r'|^@\w',
);

int _braceDelta(String line) {
  // Good enough for documentation code: strip strings and line comments.
  final code = line
      .replaceAll(RegExp(r"'[^']*'"), '')
      .replaceAll(RegExp(r'"[^"]*"'), '')
      .replaceFirst(RegExp(r'//.*$'), '');
  return '{'.allMatches(code).length - '}'.allMatches(code).length;
}

const _ignores =
    '// ignore_for_file: type=lint, unused_local_variable, '
    'unused_element, unused_import, dead_code, unused_catch_clause, '
    'inference_failure_on_function_invocation, '
    'inference_failure_on_collection_literal, '
    'inference_failure_on_untyped_parameter, '
    'inference_failure_on_instance_creation, '
    'inference_failure_on_function_return_type, '
    'strict_raw_type, unnecessary_type_check, unnecessary_cast, '
    'invalid_null_aware_operator, unnecessary_null_comparison, '
    'dead_null_aware_expression, unreachable_switch_case, '
    'unused_result, body_might_complete_normally_nullable, '
    'unnecessary_non_null_assertion, unrelated_type_equality_checks';

/// Error codes that do not indicate API drift in documentation fragments:
/// a variable declared in a previous block, or a block showing two
/// alternatives with the same variable name.
const _tolerated = {
  'UNDEFINED_IDENTIFIER',
  'ALREADY_DEFINED',
  'REFERENCED_BEFORE_DECLARATION',
};

/// Generated source plus, for each generated line, the markdown line it
/// comes from (null for scaffolding).
class _Wrapped {
  _Wrapped(this.source, this.lineMap);

  final String source;
  final List<int?> lineMap;
}

_Wrapped _wrap(_Snippet s, _Target t, int index) {
  final imports = {
    "import 'dart:async';",
    "import 'dart:convert';",
    ...t.imports.map((i) => "import '$i';"),
  };
  final top = <(String, int)>[];
  final body = <(String, int)>[];

  var depth = 0;
  var inTop = false;
  for (final (line, origin) in s.lines) {
    if (!inTop && line.trimLeft().startsWith('import ')) {
      imports.add(line.trim());
      continue;
    }
    if (!inTop && _topLevelStart.hasMatch(line)) {
      inTop = true;
      depth = 0;
    }
    if (inTop) {
      top.add((line, origin));
      depth += _braceDelta(line);
      final isAnnotation = line.startsWith('@') && !line.contains('class ');
      final closes =
          depth <= 0 &&
          !isAnnotation &&
          (line.trimRight().endsWith('}') ||
              line.trimRight().endsWith(';') ||
              line.trimRight().endsWith('};'));
      if (closes) inTop = false;
    } else {
      body.add((line, origin));
    }
  }

  final out = <String>[];
  final map = <int?>[];
  void emit(String line, [int? origin]) {
    out.add(line);
    map.add(origin);
  }

  emit(_ignores);
  emit('// ${s.source}:${s.line}');
  imports.forEach(emit);
  emit('dynamic input, rawInput, json, data, payload;');
  for (final (line, origin) in top) {
    emit(line, origin == 0 ? null : origin);
  }
  emit('Future<void> snippet$index() async {');
  for (final (line, origin) in body) {
    emit(line, origin == 0 ? null : origin);
  }
  emit('}');
  return _Wrapped('${out.join('\n')}\n', map);
}

Future<void> main(List<String> args) async {
  final readmesOnly = args.contains('--readmes');
  final filters = args.where((a) => !a.startsWith('--')).toList();
  final byTarget = <_Target, List<_Snippet>>{};
  for (final path in _markdownFiles()) {
    if (readmesOnly && path.startsWith('docs/')) continue;
    if (filters.isNotEmpty && !filters.any(path.startsWith)) continue;
    if (!File(path).existsSync()) continue;
    for (final s in _scoped(path, _extract(path))) {
      byTarget.putIfAbsent(_targetFor(path), () => []).add(s);
    }
  }

  var failures = 0;
  var total = 0;
  for (final entry in byTarget.entries) {
    final dir = Directory('${entry.key.packageDir}/.snippets');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync();

    final origin = <String, (_Snippet, List<int?>)>{};
    for (var i = 0; i < entry.value.length; i++) {
      final name = 'snippet_$i.dart';
      final wrapped = _wrap(entry.value[i], entry.key, i);
      File('${dir.path}/$name').writeAsStringSync(wrapped.source);
      origin[name] = (entry.value[i], wrapped.lineMap);
    }
    total += entry.value.length;

    final result = await Process.run('dart', [
      'analyze',
      '--format=machine',
      '.snippets',
    ], workingDirectory: entry.key.packageDir);
    final output = '${result.stdout}\n${result.stderr}';
    for (final line in output.split('\n')) {
      final parts = line.split('|');
      if (parts.length < 8 || parts[0] != 'ERROR') continue;
      if (_tolerated.contains(parts[2])) continue;
      final file = parts[3].split(Platform.pathSeparator).last;
      final hit = origin[file];
      final generatedLine = int.tryParse(parts[4]) ?? 1;
      final mapped = hit == null || generatedLine > hit.$2.length
          ? null
          : hit.$2[generatedLine - 1];
      final where = hit == null
          ? file
          : '${hit.$1.source}:${mapped ?? hit.$1.line}';
      stderr.writeln('$where: ${parts[7]}');
      failures++;
    }
    dir.deleteSync(recursive: true);
  }

  if (failures > 0) {
    stderr.writeln('\n$failures error(s) in $total snippet(s).');
    exit(1);
  }
  stdout.writeln('All $total snippet(s) compile.');
}
