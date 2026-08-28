import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/features/auth/domain/credentials.dart';

void main() {
  group('email', () {
    test('accepts addresses a strict pattern would wrongly reject', () {
      // Every one of these is a real, deliverable address. A validator that
      // rejects them locks people out of their own accounts, which is a worse
      // failure than letting a typo through to a bounce.
      for (final email in [
        'user+tag@example.com',
        'first.last@sub.domain.co.uk',
        'user@new-tld.photography',
        'x@y.zz',
        "o'brien@example.com",
      ]) {
        expect(
          Credentials.isPlausibleEmail(email),
          isTrue,
          reason: 'rejected the valid address $email',
        );
      }
    });

    test('rejects what is obviously not an address', () {
      for (final email in [
        '',
        '   ',
        'nope',
        '@example.com',
        'user@',
        'user@nodot',
        'user@.com',
        'user@example.',
        'two@at@example.com',
        'has space@example.com',
      ]) {
        expect(
          Credentials.isPlausibleEmail(email),
          isFalse,
          reason: 'accepted $email',
        );
      }
    });

    test('surrounding whitespace does not make an address invalid', () {
      expect(Credentials.isPlausibleEmail('  user@example.com  '), isTrue);
    });

    test('the error message is absent exactly when the address is fine', () {
      expect(Credentials.emailError('user@example.com'), isNull);
      expect(Credentials.emailError('nope'), isNotNull);
    });
  });

  group('password', () {
    test('the boundary is the minimum length, not one either side', () {
      const min = Credentials.minPasswordLength;
      expect(Credentials.passwordError('x' * (min - 1)), isNotNull);
      expect(Credentials.passwordError('x' * min), isNull);
      expect(Credentials.passwordError('x' * (min + 1)), isNull);
    });

    test('an empty password is rejected', () {
      expect(Credentials.passwordError(''), isNotNull);
    });

    test('the message names the requirement', () {
      expect(
        Credentials.passwordError('short'),
        contains('${Credentials.minPasswordLength}'),
      );
    });
  });

  group('code', () {
    test('is complete only at exactly the length, and only digits', () {
      expect(Credentials.isCompleteCode('482915', 6), isTrue);
      expect(Credentials.isCompleteCode('48291', 6), isFalse);
      expect(Credentials.isCompleteCode('4829155', 6), isFalse);
      expect(Credentials.isCompleteCode('', 6), isFalse);
      expect(Credentials.isCompleteCode('48291a', 6), isFalse);
      expect(Credentials.isCompleteCode('4829 5', 6), isFalse);
    });
  });
}
