import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

// TODO(poq): add S3I::Endpoints as attribute

/// Represents a `Value` in the S3I-Directory data model.
class Property implements JsonSerializableObject {
  /// Creates a [Property] tied to a [attribute] and filled with [value]s.
  Property(this.name, this.type);

  /// Creates a [Property] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [attribute]
  /// could not be found in the json. Throws a [TypeError] if the values
  /// couldn't be parsed as string or List<String>.
  factory Property.fromJson(String name , Map<String, dynamic> json) {

    final String type = json.containsKey(DirectoryKeys.thingType)
        ? json[DirectoryKeys.thingType] as String
        : throw JsonMissingKeyException(
        DirectoryKeys.thingType, json.toString());
    final Property p = Property(name, type);
    return p;
  }

  /// The name (fml4.0 key) of this value object.
  final String name;

  /// The stored values associated with the attribute.
  final String type;

  /// Maps the [jsonList] to a [List<String>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed to
  /// a string.
  static List<String> _createValueList(List<dynamic> jsonList) {
    return jsonList.map((dynamic val) => val.toString()).toList();
  }

  @override
  String toString() {
    return 'Value($name, $type)';
  }

  /// TODO(Bek): name should be parent attribute of type
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DirectoryKeys.name] = name;
    if (type != null) newJson[DirectoryKeys.value] = type;
    return newJson;
  }
}
