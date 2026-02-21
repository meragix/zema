import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

final class CatchSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final O Function(List<ZemaIssue>) handler;

  const CatchSchema(this.base, this.handler);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) {
      return success(handler(result.errors));
    }
    return result;
  }
}
