import 'package:meta/meta.dart';

/// A minimal success/failure union used across the data and domain layers.
///
/// Repositories never throw for expected failure modes; they return [Result]
/// so that callers are forced by the type system to handle both branches.
@immutable
sealed class Result<T> {
  const Result();

  /// Folds both branches into a single value.
  R when<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) err,
  }) {
    final self = this;
    return switch (self) {
      Ok<T>() => ok(self.value),
      Err<T>() => err(self.failure),
    };
  }

  /// The value when successful, otherwise `null`.
  T? get valueOrNull => this is Ok<T> ? (this as Ok<T>).value : null;

  /// Whether this result represents success.
  bool get isOk => this is Ok<T>;
}

/// Successful [Result].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  bool operator ==(Object other) => other is Ok<T> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// Failed [Result].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;

  @override
  bool operator ==(Object other) => other is Err<T> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err($failure)';
}

/// Classified failure surface. Presentation maps these to user-facing copy.
enum FailureKind {
  /// Local database read/write problem.
  storage,

  /// Caller supplied data that violates a domain rule.
  validation,

  /// The requested entity does not exist.
  notFound,

  /// Anything not otherwise classified.
  unexpected,
}

/// A failure carried by [Err].
@immutable
final class AppFailure {
  const AppFailure(this.kind, this.message, {this.cause});

  /// Storage-layer failure shorthand.
  const AppFailure.storage(String message, {Object? cause})
    : this(FailureKind.storage, message, cause: cause);

  /// Validation failure shorthand.
  const AppFailure.validation(String message)
    : this(FailureKind.validation, message);

  /// Not-found failure shorthand.
  const AppFailure.notFound(String message)
    : this(FailureKind.notFound, message);

  final FailureKind kind;
  final String message;
  final Object? cause;

  @override
  bool operator ==(Object other) =>
      other is AppFailure && other.kind == kind && other.message == message;

  @override
  int get hashCode => Object.hash(kind, message);

  @override
  String toString() => 'AppFailure(${kind.name}: $message)';
}
