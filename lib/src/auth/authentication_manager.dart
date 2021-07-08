import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';

/// Base class for the different login approaches
abstract class AuthenticationManager {
  final ClientIdentity clientIdentity;
  List<String> scopes = [];
  //TODO: use discovery endpoint

  AuthenticationManager(this.clientIdentity);

  /// Returns a valid [AccessToken] for the [clientIdentity]
  /// which is at least valid for the time specified in [tokenValidBuffer].
  Future<AccessToken> getAccessToken({int tokenValidBuffer = 10});

  Future<bool> logout();

  /// Sets the [scopes] which are used for issuing a new token.
  /// If [newScopes] is NOT equals [scopes] both tokens are invalidated (doesn't mind the order of the scopes).
  void setScopes(List<String> newScopes);

  @override
  String toString() {
    return "AuthenticationManager($clientIdentity)";
  }
}
