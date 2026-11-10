/// Fallback for platforms without `dart:isolate` (the web).
///
/// Runs [computation] synchronously on the current isolate and wraps the
/// result in a [Future], so `ZemaSchema.parseInIsolate` keeps the same
/// signature and result on every platform. Only the offloading is lost.
Future<R> runInBackground<R>(R Function() computation) =>
    Future<R>.sync(computation);
