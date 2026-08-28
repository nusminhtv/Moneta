import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/result.dart';
import 'package:moneta/features/auth/data/local_auth_service.dart';

void main() {
  const service = LocalAuthService();

  group('it authenticates nobody', () {
    test('log in accepts any well-formed credentials', () async {
      // This is the point, not a gap. There is no backend and no stored
      // credential, so there is nothing to check against. A test asserting
      // "wrong password is rejected" would be asserting a fiction.
      final a = await service.logIn(
        email: 'someone@example.com',
        password: 'anything-at-all',
      );
      final b = await service.logIn(
        email: 'someone.else@example.com',
        password: 'something-else',
      );
      expect(a.isOk, isTrue);
      expect(b.isOk, isTrue);
    });
  });

  group('shape validation', () {
    test('a bad email is a validation failure naming the problem', () async {
      final result = await service.signUp(
        email: 'nope',
        password: 'longenough',
      );
      expect(result.isOk, isFalse);
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (failure) {
          expect(failure.kind, FailureKind.validation);
          expect(failure.message.toLowerCase(), contains('email'));
        },
      );
    });

    test('a short password is a validation failure', () async {
      final result = await service.signUp(
        email: 'user@example.com',
        password: 'short',
      );
      expect(result.isOk, isFalse);
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (f) => expect(f.kind, FailureKind.validation),
      );
    });

    test('the email is reported before the password', () async {
      // Both are wrong; the user fixes the first field first.
      final result = await service.signUp(email: 'nope', password: 'x');
      result.when(
        ok: (_) => fail('expected a failure'),
        err: (f) => expect(f.message.toLowerCase(), contains('email')),
      );
    });

    test('a reset request only needs a plausible address', () async {
      expect(
        (await service.requestPasswordReset(email: 'user@example.com')).isOk,
        isTrue,
      );
      expect(
        (await service.requestPasswordReset(email: 'nope')).isOk,
        isFalse,
      );
    });
  });

  group('codes', () {
    test('a complete numeric code is accepted', () async {
      expect((await service.confirmCode(code: '482915')).isOk, isTrue);
    });

    test('an incomplete or non-numeric code is refused', () async {
      for (final code in ['', '4829', '48291a']) {
        final result = await service.confirmCode(code: code);
        expect(result.isOk, isFalse, reason: 'accepted "$code"');
        result.when(
          ok: (_) => fail('expected a failure'),
          err: (f) => expect(f.message, contains('${service.codeLength}')),
        );
      }
    });
  });
}
