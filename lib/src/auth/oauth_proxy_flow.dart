import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/max_retry_exception.dart';
import 'package:s3i_flutter/src/exceptions/network_response_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// Uses the `S3I-OAuthProxy` to obtain an access and refresh token.
///
/// Does not refreshes the token automatically, only if [getAccessToken] is
/// called and the accessToken is expired.
///
/// Make sure that your client allows redirecting to the S3I-OAuthProxy
/// by adding `https://auth.s3i.vswf.dev/*` to the redirecting uris in the
/// S3I-IdentityProvider.
class OAuthProxyFlow extends AuthenticationManager {
  /// Creates a new [OAuthProxyFlow] object.
  OAuthProxyFlow(ClientIdentity clientIdentity,
      {required this.openUrlCallback,
      this.onAuthSuccess,
      this.onNewRefreshToken,
      this.maxRetryPickup = 100,
      this.retryWaitingTimeMilliSec = 200,
      List<String> scopes = const <String>[],
      String discoveryEndpoint = ''})
      : super(clientIdentity,
            scopes: scopes, discoveryEndpoint: discoveryEndpoint);

  // TODO(poq): use the discovery endpoint

  /// The last issued [AccessToken] which matches the [clientIdentity] and
  /// [scopes].
  AccessToken? _accessToken;

  /// The last issued [RefreshToken] which matches the [clientIdentity] and
  /// [scopes].
  RefreshToken? _refreshToken;

  /// Number of retries (default: 100) to pickup the token bundle from
  /// the OAuthProxy endpoint.
  final int maxRetryPickup;

  /// Delay between each retry (default: 200ms).
  ///
  /// This time * [maxRetryPickup] is the maximum time the user should
  /// take to login.
  final int retryWaitingTimeMilliSec;

  /// Token endpoint of the S3I IdentityProvider.
  final Uri refreshTokenEndpoint = Uri.parse(
      'https://idp.s3i.vswf.dev/auth/realms/KWH/protocol/openid-connect/token');

  /// Base url of the S3I-OAuthProxy.
  final String authProxyBase = 'https://auth.s3i.vswf.dev';

  /// Is invoked when the OAuthProxyFlow needs to redirect to the
  /// S3I-OAuthProxy website.
  Future<void> Function(Uri) openUrlCallback;

