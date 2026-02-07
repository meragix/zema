import 'package:test/test.dart';
import 'package:zema/src/error/exception.dart';

/// Matcher for ZemaException
Matcher throwsZemaException([String? messageContains]) {
  return throwsA(
    isA<ZemaException>().having(
      (e) => e.toString(),
      'message',
      messageContains != null ? contains(messageContains) : anything,
    ),
  );
}