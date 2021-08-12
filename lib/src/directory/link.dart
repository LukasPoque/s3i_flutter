import 'package:s3i_flutter/src/directory/dir_object.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

// TODO(poq): add S3I::TargetThing

/// Represents a `Link` in the S3I-Directory data model.
class Link implements JsonSerializableObject {
  /// Creates a new [Link] with the [association] and an optional [target].
  Link(this.association, {this.target});

  /// Creates a [Link] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [association]
  /// could not be found in the json. Throws a [TypeError] if the target
  /// couldn't be parsed correctly.
  factory Link.fromJson(Map<String, dynamic> json) {
    final String association = json.containsKey(DirectoryKeys.association)
        ? json[DirectoryKeys.association] as String
        : throw JsonMissingKeyException(
            DirectoryKeys.association, json.toString());
    final Link l = Link(association)
      ..target = json.containsKey(DirectoryKeys.target)
          ? DirObject.fromJson(
              json[DirectoryKeys.target] as Map<String, dynamic>)
          : null;
    return l;
  }

  /// The type of the association between the [target] and the parent.
  ///
  /// This should be a fml4.0 key (most cases: `features`, `roles`).
  final String association;

  /// The target of this association.
  DirObject? target;

  @override
  String toString() {
    return 'Link($association, $target)';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DirectoryKeys.association] = association;
    if (target != null) newJson[DirectoryKeys.target] = target!.toJson();
    return newJson;
  }
}
