import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

// TODO(poq): add S3I::Endpoints as attribute

/// Represents a `Value` in the S3I-Directory data model.
class Value implements JsonSerializableObject {
  /// Creates a [Value] tied to a [attribute] and filled with [value]s.
  Value(this.attribute, {this.value});

  /// Creates a [Value] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [attribute]
  /// could not be found in the json. Throws a [TypeError] if the values
  /// couldn't be parsed as string or List<String>.
  factory Value.fromJson(Map<String, dynamic> json) {
    final String attribute = json.containsKey(DirectoryKeys.attribute)
        ? json[DirectoryKeys.attribute] as String
        : throw JsonMissingKeyException(
            DirectoryKeys.attribute, json.toString());
    final Value v = Value(attribute)
      ..value = json.containsKey(DirectoryKeys.value)
          ? _createValueList(json[DirectoryKeys.value] as List<dynamic>)
          : null;
    return v;
  }

  /// The name (fml4.0 key) of this value object.
  final String attribute;

  /// The stored values associated with the attribute.
  List<String>? value;

  /// Maps the [jsonList] to a [List<String>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed to
  /// a string.
  static List<String> _createValueList(List<dynamic> jsonList) {
    return jsonList.map((dynamic val) => val.toString()).toList();
  }

  @override
  String toString() {
    return 'Value($attribute, $value)';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DirectoryKeys.attribute] = attribute;
    if (value != null) newJson[DirectoryKeys.value] = value;
    return newJson;
  }
}
