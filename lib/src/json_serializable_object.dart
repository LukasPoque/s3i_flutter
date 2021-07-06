/// Base class for all classes which could be represented in json
abstract class JsonSerializableObject {
  Map<String, dynamic> toJson();
}
