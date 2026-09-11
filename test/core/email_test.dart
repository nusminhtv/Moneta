import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/email.dart';

void main() {
  group('the rule is permissive on purpose', () {
    // Addresses that are valid and that a stricter pattern would reject. The
    // only authority on whether an address works is the address itself.
    const accepted = [
      'minh.tran@example.com',
      'user+tag@sub.domain.co.uk',
      'a@b.c',
      'UPPER@EXAMPLE.COM',
      "o'brien@example.com",
      'trần@example.com',
      '  spaced@example.com  ',
    ];

    for (final email in accepted) {
      test('accepts "$email"', () {
        expect(isPlausibleEmail(email), isTrue);
      });
    }
  });

  group('and rejects what is obviously not an address', () {
    const rejected = {
      'minh.tran': 'no @ at all',
      '@example.com': 'nothing before the @',
      'a@b': 'a domain with no dot',
      'a b@c.com': 'a space',
      'a@b.com c': 'a trailing space in the domain',
      'a@@b.com': 'two @',
      'a@.com': 'a domain starting with a dot',
      'a@b.': 'a domain ending with a dot',
      '': 'empty',
      '   ': 'whitespace only',
    };

    for (final entry in rejected.entries) {
      test('rejects "${entry.key}" — ${entry.value}', () {
        expect(isPlausibleEmail(entry.key), isFalse);
      });
    }
  });

  test('the message says the one thing the rule can honestly say', () {
    // Asserted as a literal rather than against the constant, so changing the
    // copy is a deliberate act and not a silent one.
    expect(emailErrorMessage, 'Enter a valid email address');
  });
}
