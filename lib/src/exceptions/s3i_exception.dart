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
