import 'package:zema/src/core/result.dart';
import 'package:zema/zema.dart';

final class ZemaObject<T extends Object> extends ZemaSchema<dynamic, T> {
  final Map<String, ZemaSchema<dynamic, dynamic>> shape;
  const ZemaObject(this.shape);

  @override
  ZemaResult<T> safeParse(dynamic value) {
    if (value is! Map) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_type',
          message: ZemaI18n.translate(
            'invalid_type',
            params: {
              'expected': 'object',
              'received': value.runtimeType.toString(),
            },
          ),
          receivedValue: value,
          meta: {
            'expected': 'object',
            'received': value.runtimeType.toString()
          },
        ),
      );
    }

    final cleaned = <String, dynamic>{};
    final allIssues = <ZemaIssue>[];

    for (final entry in shape.entries) {
      final key = entry.key;
      final schema = entry.value;
      final fieldValue = value[key];

      final result = schema.safeParse(fieldValue);

      if (result.isFailure) {
        for (final issue in result.errors) {
          allIssues.add(issue.withPath(key));
        }
      } else {
        cleaned[key] = result.value;
      }
    }

    if (allIssues.isNotEmpty) {
      return failure(allIssues);
    }

    return success(cleaned as T);
  }
}
