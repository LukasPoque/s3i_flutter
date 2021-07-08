import 'package:http/http.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

/// Exception thrown if a network request returned with an unexpected status code
class NetworkResponseException extends S3IException {
  final Response networkResponse;

  NetworkResponseException(this.networkResponse)
      : super(networkResponse.statusCode.toString());

  @override
  String toString() {
    String error = "NetworkResponseException: ${networkResponse.statusCode}";
    if (networkResponse.reasonPhrase != null)
      error += " | " + networkResponse.reasonPhrase!;
    return error;
  }
}
