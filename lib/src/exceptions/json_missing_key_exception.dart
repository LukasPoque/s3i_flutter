import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';

/// Exception thrown when a json document (Entry) is missing a key attribute
/// which is needed in the (f)ml40 structure.
class JsonMissingKeyException extends InvalidJsonSchemaException {
  /// Creates a [JsonMissingKeyException] with the given [fieldName] and
  /// the encoded [jsonDump].
  JsonMissingKeyException(String fieldName, String jsonDump)
      : super(fieldName, jsonDump);

  @override
  String toString() {
    return 'JsonMissingKeyException: Missing key: $errorMessage '
        '| Try parsing: $jsonDump';
  }
}
