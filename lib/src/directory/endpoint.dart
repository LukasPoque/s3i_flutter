/// Represents an Endpoint in the S3I-Directory Data Model.
class Endpoint {
  String endpoint;

  Endpoint(this.endpoint);

  Uri getAsURI() {
    return Uri.parse(endpoint);
  }

  @override
  String toString() {
    return "Endpoint($endpoint)";
  }
}
