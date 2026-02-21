import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaObject<T extends Object> extends ZemaSchema<dynamic, T> {
  final Map<String, ZemaSchema<dynamic, dynamic>> shape;
  final T Function(Map<String, dynamic>)? constructor;
  final bool strict; // Disallow unknown keys

  const ZemaObject(
    this.shape, {
    this.constructor,
    this.strict = false,
  });

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
            'received': value.runtimeType.toString(),
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

    // Strict mode: check for unknown keys
    if (strict) {
      for (final key in value.keys) {
        if (!shape.containsKey(key)) {
          allIssues.add(ZemaIssue(
            code: 'unknown_key',
            message: 'Unknown key: $key',
            path: [key.toString()],
          ));
        }
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
  ZemaSchema<dynamic, R> map<R>(R Function(T) mapper) => transform(mapper);

  /// Make this schema strict (reject unknown keys)
  ZemaObject<T> makeStrict() => ZemaObject(
        shape,
        constructor: constructor,
        strict: true,
      );

  /// Extend this schema with additional fields
  ZemaObject<Map<String, dynamic>> extend(Map<String, ZemaSchema<dynamic, dynamic>> additionalShape) {
    return ZemaObject({...shape, ...additionalShape});
  }

  /// Pick specific fields
  ZemaObject<Map<String, dynamic>> pick(List<String> keys) {
    final pickedShape = <String, ZemaSchema<dynamic, dynamic>>{};
    for (final key in keys) {
      if (shape.containsKey(key)) {
        pickedShape[key] = shape[key]!;
      }
    }
    return ZemaObject(pickedShape);
  }

  /// Omit specific fields
  ZemaObject<Map<String, dynamic>> omit(List<String> keys) {
    final omittedShape = Map<String, ZemaSchema<dynamic, dynamic>>.from(shape);
    for (final key in keys) {
      omittedShape.remove(key);
    }
    return ZemaObject(omittedShape);
  }
}
