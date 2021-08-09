import 'package:s3i_flutter/src/exceptions/parse_exception.dart';

// TODO(poq): maybe saving the jsonDump is not so a good idea because it can
//  be big?

/// Exception thrown when a json document could not be parsed correctly.
class InvalidJsonSchemaException extends ParseException {
  /// Creates an [InvalidJsonSchemaException] with the given [message] and
  /// the encoded [jsonDump].
  InvalidJsonSchemaException(String message, this.jsonDump) : super(message);

  /// The json document which triggers the parsing error (or a subset of it).
  String jsonDump;

  @override
  String toString() {
    return 'InvalidJsonSchemaException: $errorMessage | Try parsing: $jsonDump';
  }
}
