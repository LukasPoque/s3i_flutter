import 'package:http/http.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

/// Exception thrown if a network request returned with an unexpected
/// status code
class NetworkResponseException extends S3IException {
  /// Creates a [NetworkResponseException] from the given [networkResponse].
  NetworkResponseException(this.networkResponse)
      : super(networkResponse.statusCode.toString());

  /// The network response which doesn't match the expected result.
  final Response networkResponse;

  @override
  String toString() {
    String error = 'NetworkResponseException: ${networkResponse.statusCode}';
    if (networkResponse.reasonPhrase != null)
      error += ' | ${networkResponse.reasonPhrase!}';
    return error;
  }
}
