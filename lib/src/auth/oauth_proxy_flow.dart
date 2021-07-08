import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/client_identity.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/exceptions/max_retry_exception.dart';
import 'package:s3i_flutter/src/exceptions/network_response_exception.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// Uses the S3I-OAuthProxy to obtain a access and refresh token.
/// Does not refreshes the token automatically, only if [getAccessToken] is called and the accessToken is expired.
class OAuthProxyFlow extends AuthenticationManager {
  /// Number of retries (100) to pickup the token bundle from the OAuthProxy
  static final int maxRetryPickup = 100;
  AccessToken? _accessToken;
  RefreshToken? _refreshToken;
  final Uri refreshTokenEndpoint = Uri.parse(
      "https://idp.s3i.vswf.dev/auth/realms/KWH/protocol/openid-connect/token");
  final String authProxyBase = "https://auth.s3i.vswf.dev";

  /// Is invoked when the OAuthProxyFlow needs to redirect to the S3I-OAuthProxy website
  Function(Uri) openUrlCallback;

  /// Is invoked if the user is authenticated correctly
  VoidCallback? onAuthSuccess;

  //TODO: enable storage and loading of refresh token
  // Is invoked if a new refresh token is available. Could be used to store the token in an external database.
  // Function(RefreshToken)? onNewRefreshToken;
  // void setRefreshToken(RefreshToken token){}

  OAuthProxyFlow(ClientIdentity clientIdentity, this.openUrlCallback,
      {this.onAuthSuccess})
      : super(clientIdentity);

  /// Returns a valid AccessToken for the [_clientIdentity]
  ///
  /// which is at least valid for the time specified in [tokenValidBuffer].
  /// Throws [NetworkResponseException] if the OAuthProxy returns a bad status code.
  /// Throws [InvalidJsonSchemaException] if the response from the OAuthProxy is invalid.
  /// Throws [MaxRetryException] if the
  @override
  Future<AccessToken> getAccessToken({int tokenValidBuffer = 10}) async {
    if (_accessToken != null && _refreshToken != null) {
      //check if current _accessToken is valid
      if (_accessToken!.isNotExpired(timeBufferInSeconds: tokenValidBuffer)) {
        return _accessToken!;
      }
      //check if _refreshToken is valid and try to get a new access token
      if (_refreshToken!.isNotExpired(timeBufferInSeconds: tokenValidBuffer)) {
        var response = await http.post(refreshTokenEndpoint, headers: {
          HttpHeaders.contentTypeHeader: "application/x-www-form-urlencoded"
        }, body: {
          JsonKey.grantType: "refresh_token",
          JsonKey.clientId: clientIdentity.id,
          JsonKey.clientSecret: clientIdentity.secret,
          JsonKey.refreshToken: _refreshToken!.originalToken
        });
        if (response.statusCode == 200) {
          try {
            _parseTokenResponseBody(response.body);
            //_accessToken and _refreshToken should be valid if this code is reached
            return _accessToken!;
            //TODO: test _accessToken.isNotExpired
          } catch (e) {
            //ignore errors in favor of full flow
          }
        }
        //something went wrong while refreshing token -> try full flow
      }
    }
    //full flow
    String authInit = authProxyBase +
        "/initialize/${clientIdentity.id}/${clientIdentity.secret}";
    if (scopes.isNotEmpty) authInit += "/" + scopes.join(" ");
    //send start auth request to oAuthProxy
    var response = await http.post(Uri.parse(authInit));
    if (response.statusCode != 200) throw NetworkResponseException(response);
    try {
      final Map<String, dynamic> initBody = jsonDecode(response.body);
      //check response
      if (initBody["redirect_url"] != null &&
          initBody["proxy_user_identifier"] != null &&
          initBody["proxy_secret"] != null) {
        //build url for interaction with the user and send it to the application
        final authenticatorUrl =
            authProxyBase + initBody["redirect_url"].toString();
        openUrlCallback(Uri.parse(authenticatorUrl));
        //start polling at pickup endpoint
        final pollingUrl = authProxyBase +
            "/pickup/${initBody["proxy_user_identifier"].toString()}/${initBody["proxy_secret"].toString()}";
        final pickUpClient = http.Client();
        for (int i = 0; i < maxRetryPickup; i++) {
          response = await pickUpClient.post(Uri.parse(pollingUrl));
          if (response.statusCode != 200)
            throw NetworkResponseException(response);
          try {
            _parseTokenResponseBody(response.body);
            //_accessToken and _refreshToken should be valid if this code is reached
            return _accessToken!;
            //TODO: test _accessToken.isNotExpired
          } catch (e) {
            //answer doesn't includes the needed tokens
          }
        }
      } else {
        throw InvalidJsonSchemaException(
            "S3I-OAuthProxy returned invalid json", response.body);
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          "S3I-OAuthProxy returned invalid json (${e.toString()})", response.body);
    } on FormatException catch (e) {
      throw InvalidJsonSchemaException(
          "S3I-OAuthProxy returned invalid json (${e.toString()})", response.body);
    }
    throw MaxRetryException("Can't receive token bundle from OAuthProxy");
  }

  @override
  Future<bool> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  void setScopes(List<String> newScopes) {
    bool needReset = newScopes.length != scopes.length;
    if (!needReset) {
      for (String scope in newScopes) {
        needReset = !scopes.contains(scope);
        if (needReset) break;
      }
    }
    if (needReset) {
      scopes = newScopes;
      _invalidateLoginState();
    }
  }

  /// Invalidates the login state by setting [_accessToken] and [_refreshToken] to `null`.
  void _invalidateLoginState() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Tries to parse [tokenBundle] to [_accessToken] and [_refreshToken].
  ///
  /// Could throw [InvalidJsonSchemaException], [FormatException] and [TypeError].
  void _parseTokenResponseBody(String tokenBundle) {
    final Map<String, dynamic> jsonB = jsonDecode(tokenBundle);
    if (jsonB["access_token"] != null && jsonB["refresh_token"] != null) {
      _accessToken = jsonB["access_token"];
      _refreshToken = jsonB["refresh_token"];
      return;
    }
    throw InvalidJsonSchemaException(
        "_parseTokenResponseBody error", tokenBundle);
  }
}
