import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

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
            scopes: scopes, discoveryEndpoint: discoveryEndpoint) {
    _appAuth = FlutterAppAuth();
  }

  /// The last issued [AccessToken] which matches the [clientIdentity] and
  /// [scopes].
  AccessToken? _accessToken;

  /// The last issued [RefreshToken] which matches the [clientIdentity] and
  /// [scopes].
  RefreshToken? _refreshToken;

  /// The [FlutterAppAuth] object used to obtain tokens.
  late FlutterAppAuth _appAuth;

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
    _refreshToken = token;
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
    if (_accessToken != null) {
      //check if current _accessToken is valid
      if (_accessToken!.isNotExpired(timeBufferInSeconds: tokenValidBuffer)) {
        return _accessToken!;
      }
    }
    if (_refreshToken != null) {
      //check if _refreshToken is valid and try to get a new access token
      if (_refreshToken!.isNotExpired(timeBufferInSeconds: tokenValidBuffer)) {
        // refresh token
        final TokenResponse? result = await _appAuth.token(TokenRequest(
            clientIdentity.id, redirectUrlScheme,
            clientSecret: clientIdentity.secret,
            discoveryUrl: discoveryEndpoint,
            refreshToken: _refreshToken!.originalToken,
            scopes: scopes));
        if (result != null) {
          if (result.accessToken != null && result.refreshToken != null) {
            _accessToken = AccessToken(result.accessToken!);
            _refreshToken = RefreshToken(result.refreshToken!);
            if (onNewRefreshToken != null) onNewRefreshToken!(_refreshToken!);
            return _accessToken!;
            // TODO(poq): test _accessToken.isNotExpired
          }
        }
      }
    }
    // new full authentication is needed
    final AuthorizationTokenResponse? result =
        await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        clientIdentity.id,
        redirectUrlScheme,
        clientSecret: clientIdentity.secret,
        discoveryUrl: discoveryEndpoint,
        scopes: scopes,
      ),
    );
    if (result == null || result.accessToken == null) {
      // something went wrong
      throw S3IException('Can not authenticate the user - empty response');
    }
    if (result.refreshToken != null) {
      _refreshToken = RefreshToken(result.refreshToken!);
      if (onNewRefreshToken != null) onNewRefreshToken!(_refreshToken!);
    }
    _accessToken = AccessToken(result.accessToken!);
    return _accessToken!;
  }

  @override
  Future<bool> logout() async {
    // TODO(poq): implement logout
    //throw UnimplementedError();
    _invalidateLoginState();
    return true;
  }

  @override
  void setScopes(List<String> newScopes) {
    bool needReset = newScopes.length != scopes.length;
    if (!needReset) {
      for (final String scope in newScopes) {
        needReset = !scopes.contains(scope);
        if (needReset) break;
      }
    }
    if (needReset) {
      scopes = newScopes;
      _invalidateLoginState();
    }
  }

  /// Invalidates the local login state by setting [_accessToken] and
  /// [_refreshToken] to `null`.
  void _invalidateLoginState() {
    _accessToken = null;
    _refreshToken = null;
  }
}
