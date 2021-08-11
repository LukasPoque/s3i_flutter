import 'dart:convert';

/// The number of different parts (divided by `.`) of a JWT
/// (header, payload, signature).
const int _jwtNumberOfParts = 3;

/// The json key used in the header to specify the type of the token.
const String _headerKeyTokenType = 'typ';

/// The corresponding value to [_headerKeyTokenType] in a valid JWT header.
const String _headerValueJwtTokenType = 'JWT';

/// The key for the token type in payload.
///
/// Bearer -> access token
/// Refresh -> refresh token
/// Offline -> offline token (special refresh token)
const String _payloadKeyType = 'typ';

/// The key for the expiring timestamp in payload.
const String _payloadKeyExpire = 'exp';

/// The key for the issued at timestamp in payload.
const String _payloadKeyIssued = 'iat';

/// The base class for all JWTs in the S3I.
///
/// From the [RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519):
/// > JSON Web Token (JWT) is a compact, URL-safe means of representing
/// > claims to be transferred between two parties.
///
/// Currently there are two different token types supported by the
/// S3I-IdentityProvider: [AccessToken] and [RefreshToken]. For more information
/// see [OpenID Connect](https://openid.net/connect/).
abstract class JsonWebToken {
  /// Creates a new [JsonWebToken].
  ///
  /// The [originalToken]-String should contain header, payload and
  /// the signature base64 encoded. Decodes the given input into the
  /// [decodedPayload].
  ///
  /// Throws [FormatException] if there are not 3 parts (header, payload,
  ///  signature) or the payload could not be decoded. Could be thrown if there
  ///  are other parsing errors too.
  JsonWebToken(this.originalToken) {
    final List<String> tokenParts = originalToken.split('.');
    if (tokenParts.length != _jwtNumberOfParts) {
      throw const FormatException('No valid JWT - missing parts');
    }
    final Map<String, dynamic> decodedHeader = _decodeBase64(tokenParts[0]);
    if (!decodedHeader.containsKey(_headerKeyTokenType)) {
      throw const FormatException('No token type in header');
    }
    if (decodedHeader[_headerKeyTokenType] != _headerValueJwtTokenType) {
      throw const FormatException('Wrong token type in header');
    }
    // TODO(poq): check header for "alg"
    // TODO(poq): validate signature/token -> throw InvalidTokenSignature
    decodedPayload =
        Map<String, dynamic>.unmodifiable(_decodeBase64(tokenParts[1]));
  }

  /// The complete original token with header, payload and signature.
  final String originalToken;

  /// The payload information stored in [originalToken] for easy access.
  ///
  /// This map is created in the constructor as unmodifiable map.
  late Map<String, dynamic> decodedPayload;

  /// Returns true if the token is still valid.
  ///
  /// Uses [getExpirationDate] to get the token validation time.
  ///
  /// You could use [timeBufferInSeconds] to add a safety zone in seconds. This
  /// is useful for network request since this is not instant and a token could
  /// be invalidated between the expired check and the check on the server side.
  /// The default value is 0 seconds.
  bool isNotExpired({int timeBufferInSeconds = 0}) {
    return (DateTime.now().difference(getExpirationDate())).inSeconds <
        timeBufferInSeconds;
  }

  /// Returns the exact moment when the token expires or the start of the epoch
  /// if the expiration date could not be found.
  DateTime getExpirationDate();

  /// Returns the duration from now until the token expires.
  Duration timeTillExpiration() {
    return getExpirationDate().difference(DateTime.now());
  }

  @override
  String toString() {
    return 'JsonWebToken($originalToken)';
  }

  /// Decodes the given [base64String] to a map with readable information.
  ///
  /// Throws a [FormatException] if the given string could not be decoded to
  /// a map.
  static Map<String, dynamic> _decodeBase64(String base64String) {
    try {
      final String inputNormalized = base64.normalize(base64String);
      final String inputString = utf8.decode(base64.decode(inputNormalized));
      final Map<String, dynamic> decodedInput =
          jsonDecode(inputString) as Map<String, dynamic>;
      return decodedInput;
    } catch (error) {
      throw const FormatException('Base64 string could not be parsed');
    }
  }
}

