import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';

/// This is a dummy class with no implementation if you build for WEB!
///
/// Uses the `flutter_appauth` package to obtain an access and refresh token.
///
/// This package is (currently) only suitable for iOS and Android. It uses the
/// official [AppAuth](https://appauth.io/) client SDKs for OpenId Connect.
///
/// See [Flutter Appauth](https://github.com/MaikuB/flutter_appauth/tree/master/flutter_appauth#android-setup)
/// for more information how to set up your app config files.
class AppAuthFlow extends AuthenticationManager {
  /// Creates a new [AppAuthFlow] object.
  AppAuthFlow(ClientIdentity clientIdentity,
      {List<String> scopes = const <String>[],
      String discoveryEndpoint = '',
      this.onNewRefreshToken,
      required this.redirectUrlScheme})
      : super(clientIdentity,
            scopes: scopes, discoveryEndpoint: discoveryEndpoint);

  /// The scheme used to redirect to after the login.
  ///
  /// Needs to be the same in here, in the app (android and ios config files)
  /// and in the redirecting uris in the S3I-IdentityProvider.
  final String redirectUrlScheme;

  /// Is invoked if a new refresh token is available. Could be used to store
  /// the token in an external database.
  Function(RefreshToken)? onNewRefreshToken;

  /// Overwrites the current [_refreshToken]. Could be used to set an older
  /// token from an external database. To receive new [RefreshToken]s see
  /// the [onNewRefreshToken] callback.
  // ignore: avoid_setters_without_getters
  set refreshToken(RefreshToken token) {
    throw UnsupportedError('AppAuthFlow is not available for this platform');
  }

  /// Returns a valid [AccessToken] for the [clientIdentity]
  /// which is at least valid for the time specified in [tokenValidBuffer].
  ///
  /// The default value for [tokenValidBuffer] is 10 seconds.
  ///
  /// Could throw a [S3IException] if appAuth returns something unexpected.
  /// Throws everything [FlutterAppAuth.token] or
  /// [FlutterAppAuth.authorizeAndExchangeCode] could throw.
  @override
  Future<AccessToken> getAccessToken({int tokenValidBuffer = 10}) async {
    throw UnsupportedError('AppAuthFlow is not available for this platform');
  }

  @override
  Future<bool> logout() async {
    throw UnsupportedError('AppAuthFlow is not available for this platform');
  }

  @override
  void setScopes(List<String> newScopes) {
    throw UnsupportedError('AppAuthFlow is not available for this platform');
  }
}
