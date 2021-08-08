import 'package:s3i_flutter/src/entry.dart';
import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

/// Exception thrown when a request response could not be parsed correctly to
/// an [Entry].
class ResponseParsingException extends S3IException {
  /// Creates a [ResponseParsingException] with the [originalException].
  ResponseParsingException(this.originalException)
      : super(originalException.toString());

  /// The original exception thrown during parsing of the response.
  final Exception originalException;

  @override
  String toString() {
    return 'NetworkAuthenticationException: $originalException';
  }
}
