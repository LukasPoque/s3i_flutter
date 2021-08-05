import 'package:flutter/foundation.dart';

/// Represents a simple `Client` in the OpenID-Connect terms for authentication
/// at the S3I-IdentityProvider.
@immutable
class ClientIdentity {
  /// Creates a [ClientIdentity] with the given [id] and the [secret] which
  /// could be empty if the client is a public client.
  const ClientIdentity(this.id, {this.secret = ''});

  /// The id of the client, starts often with `s3i:` in the S3I.
  final String id;

  /// The secret of the client, is an empty string if the client is `public`.
  final String secret;

  @override
  String toString() {
    return 'Client($id, $secret)';
  }
}
