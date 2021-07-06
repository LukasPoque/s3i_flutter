import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// Represents a Value in the S3I-Directory Data Model.
/// needs an attribute name
class Value implements JsonSerializableObject {
  String attribute;
  List<String>? value;

  //TODO: add S3I::Endpoints as attribute

  Value(this.attribute);

  static Value fromJson(Map<String, dynamic> json) {
    String attribute = json.containsKey(JsonKey.attribute)
        ? json[JsonKey.attribute]
        : throw JsonMissingKeyException(JsonKey.attribute, json.toString());
    Value v = Value(attribute);
    v.value = json.containsKey(JsonKey.value)
        ? _createValueList(json[JsonKey.value])
        : null;
    return v;
  }

  static List<String> _createValueList(List<dynamic> jsonList) {
    return jsonList.map((val) => val.toString()).toList();
  }

  @override
  String toString() {
    return "Value($attribute, $value)";
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.attribute] = attribute;
    if (value != null) newJson[JsonKey.value] = value;
    return newJson;
  }
}
