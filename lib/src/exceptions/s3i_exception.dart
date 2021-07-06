/// Base class for all Exceptions in the s3i_flutter package.
class S3IException implements Exception {
  final String errorMessage;

  S3IException(this.errorMessage);

  @override
  String toString() {
    return "S3IException: $errorMessage";
  }
}
