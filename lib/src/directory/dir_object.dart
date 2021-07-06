import 'package:s3i_flutter/src/directory/link.dart';
import 'package:s3i_flutter/src/directory/value.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// Represents an Object in the S3I-Directory Data Model.
/// needs a classString name
class DirObject implements JsonSerializableObject {
  String classString;
  String? identifier;
  List<Link>? links;
  List<Value>? values;

  //TODO: add S3I::Endpoints and S3I::Services

  DirObject(this.classString);

  factory DirObject.fromJson(Map<String, dynamic> json) {
    String classString = json.containsKey(JsonKey.classString)
        ? json[JsonKey.classString]
        : throw JsonMissingKeyException(JsonKey.classString, json.toString());
    DirObject o = DirObject(classString);
    o.identifier = json[JsonKey.identifier];
    o.links = json.containsKey(JsonKey.links)
        ? _createLinkList(json[JsonKey.links])
        : null;
    o.values = json.containsKey(JsonKey.values)
        ? _createValueList(json[JsonKey.values])
        : null;
    return o;
  }

  static List<Link> _createLinkList(List<dynamic> jsonList) {
    return jsonList.map((linkE) => Link.fromJson(linkE)).toList();
  }

  static List<Value> _createValueList(List<dynamic> jsonList) {
    return jsonList.map((valueE) => Value.fromJson(valueE)).toList();
  }

  @override
  String toString() {
    return "Object($classString, $identifier, $links, $values)";
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.classString] = classString;
    if (identifier != null) newJson[JsonKey.identifier] = identifier;
    if (links != null) newJson[JsonKey.links] = links;
    if (values != null) newJson[JsonKey.values] = values;
    return newJson;
  }
}
