import 'package:s3i_flutter/src/directory/link.dart';
import 'package:s3i_flutter/src/directory/value.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';
import 'package:s3i_flutter/src/directory/service.dart'; /// TODO(bek) added here

// TODO(poq): add S3I::Endpoints and S3I::Services

/// Represents an `Object` in the S3I-Directory data model.
class DirObject implements JsonSerializableObject {
  /// Creates a [DirObject] with the given [classString].
  DirObject(this.classString, {this.identifier, this.links, this.values, this.services}); //TODO(Bek): added here

  /// Creates a [DirObject] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [classString] (or other
  /// required keys) could not be found in the json. Throws a [TypeError]
  /// if the values couldn't be parsed as expected.
  factory DirObject.fromJson(Map<String, dynamic> json) {
    final String classString = json.containsKey(DirectoryKeys.classString)
        ? json[DirectoryKeys.classString] as String
        : throw JsonMissingKeyException(
            DirectoryKeys.classString, json.toString());
    final DirObject o = DirObject(classString)
      ..identifier = json[DirectoryKeys.identifier] as String?
      ..links = json.containsKey(DirectoryKeys.links)
          ? _createLinkList(json[DirectoryKeys.links] as List<dynamic>)
          : null
      ..values = json.containsKey(DirectoryKeys.values)
          ? _createValueList(json[DirectoryKeys.values] as List<dynamic>)
          : null
      ..services = json.containsKey(DirectoryKeys.services) ///TODO(Bek) Added here
          ? _createServiceList(json[DirectoryKeys.services] as List<dynamic>)
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

  /// The services provided ///TODO(Bek) added here
  List<Service>? services;

  /// Maps the [jsonList] to a [List<Service>]. ///TODO(bek) added here
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed to
  /// a Map<String, dynamic> or [Service.fromJson] throws this error. Throws a
  /// [JsonMissingKeyException] if a needed key is missing.
  static List<Service> _createServiceList(List<dynamic> jsonList) {
    return jsonList
        .map((dynamic service) => Service.fromJson(service as Map<String, dynamic>))
        .toList();
  }

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
    newJson[DirectoryKeys.classString] = classString;
    if (identifier != null) newJson[DirectoryKeys.identifier] = identifier;
    if (links != null) newJson[DirectoryKeys.links] = links;
    if (values != null) newJson[DirectoryKeys.values] = values;
    return newJson;
  }
}
