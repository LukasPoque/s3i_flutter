/// Base class for all classes which could be represented in json
abstract class JsonSerializableObject {
  /// Returns the information stored in this object in a way the it could be
  /// encoded via `jsonEncode()`.
  Map<String, dynamic> toJson();
}
