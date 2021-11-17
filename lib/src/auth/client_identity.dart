import 'package:flutter/foundation.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';

/// Represents a simple `Client` in the OpenID-Connect terms for authentication
/// at the S3I-IdentityProvider.
@immutable
class ClientIdentity {
  /// Creates a [ClientIdentity] with the given [id] and the [secret] which
  /// could be empty if the client is a public client.
  const ClientIdentity(this.id, {this.secret = ''});

  /// Creates a [ClientIdentity] with the [id] and the [secret] stored in the
  /// [jsonMap].
  ///
  /// This is used to parse the answer from the S3I-Config.
  ///
  /// Could throw an [InvalidJsonSchemaException] if an attribute is not a valid
  /// String.
  factory ClientIdentity.fromJson(Map<String, dynamic> jsonMap) {
    try {
      String id;
      String secret;
      jsonMap.containsKey('identifier')
          ? id = jsonMap['identifier'] as String
          : throw JsonMissingKeyException('identifier', jsonMap.toString());
      jsonMap.containsKey('secret')
          ? secret = jsonMap['secret'] as String
          : throw JsonMissingKeyException('secret', jsonMap.toString());
      return ClientIdentity(id, secret: secret);
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), jsonMap.toString());
    }
  }

  /// The id of the client, starts often with `s3i:` in the S3I.
  final String id;

  /// The secret of the client, is an empty string if the client is `public`.
  final String secret;

  @override
  String toString() {
    return 'Client($id, $secret)';
  }
}
