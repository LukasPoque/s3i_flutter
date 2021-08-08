import 'package:s3i_flutter/src/directory/link.dart';
import 'package:s3i_flutter/src/directory/value.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

// TODO(poq): add S3I::Endpoints and S3I::Services

/// Represents an `Object` in the S3I-Directory data model.
class DirObject implements JsonSerializableObject {
  /// Creates a [DirObject] with the given [classString].
  DirObject(this.classString, {this.identifier, this.links, this.values});

  /// Creates a [DirObject] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [classString] (or other
  /// required keys) could not be found in the json. Throws a [TypeError]
  /// if the values couldn't be parsed as expected.
  factory DirObject.fromJson(Map<String, dynamic> json) {
    final String classString = json.containsKey(JsonKey.classString)
        ? json[JsonKey.classString] as String
        : throw JsonMissingKeyException(JsonKey.classString, json.toString());
    final DirObject o = DirObject(classString)
      ..identifier = json[JsonKey.identifier] as String?
      ..links = json.containsKey(JsonKey.links)
          ? _createLinkList(json[JsonKey.links] as List<dynamic>)
          : null
      ..values = json.containsKey(JsonKey.values)
          ? _createValueList(json[JsonKey.values] as List<dynamic>)
          : null;
    return o;
  }

  /// The fml4.0 key / name of this object.
  final String classString;

  /// An optional identifier for this object to differentiate between them if
  /// there are multiple same class keys in one entry.
  String? identifier;

  /// The links associated with this object.
  List<Link>? links;

  /// The values associated with this object.
  List<Value>? values;

  /// Maps the [jsonList] to a [List<Link>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed to
  /// a Map<String, dynamic> or [Link.fromJson] throws this error. Throws a
  /// [JsonMissingKeyException] if a needed key is missing.
  static List<Link> _createLinkList(List<dynamic> jsonList) {
    return jsonList
        .map((dynamic linkE) => Link.fromJson(linkE as Map<String, dynamic>))
        .toList();
  }

  /// Maps the [jsonList] to a [List<Value>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed to
  /// a Map<String, dynamic> or [Value.fromJson] throws this error. Throws a
  /// [JsonMissingKeyException] if a needed key is missing.
  static List<Value> _createValueList(List<dynamic> jsonList) {
    return jsonList
        .map((dynamic valueE) => Value.fromJson(valueE as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'Object($classString, $identifier, $links, $values)';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[JsonKey.classString] = classString;
    if (identifier != null) newJson[JsonKey.identifier] = identifier;
    if (links != null) newJson[JsonKey.links] = links;
    if (values != null) newJson[JsonKey.values] = values;
    return newJson;
  }
}
