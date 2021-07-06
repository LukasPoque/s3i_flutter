import 'package:s3i_flutter/src/directory/dir_object.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// Represents a Link in the S3I-Directory Data Model.
/// needs an association name
class Link implements JsonSerializableObject {
  String association;
  DirObject? target;

  //TODO: add S3I::TargetThing

  Link(this.association);

  factory Link.fromJson(Map<String, dynamic> json) {
    String association = json.containsKey(JsonKey.association)
        ? json[JsonKey.association]
        : throw JsonMissingKeyException(JsonKey.association, json.toString());
    Link l = Link(association);
    l.target = json.containsKey(JsonKey.target)
        ? DirObject.fromJson(json[JsonKey.target])
        : null;
    return l;
  }

  @override
  String toString() {
    return "Link($association, $target)";
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.association] = association;
    if (target != null) newJson[JsonKey.target] = target!.toJson();
    return newJson;
  }
}
