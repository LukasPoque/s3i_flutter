import 'package:flutter/foundation.dart';

/// Represents an `Endpoint` in the S3I-Directory data model.
@immutable
class Endpoint {
  /// Creates an [Endpoint] with the given [endpoint].
  const Endpoint(this.endpoint);

  /// The endpoint of an thing in the S3I.
  final String endpoint;

  /// Returns the given [endpoint] parsed to an valid URI.
  ///
  /// Could throw [FormatException] if [URI.parse] couldn't parse the string.
  Uri getAsURI() {
    return Uri.parse(endpoint);
  }

  @override
  String toString() {
    return 'Endpoint($endpoint)';
  }
}
