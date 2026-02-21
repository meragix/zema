import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';

final class ZemaMap<K, V> extends ZemaSchema<dynamic, Map<K, V>> {
  final ZemaSchema<dynamic, K> keySchema;
  final ZemaSchema<dynamic, V> valueSchema;
  final int? minSize;
  final int? maxSize;

  const ZemaMap(
    this.keySchema,
    this.valueSchema, {
    this.minSize,
    this.maxSize,
  });

  @override
  ZemaResult<Map<K, V>> safeParse(dynamic value) {
    if (value is! Map) {
      return singleFailure(
        ZemaIssue(
          code: 'invalid_type',
          message: ZemaI18n.translate(
            'invalid_type',
            params: {
              'expected': 'Map',
              'received': value.runtimeType.toString(),
            },
          ),
          receivedValue: value,
          meta: {'expected': 'Map', 'received': value.runtimeType.toString()},
        ),
      );
    }

    if (minSize != null && value.length < minSize!) {
      return singleFailure(
        ZemaIssue(
          code: 'too_small',
          message: ZemaI18n.translate(
            'too_small',
            params: {
              'min': minSize,
              'actual': value.length,
            },
          ),
          receivedValue: value.length,
          meta: {'min': minSize, 'actual': value.length},
        ),
      );
    }

    if (maxSize != null && value.length > maxSize!) {
      return singleFailure(
        ZemaIssue(
          code: 'too_big',
          message: ZemaI18n.translate(
            'too_big',
            params: {
              'max': maxSize,
              'actual': value.length,
            },
          ),
          receivedValue: value.length,
          meta: {'max': maxSize, 'actual': value.length},
        ),
      );
    }

    final errors = <ZemaIssue>[];
    final parsed = <K, V>{};

    for (final entry in value.entries) {
      // Validate key
      final keyResult = keySchema.safeParse(entry.key);
      if (keyResult.isFailure) {
        errors.addAll(
          keyResult.errors.map(
            (issue) => issue.withPath(entry.key.toString()),
          ),
        );
      }

      // Validate value
      final valueResult = valueSchema.safeParse(entry.value);
      if (valueResult.isFailure) {
        errors.addAll(
          valueResult.errors.map(
            (issue) => issue.withPath(entry.key.toString()),
          ),
        );
      }

      if (keyResult.isSuccess && valueResult.isSuccess) {
        parsed[keyResult.value] = valueResult.value;
      }
    }

    if (errors.isNotEmpty) {
      return failure(errors);
    }

    return success(parsed);
  }

  ZemaMap<K, V> min(int size) =>
      ZemaMap(keySchema, valueSchema, minSize: size, maxSize: maxSize);
  ZemaMap<K, V> max(int size) =>
      ZemaMap(keySchema, valueSchema, minSize: minSize, maxSize: size);
}
