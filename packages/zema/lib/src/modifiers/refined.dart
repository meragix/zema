import 'package:zema/src/core/result.dart';
import 'package:zema/src/core/schema.dart';
import 'package:zema/src/error/issue.dart';

extension ZemaSchemaRefinement<I, O> on ZemaSchema<I, O> {
  /// Add custom validation logic
  ZemaSchema<I, O> refine(
    bool Function(O) predicate, {
    String? message,
    String? code,
  }) =>
      _RefinedSchema(
        this,
        predicate,
        message ?? 'Custom validation failed',
        code ?? 'custom_error',
      );

  /// Add custom asynchronous validation
  ZemaSchema<I, O> refineAsync(
    Future<bool> Function(O) predicate, {
    String? message,
    String? code,
  }) =>
      _AsyncRefinedSchema(
        this,
        predicate,
        message ?? 'Async validation failed',
        code ?? 'async_custom_error',
      );

  /// Superrefine with access to context
  ZemaSchema<I, O> superRefine(
    List<ZemaIssue>? Function(O, ValidationContext) validator,
  ) =>
      _SuperRefinedSchema(this, validator);
}

final class _RefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final bool Function(O) predicate;
  final String message;
  final String code;

  const _RefinedSchema(this.base, this.predicate, this.message, this.code);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return result;

    final output = result.value;
    if (!predicate(output)) {
      return singleFailure(ZemaIssue(code: code, message: message));
    }

    return success(output);
  }
}

final class _AsyncRefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final Future<bool> Function(O) predicate;
  final String message;
  final String code;

  const _AsyncRefinedSchema(this.base, this.predicate, this.message, this.code);

  @override
  ZemaResult<O> safeParse(I value) {
    // Sync parse delegates to base only
    return base.safeParse(value);
  }

  @override
  Future<ZemaResult<O>> safeParseAsync(I value) async {
    final result = await base.safeParseAsync(value);
    if (result.isFailure) return result;

    final output = result.value;

    try {
      final isValid = await predicate(output);
      if (!isValid) {
        return singleFailure(ZemaIssue(code: code, message: message));
      }
      return success(output);
    } catch (e) {
      return singleFailure(ZemaIssue(
        code: 'async_refinement_error',
        message: 'Async validation failed: $e',
      ));
    }
  }
}

/// Context for advanced validation
class ValidationContext {
  final List<String> path;
  final Map<String, dynamic> meta;

  ValidationContext({
    this.path = const [],
    this.meta = const {},
  });

  void addIssue({required String code, required String message}) {
    // Store issue in context
  }
}

final class _SuperRefinedSchema<I, O> extends ZemaSchema<I, O> {
  final ZemaSchema<I, O> base;
  final List<ZemaIssue>? Function(O, ValidationContext) validator;
  // final ZemaIssue? Function(O, ValidationContext) validator;

  const _SuperRefinedSchema(this.base, this.validator);

  @override
  ZemaResult<O> safeParse(I value) {
    final result = base.safeParse(value);
    if (result.isFailure) return result;

    final output = result.value;
    final ctx = ValidationContext();
    final issues = validator(output, ctx);

    if (issues != null && issues.isNotEmpty) {
      return failure(issues);
    }

    return success(output);
  }
}
