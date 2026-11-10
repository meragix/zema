import 'dart:isolate';

/// Runs [computation] in a new [Isolate] (native platforms).
Future<R> runInBackground<R>(R Function() computation) =>
    Isolate.run(computation);
