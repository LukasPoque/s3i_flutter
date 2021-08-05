import 'package:s3i_flutter/src/exceptions/parse_exception.dart';

/// Exception thrown when a json document could not be parsed correctly.
class InvalidJsonSchemaException extends ParseException {
  /// Creates an [InvalidJsonSchemaException] with the given [fieldName] and
  /// the encoded [jsonDump].
  InvalidJsonSchemaException(String message, this.jsonDump) : super(message);

  /// The json document which triggers the parsing error (or a subset of it).
  String jsonDump;

  @override
  String toString() {
    return 'InvalidJsonSchemaException: $errorMessage | Try parsing: $jsonDump';
  }
}
