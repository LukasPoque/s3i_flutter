import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

/// Exception thrown when a piece of data could not be parsed correctly.
class ParseException extends S3IException {
  ParseException(String message) : super(message);

  @override
  String toString() {
    return "ParseException: $errorMessage";
  }
}
