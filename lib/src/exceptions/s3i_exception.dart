// TODO(poq): maybe a global error code is nicer because developers could use
//  them to map to their custom messages, store a static map<ErrorCode,Message>
//  somewhere to use it here in toString

/// Base class for all Exceptions in the s3i_flutter package.
class S3IException implements Exception {
  /// Creates a [S3IException] with [errorMessage].
  S3IException(this.errorMessage);

  /// The description of the error.
  final String errorMessage;

  @override
  String toString() {
    return 'S3IException: $errorMessage';
  }
}
