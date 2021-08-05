import 'package:s3i_flutter/s3i_flutter.dart';

///Exception thrown if the maximum numbers of retries of an request is exceeded.
///
/// Is often used by the `AuthenticationManager`.
class MaxRetryException extends S3IException {
  /// Creates a [MaxRetryException] with a [errorMessage].
  MaxRetryException(String errorMessage) : super(errorMessage);

  @override
  String toString() {
    return 'MaxRetryException: $errorMessage';
  }
}
