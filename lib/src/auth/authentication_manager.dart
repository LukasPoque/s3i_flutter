import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';

/// Base class for the different authentication approaches to
/// the S3I-IdentityProvider.
abstract class AuthenticationManager {
  /// Creates an [AuthenticationManager] with the given [clientIdentity] and
  /// the given [scopes] (with an empty list as default).
  AuthenticationManager(this.clientIdentity, {this.scopes = const <String>[]});

  /// The identity used to issue tokens at the IdP.
  final ClientIdentity clientIdentity;

  /// All scopes which are added to the auth request.
  ///
  /// Is an empty map as default.
  List<String> scopes;

  // TODO(poq): save/use discovery endpoint (information)

  /// Returns a valid [AccessToken] for the [clientIdentity]
  /// which is at least valid for the time specified in [tokenValidBuffer].
  ///
  /// The default value for [tokenValidBuffer] is 10 seconds.
  Future<AccessToken> getAccessToken({int tokenValidBuffer = 10});

  /// Deletes old tokens and invalidates the token session at the IdP.
  Future<bool> logout();

  /// Sets the [scopes] which are used for issuing a new token.
  /// If [newScopes] is NOT equals [scopes] both tokens are invalidated
  /// (doesn't mind the order of the scopes).
  void setScopes(List<String> newScopes);

  @override
  String toString() {
    return 'AuthenticationManager($clientIdentity, $scopes)';
  }
}
