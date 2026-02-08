import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/i18n.dart';
import 'package:zema/src/error/issue.dart';
import 'package:zema/src/extensions/custom_message.dart';
import 'package:zema/src/helpers/validators.dart';

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
        message: ZemaI18n.translate(
          'too_long',
          params: {
            'max': maxLength,
            'actual': str.length,
          },
        ),
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
    if (isEmail == true && !Validators.emailRegex.hasMatch(str)) {
      final issue = ZemaIssue(
        code: 'invalid_email',
        message: ZemaI18n.translate('invalid_email'),
        receivedValue: str,
      );
      issues.add(applyCustomMessage(issue));
    }

    // URL validation
    if (isUrl == true && !Validators.urlRegex.hasMatch(str)) {
      issues.add(
        ZemaIssue(
          code: 'invalid_url',
          message: ZemaI18n.translate('invalid_url'),
          receivedValue: str,
        ),
      );
    }

    // UUID validation
    if (isUuid == true && !Validators.uuidRegex.hasMatch(str)) {
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
}
