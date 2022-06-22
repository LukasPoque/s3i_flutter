import 'dart:io';

import 'package:s3i_flutter/src/directory/link.dart';
import 'package:s3i_flutter/src/directory/property.dart';
import 'package:s3i_flutter/src/directory/value.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

// TODO(Bek): This was added (do we need it?)

/// Represents an `Object` in the S3I-Directory data model.
class EventObj implements JsonSerializableObject {
  /// Creates a [EventObj] with the given [description].
  EventObj(this.name, this.description, {this.properties});

  /// Creates a [EventObj] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [classString] (or other
  /// required keys) could not be found in the json. Throws a [TypeError]
  /// if the values couldn't be parsed as expected.
  factory EventObj.fromJson(String name, Map<String, dynamic> json) {

    final String description = json.containsKey(DirectoryKeys.description)
        ? json[DirectoryKeys.description] as String
        : throw JsonMissingKeyException(
        DirectoryKeys.description, json.toString());


    final Map<String, dynamic> schemaMap;
    if (json.containsKey(DirectoryKeys.schema)) {
      schemaMap =
      json[DirectoryKeys.schema] as Map<String, dynamic>;
    }
    else {
      throw JsonMissingKeyException(
          DirectoryKeys.schema, json.toString());
    }
    final EventObj o = EventObj(name,description)
      ..properties = schemaMap.containsKey(DirectoryKeys.properties)
          ? _createPropertyList(schemaMap[DirectoryKeys.properties] as Map<String,dynamic>)
          : null;
    return o;
  }

  ///Event name
  final String name;

  /// Each Event has a description
  final String description;

  /// The properties associated with this Event.
  List<Property>? properties;

  /// Maps the [jsonList] to a [List<Property>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed to
  /// a Map<String, dynamic> or [Property.fromJson] throws this error. Throws a
  /// [JsonMissingKeyException] if a needed key is missing.
  static List<Property> _createPropertyList(Map<String,dynamic> jsonMap) {
    return jsonMap.entries.map((e) => Property.fromJson(e.key, e.value as Map<String,dynamic>)).toList();
  }

  @override
  String toString() {
    return 'Object($description';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DirectoryKeys.description] = description;
    if (properties != null) newJson[DirectoryKeys.properties] = properties;
    return newJson;
  }

  bool operator ==(o) => o is EventObj && o.name == name && o.description == description;
}