  /// Is invoked if the user is authenticated correctly.
  ///
  /// Is called everytime the [_accessToken] is changed.
  Function(AccessToken)? onAuthSuccess;

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
  /// Throws [NetworkResponseException] if the OAuthProxy returns a
  /// bad status code. Throws [InvalidJsonSchemaException] if the response
  /// from the OAuthProxy is invalid. Throws [MaxRetryException] if there is
  /// no token bundle at the OAuthProxy after [maxRetryPickup] exceeded.
  /// Could throw [FormatException] if the token could not be parsed correctly.
  /// If there is no internet connection a [SocketException] is thrown.
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
        final http.Response response =
            await http.post(refreshTokenEndpoint, headers: <String, String>{
          'content-type': 'application/x-www-form-urlencoded'
        }, body: <String, String>{
          KeycloakKeys.grantType: KeycloakKeys.refreshToken,
          KeycloakKeys.clientId: clientIdentity.id,
          KeycloakKeys.clientSecret: clientIdentity.secret,
          KeycloakKeys.refreshToken: _refreshToken!.originalToken
        });
        if (response.statusCode == 200) {
          try {
            _parseAndSetTokenResponse(response.body);
            //_accessToken and _refreshToken should be valid if this is reached
            if (onNewRefreshToken != null) onNewRefreshToken!(_refreshToken!);
            if (onAuthSuccess != null) onAuthSuccess!(_accessToken!);
            return _accessToken!;
            // TODO(poq): test _accessToken.isNotExpired
          } catch (e) {
            //ignore errors in favor of full flow
          }
        }
        //something went wrong while refreshing token -> try full flow
      }
    }
    //full flow
    _invalidateLoginState();
    final Uri pollingUrl = await _initializeOAuthProxy();
    final http.Client pickUpClient = http.Client();
    for (int i = 0; i < maxRetryPickup; i++) {
      final http.Response response = await pickUpClient.get(pollingUrl);
      if (response.statusCode != 200) {
        pickUpClient.close();
        throw NetworkResponseException(response);
      }
      try {
        _parseAndSetTokenResponse(response.body);
        //_accessToken and _refreshToken should be
      } catch (e) {
        //answer doesn't includes the needed tokens
        await Future<dynamic>.delayed(
            Duration(milliseconds: retryWaitingTimeMilliSec));
        continue;
      }
      // valid if this code is reached
      if (onNewRefreshToken != null) onNewRefreshToken!(_refreshToken!);
      if (onAuthSuccess != null) onAuthSuccess!(_accessToken!);
      pickUpClient.close();
      return _accessToken!;
    }
    // TODO(poq): test _accessToken.isNotExpired
    pickUpClient.close();
    throw MaxRetryException('Can not receive token bundle from OAuthProxy');
  }

  Future<Uri> _initializeOAuthProxy() async {
    String authInit = '$authProxyBase${'/initialize/${clientIdentity.id}/'
        '${clientIdentity.secret}'}';
    if (scopes.isNotEmpty) {
      authInit += '/${scopes.join(' ')}';
    }
    final http.Response response = await http.get(Uri.parse(authInit));
    if (response.statusCode != 200) {
      throw NetworkResponseException(response);
    }

    late Map<String, dynamic> initBody;

    try {
      //send start auth request to oAuthProxy
      initBody = jsonDecode(response.body) as Map<String, dynamic>;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          'S3I-OAuthProxy returned invalid json, expected object '
          '(${e.toString()})',
          response.body);
    } on FormatException catch (e) {
      throw InvalidJsonSchemaException(
          'S3I-OAuthProxy returned invalid json (${e.toString()})',
          response.body);
    }

    //check response
    if (initBody['redirect_url'] != null &&
        initBody['proxy_user_identifier'] != null &&
        initBody['proxy_secret'] != null) {
      //build url for interaction with the user and send it to the application
      // Value Error
      final String authenticatorUrl =
          authProxyBase + initBody['redirect_url'].toString();
      // Could return null
      await openUrlCallback(Uri.parse(authenticatorUrl));
      //start polling at pickup endpoint
      // Value error
      final String pollingUrl = "$authProxyBase${"/pickup/"
          "${initBody["proxy_user_identifier"].toString()}/"
          "${initBody["proxy_secret"].toString()}"}";

      return Uri.parse(pollingUrl);
    } else {
      throw InvalidJsonSchemaException(
          'S3I-OAuthProxy missing at least one required fields ("redirect_url",'
          ' "proxy_user_identifier", "proxy_secret")',
          response.body);
    }
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

  /// Tries to parse [tokenBundle] to an [AccessToken] and a [RefreshToken]
  /// and sets the values to [_accessToken] and [_refreshToken].
  ///
  /// Could throw [InvalidJsonSchemaException] and [FormatException].
  void _parseAndSetTokenResponse(String tokenBundle) {
    late Map<String, dynamic> jsonB;
    try {
      jsonB = jsonDecode(tokenBundle) as Map<String, dynamic>;
    } on TypeError {
      throw const FormatException('Token bundle could not be parsed to Map');
    }
    if (jsonB[KeycloakKeys.accessToken] == null ||
        jsonB[KeycloakKeys.refreshToken] == null) {
      throw InvalidJsonSchemaException(
          'ParseTokenResponseBody error', tokenBundle);
    }
    try {
      _accessToken = AccessToken(jsonB[KeycloakKeys.accessToken] as String);
      _refreshToken = RefreshToken(jsonB[KeycloakKeys.refreshToken] as String);
    } on TypeError {
      throw const FormatException('Tokens in bundle are not Strings');
    }
    return;
  }
}
