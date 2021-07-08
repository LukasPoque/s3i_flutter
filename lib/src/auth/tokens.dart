import 'package:jwt_decoder/jwt_decoder.dart';

abstract class Token {
  final String originalToken;
  late Map<String, dynamic> decodedToken;

  // throws FormatException if _originalToken is no valid JWT
  Token(this.originalToken) {
    decodedToken = JwtDecoder.decode(originalToken);
  }

  bool isNotExpired({int timeBufferInSeconds = 0}) {
    return (DateTime.now().difference(getExpirationDate())).inSeconds <
        timeBufferInSeconds;
  }

  DateTime getExpirationDate() {
    return JwtDecoder.getExpirationDate(originalToken);
  }

  @override
  String toString() {
    return "JsonWebToken($originalToken)";
  }
}

//TODO: validate token type
class AccessToken extends Token {
  AccessToken(String originalToken) : super(originalToken);

  @override
  String toString() {
    return "AccessToken($originalToken)";
  }
}

class RefreshToken extends Token {
  RefreshToken(String originalToken) : super(originalToken);

  @override
  String toString() {
    return "RefreshToken($originalToken)";
  }
}