/// Represents an `Access Token` from OAuth2.0/OpenID Connect.
///
/// Used to grant access to protected resources like the S3I-Directory.
class AccessToken extends JsonWebToken {
  /// Creates a new [AccessToken] from the given string.
  ///
  /// The [originalToken]-String should contain header, payload and
  /// the signature base64 encoded. Calls super constructor.
  ///
  /// Throws [FormatException] if [JsonWebToken] constructor throws it and
  /// if the token type in the payload is not compatible with an access token.
  AccessToken(String originalToken) : super(originalToken) {
    if (!decodedPayload.containsKey(_payloadKeyType)) {
      throw const FormatException('Not type claim in payload');
    }
    if (decodedPayload[_payloadKeyType] != _payloadValueAccessTokenType) {
      throw const FormatException('Wrong type claim in payload');
    }
  }

  static const String _payloadValueAccessTokenType = 'Bearer';

  @override
  String toString() {
    return 'AccessToken($originalToken)';
  }

  @override
  DateTime getExpirationDate() {
    try {
      final int secSinceEpoch = decodedPayload[_payloadKeyExpire] as int;
      return DateTime.fromMillisecondsSinceEpoch(secSinceEpoch * 1000);
    } on TypeError {
      // this method shouldn't throw an exception return epoch start  as default
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}

/// Represents a `Refresh Token` from OAuth2.0/OpenID Connect.
///
/// Used to get a new [AccessToken] from the S3I-IdentityProvider without
/// authentication of the user with username/password. There are two types of
/// [RefreshToken] in the S3I: normal `Refresh Token` and `Offline Tokens`.
/// An Offline Token is a special Refresh Token with special rights and a longer
/// life time than normal a Refresh Token. To receive an Offline Token instead
/// of a Refresh Token add `offline_access` to the scopes of the
/// [AuthenticationManager]-Instance and ensure that your client has this
/// `scope` assigned.
class RefreshToken extends JsonWebToken {
  /// Creates a new [RefreshToken] from the given string.
  ///
  /// The [originalToken]-String should contain header, payload and
  /// the signature base64 encoded. Calls super constructor.
  ///
  /// Throws [FormatException] if [JsonWebToken] constructor throws it and
  /// if the token type in the payload is not compatible with an refresh token.
  RefreshToken(String originalToken) : super(originalToken) {
    if (!decodedPayload.containsKey(_payloadKeyType)) {
      throw const FormatException('Not type claim in payload');
    }
    if (decodedPayload[_payloadKeyType] != _payloadValueRefresh &&
        decodedPayload[_payloadKeyType] != _payloadValueOffline) {
      throw const FormatException('Wrong type claim in payload');
    }
  }

  static const String _payloadValueRefresh = 'Refresh';
  static const String _payloadValueOffline = 'Offline';
  static const Duration _offlineExpiringTime = Duration(days: 30);

  @override
  String toString() {
    return 'RefreshToken($originalToken)';
  }

  @override
  DateTime getExpirationDate() {
    if (decodedPayload[_payloadKeyType] == _payloadValueRefresh) {
      //refresh token
      try {
        final int secSinceEpoch = decodedPayload[_payloadKeyExpire] as int;
        return DateTime.fromMillisecondsSinceEpoch(secSinceEpoch * 1000);
      } on TypeError {
        // this method shouldn't throw an exception
        // return epoch start as default
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    } else {
      //offline token
      try {
        final int secSinceEpoch = decodedPayload[_payloadKeyIssued] as int;
        return DateTime.fromMillisecondsSinceEpoch(secSinceEpoch * 1000)
            .add(_offlineExpiringTime);
      } on TypeError {
        // this method shouldn't throw an exception
        // return epoch start as default
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }
  }
}
