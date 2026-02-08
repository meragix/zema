import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaObject<T extends Object> extends ZemaSchema<dynamic, T> {
  final Map<String, ZemaSchema<dynamic, dynamic>> shape;
  final T Function(Map<String, dynamic>)? constructor;

  const ZemaObject(this.shape, {this.constructor});

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

    if (constructor != null) {
      try {
        return success(constructor!(cleaned));
      } catch (e) {
        return singleFailure(
        ZemaIssue(
          code: 'transform_error',
          message: ZemaI18n.translate('transform_error'),
          ),
        );
      }
    }

    return success(cleaned as T);
  }

  /// Type-safe transformation to custom class
  // ZemaSchema<dynamic, R> map<R>(R Function(T) mapper) => transform(mapper);
}
