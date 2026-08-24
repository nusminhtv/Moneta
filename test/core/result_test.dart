import 'package:flutter_test/flutter_test.dart';
import 'package:moneta/core/result.dart';

void main() {
  test('Ok carries a value and folds through the ok branch', () {
    const result = Ok<int>(42);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, 42);
    expect(result.when(ok: (v) => v * 2, err: (_) => -1), 84);
  });

  test('Err carries a failure and folds through the err branch', () {
    const result = Err<int>(AppFailure.notFound('missing'));
    expect(result.isOk, isFalse);
    expect(result.valueOrNull, isNull);
    expect(result.when(ok: (_) => 'ok', err: (f) => f.message), 'missing');
  });

  test('failure shorthands set the right kind', () {
    expect(const AppFailure.storage('db').kind, FailureKind.storage);
    expect(const AppFailure.validation('bad').kind, FailureKind.validation);
    expect(const AppFailure.notFound('gone').kind, FailureKind.notFound);
  });

  test('results are debuggable', () {
    expect(const Ok<int>(1).toString(), 'Ok(1)');
    expect(
      const Err<int>(AppFailure.storage('disk full')).toString(),
      'Err(AppFailure(storage: disk full))',
    );
    expect(
      const AppFailure(FailureKind.unexpected, 'boom').toString(),
      'AppFailure(unexpected: boom)',
    );
  });

  test('equal results hash equally', () {
    expect(const Ok<int>(1).hashCode, const Ok<int>(1).hashCode);
    expect(
      const Err<int>(AppFailure.storage('x')).hashCode,
      const Err<int>(AppFailure.storage('x')).hashCode,
    );
    expect(
      const AppFailure.storage('x').hashCode,
      const AppFailure.storage('x').hashCode,
    );
  });

  test('failures carry an optional cause', () {
    final failure = AppFailure.storage('write failed', cause: StateError('x'));
    expect(failure.cause, isA<StateError>());
  });

  test('results with equal contents are equal', () {
    expect(const Ok<int>(1), const Ok<int>(1));
    expect(
      const Err<int>(AppFailure.storage('x')),
      const Err<int>(AppFailure.storage('x')),
    );
    expect(const Ok<int>(1), isNot(const Ok<int>(2)));
  });
}
