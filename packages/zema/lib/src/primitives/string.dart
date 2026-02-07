import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/utils/custom_message.dart';

final class ZemaString extends ZemaSchema<dynamic, String>
    with ZemaCustomMessage<dynamic, String> {
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final bool shouldTrim;
  final Set<String>? enumValues;
  final bool? isEmail;
  final bool? isUrl;
  final bool? isUuid;

  @override
  final String? customMessage;

  const ZemaString({
    this.minLength,
    this.maxLength,
    this.pattern,
    this.shouldTrim = false,
    this.enumValues,
    this.isEmail,
    this.isUrl,
    this.isUuid,
    this.customMessage,
  });

  @override
  ZemaResult<String> safeParse(dynamic value) {
    // Type check
    if (value is! String) {
      final issue = ZemaIssue(
        code: 'invalid_type',
        message: ZemaI18n.translate(
          'invalid_type',
          params: {
            'expected': 'string',
            'received': value.runtimeType.toString(),
          },
        ),
        receivedValue: value,
        meta: {'expected': 'string', 'received': value.runtimeType.toString()},
      );
      return singleFailure(
        applyCustomMessage(issue),
      );
    }

    // Trim if requested
    final str = shouldTrim ? value.trim() : value;
    final issues = <ZemaIssue>[];

    // Length validation
    if (minLength != null && str.length < minLength!) {
      final issue = ZemaIssue(
        code: 'too_short',
        message: ZemaI18n.translate(
          'too_short',
          params: {
            'min': minLength,
            'actual': str.length,
          },
        ),
        receivedValue: str,
        meta: {'min': minLength, 'actual': str.length},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (maxLength != null && str.length > maxLength!) {
      final issue = ZemaIssue(
        code: 'too_long',
        message: ZemaI18n.translate('too_long', params: {
          'max': maxLength,
          'actual': str.length,
        }),
        receivedValue: str,
        meta: {'max': maxLength, 'actual': str.length},
      );
      issues.add(applyCustomMessage(issue));
    }

    // Pattern validation
    if (pattern != null && !pattern!.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_format',
          message: 'String does not match required pattern',
          meta: {'pattern': pattern!.pattern},
        ),
      );
    }

    // Email validation
    if (isEmail == true && !_emailRegex.hasMatch(str)) {
      final issue = ZemaIssue(
        code: 'invalid_email',
        message: ZemaI18n.translate('invalid_email'),
        receivedValue: str,
      );
      issues.add(applyCustomMessage(issue));
    }

    // URL validation
    if (isUrl == true && !_urlRegex.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_url',
          message: ZemaI18n.translate('invalid_url'),
          receivedValue: str,
        ),
      );
    }

    // UUID validation
    if (isUuid == true && !_uuidRegex.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_uuid',
          message: ZemaI18n.translate('invalid_uuid'),
          receivedValue: str,
        ),
      );
    }

    // Enum validation
    if (enumValues != null && !enumValues!.contains(str)) {
      final issue = ZemaIssue(
        code: 'invalid_enum',
        message: ZemaI18n.translate(
          'invalid_enum',
          params: {
            'allowed': enumValues!.toList(),
          },
        ),
        receivedValue: str,
        meta: {'allowed': enumValues!.toList()},
      );
      issues.add(applyCustomMessage(issue));
    }

    if (issues.isNotEmpty) {
      return failure(issues);
    }

    return success(str);
  }

  // Fluent API
  ZemaString trim() => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: true,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  ZemaString min(int length, {String? message}) => ZemaString(
        minLength: length,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  ZemaString max(int length, {String? message}) => ZemaString(
        minLength: minLength,
        maxLength: length,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  ZemaString email({String? message}) => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: true,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  ZemaString url() => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: true,
        isUuid: isUuid,
      );

  ZemaString uuid() => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: enumValues,
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: true,
      );

  ZemaString oneOf(List<String> values) => ZemaString(
        minLength: minLength,
        maxLength: maxLength,
        pattern: pattern,
        shouldTrim: shouldTrim,
        enumValues: values.toSet(),
        isEmail: isEmail,
        isUrl: isUrl,
        isUuid: isUuid,
      );

  // Cached regex patterns
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _urlRegex = RegExp(
    r'^https?://[^\s/$.?#].[^\s]*$',
    caseSensitive: false,
  );

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );
}
