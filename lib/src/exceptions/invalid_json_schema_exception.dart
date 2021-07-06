import 'package:s3i_flutter/src/exceptions/parse_exception.dart';

/// Exception thrown when a json document (Entry) could not be parsed correctly.
class InvalidJsonSchemaException extends ParseException {
  /// The json document which triggers the parsing error (or a subset of it).
  String jsonDump;

  InvalidJsonSchemaException(String message, this.jsonDump) : super(message);

  @override
  String toString() {
    return "InvalidJsonSchemaException: $errorMessage | Try parsing: $jsonDump";
  }
}
