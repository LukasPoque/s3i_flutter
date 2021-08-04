import 'package:s3i_flutter/s3i_flutter.dart';

class MaxRetryException extends S3IException {
  MaxRetryException(String errorMessage) : super(errorMessage);

  @override
  String toString() {
    return "MaxRetryException: $errorMessage";
  }
}
