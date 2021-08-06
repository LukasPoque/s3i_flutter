/// Represents a standalone parameter of a query-request
abstract class QueryParam {
  /// Returns the stored information in this [QueryParam] ready to use in a
  /// request.
  String generateString();
}
