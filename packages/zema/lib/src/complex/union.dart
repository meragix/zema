import 'package:zema/src/core/result.dart';
import 'package:zema/zema.dart';

final class ZemaUnion<T> extends ZemaSchema<dynamic, T> {
  final List<ZemaSchema<dynamic, T>> schemas;
  final String? discriminator;

  const ZemaUnion(this.schemas, {this.discriminator});

  @override
  ZemaResult<T> safeParse(dynamic value) {
    final unionErrors = <List<ZemaIssue>>[];

    // If discriminated union, try to fast-path
    // Fast path discriminated union (to be implemented properly later)
    if (discriminator != null && value is Map) {
      final discValue = value[discriminator];
      if (discValue != null) {
        // Try to match discriminator-specific schema first
        // (would need schema metadata for this optimization)
      }
    }

    // Try each schema until one succeeds
    for (final schema in schemas) {
      final result = schema.safeParse(value);
      if (result.isSuccess) {
        return result; // Success!
      }
      unionErrors.add(result.errors);
    }

    // All schemas failed
    return singleFailure(
      ZemaIssue(
        code: 'invalid_union',
        message: ZemaI18n.translate('invalid_union'),
        meta: {
          'unionErrors': unionErrors,
          'schemaCount': schemas.length,
          if (discriminator != null) 'discriminator': discriminator,
          'receivedType': value.runtimeType.toString(),
        },
      ),
    );
  }
}
