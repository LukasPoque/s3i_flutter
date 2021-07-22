import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

/// Exception thrown when an argument is not matching the expectations.
class InvalidArgumentException extends S3IException {
  InvalidArgumentException(String message) : super(message);

  @override
  String toString() {
    return "InvalidArgumentException: $errorMessage";
  }
}
