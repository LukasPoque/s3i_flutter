import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/max_retry_exception.dart';
import 'package:s3i_flutter/src/exceptions/network_response_exception.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

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
      this.maxRetryPickup = 100,
      this.retryWaitingTimeMilliSec = 200,
      List<String> scopes = const <String>[]})
      : super(clientIdentity, scopes: scopes);

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
  VoidCallback? onAuthSuccess;

  // TODO(poq): enable storage and loading of refresh token
  // Is invoked if a new refresh token is available. Could be used to store
  // the token in an external database.
  // Function(RefreshToken)? onNewRefreshToken;
  // void setRefreshToken(RefreshToken token){}

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
    if (_accessToken != null && _refreshToken != null) {
      //check if current _accessToken is valid
      if (_accessToken!.isNotExpired(timeBufferInSeconds: tokenValidBuffer)) {
        return _accessToken!;
      }
      //check if _refreshToken is valid and try to get a new access token
      if (_refreshToken!.isNotExpired(timeBufferInSeconds: tokenValidBuffer)) {
        final http.Response response =
            await http.post(refreshTokenEndpoint, headers: <String, String>{
          'content-type': 'application/x-www-form-urlencoded'
        }, body: <String, String>{
          JsonKey.grantType: JsonKey.refreshToken,
          JsonKey.clientId: clientIdentity.id,
          JsonKey.clientSecret: clientIdentity.secret,
          JsonKey.refreshToken: _refreshToken!.originalToken
        });
        if (response.statusCode == 200) {
          try {
            _parseAndSetTokenResponse(response.body);
            //_accessToken and _refreshToken should be valid if this is reached
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
    String authInit = '$authProxyBase${'/initialize/${clientIdentity.id}/'
        '${clientIdentity.secret}'}';
    if (scopes.isNotEmpty) authInit += '/${scopes.join(' ')}';
    //send start auth request to oAuthProxy
    http.Response response = await http.get(Uri.parse(authInit));
    if (response.statusCode != 200) throw NetworkResponseException(response);
    try {
      final Map<String, dynamic> initBody =
          jsonDecode(response.body) as Map<String, dynamic>;
      //check response
      if (initBody['redirect_url'] != null &&
          initBody['proxy_user_identifier'] != null &&
          initBody['proxy_secret'] != null) {
        //build url for interaction with the user and send it to the application
        final String authenticatorUrl =
            authProxyBase + initBody['redirect_url'].toString();
        await openUrlCallback(Uri.parse(authenticatorUrl));
        //start polling at pickup endpoint
        final String pollingUrl = "$authProxyBase${"/pickup/"
            "${initBody["proxy_user_identifier"].toString()}/"
            "${initBody["proxy_secret"].toString()}"}";
        final http.Client pickUpClient = http.Client();
        for (int i = 0; i < maxRetryPickup; i++) {
          response = await pickUpClient.get(Uri.parse(pollingUrl));
          await Future<dynamic>.delayed(
              Duration(milliseconds: retryWaitingTimeMilliSec));
          if (response.statusCode != 200)
            throw NetworkResponseException(response);
          try {
            _parseAndSetTokenResponse(response.body);
            //_accessToken and _refreshToken should be
            // valid if this code is reached
            if (onAuthSuccess != null) onAuthSuccess!();
            return _accessToken!;
            // TODO(poq): test _accessToken.isNotExpired
          } catch (e) {
            //answer doesn't includes the needed tokens
          }
        }
      } else {
        throw InvalidJsonSchemaException(
            'S3I-OAuthProxy returned invalid json', response.body);
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          'S3I-OAuthProxy returned invalid json (${e.toString()})',
          response.body);
    } on FormatException catch (e) {
      throw InvalidJsonSchemaException(
          'S3I-OAuthProxy returned invalid json (${e.toString()})',
          response.body);
    }
    throw MaxRetryException('Can not receive token bundle from OAuthProxy');
  }

  @override
  Future<bool> logout() {
    // TODO(poq): implement logout
    throw UnimplementedError();
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
    try {
      final Map<String, dynamic> jsonB =
          jsonDecode(tokenBundle) as Map<String, dynamic>;
      if (jsonB[JsonKey.accessToken] != null &&
          jsonB[JsonKey.refreshToken] != null) {
        try {
          _accessToken = AccessToken(jsonB[JsonKey.accessToken] as String);
          _refreshToken = RefreshToken(jsonB[JsonKey.refreshToken] as String);
        } on TypeError {
          throw const FormatException('Tokens in bundle are not Strings');
        }
        return;
      }
    } on TypeError {
      throw const FormatException('Token bundle could not be parsed to Map');
    }
    throw InvalidJsonSchemaException(
        'ParseTokenResponseBody error', tokenBundle);
  }
}
