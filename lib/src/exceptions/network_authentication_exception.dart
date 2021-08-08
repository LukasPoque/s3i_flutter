import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

/// Exception thrown when a request could not be executed because there is no
/// valid `AccessToken` available (could not be issued).
class NetworkAuthenticationException extends S3IException {
  /// Creates a [NetworkAuthenticationException] with the [originalException].
  NetworkAuthenticationException(this.originalException)
      : super(originalException.toString());

  /// The original exception thrown during receiving an `AccessToken`.
  final Exception originalException;

  @override
  String toString() {
    return 'NetworkAuthenticationException: $originalException';
  }
}
