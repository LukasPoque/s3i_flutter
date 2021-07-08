class ClientIdentity {
  final String id;
  final String secret;

  ClientIdentity(this.id, this.secret);

  @override
  String toString() {
    return "Client($id, $secret)";
  }
}
