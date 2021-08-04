import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/policy/policy_subject.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// The type of a granted/revoked permission.
///
/// Currently supported:
/// - [PermissionType.read]
/// - [PermissionType.write]
/// - [PermissionType.execute]
///
/// For further information see:
/// https://www.eclipse.org/ditto/basic-policy.html#grant-and-revoke-some-permission
enum PermissionType { read, write, execute }

/// The protected *Resource* of a ditto policy group.
///
/// This defines to which part of a ditto entry the corresponding [PolicySubject]
/// has which permissions granted/revoked.
/// For more information see:
/// https://www.eclipse.org/ditto/basic-policy.html#which-resources-can-be-controlled
class PolicyResource implements JsonSerializableObject {
  PolicyResource(this.path,
      {Set<PermissionType>? grants, Set<PermissionType>? revokes}) {
    grant = {...?grants};
    revoke = {...?revokes};
  }

  /// The path to the resource.
  ///
  /// This could be something general like `policy:/` or a mor specific path
  /// like `thing:/features/featureX/properties/location`.
  final String path;

  /// The allowed actions on this resource.
  ///
  /// See [PermissionType] for what is supported.
  late Set<PermissionType> grant;

  /// The permitted actions on this resource.
  ///
  /// See [PermissionType] for what is supported.
  late Set<PermissionType> revoke;

  /// Returns a [PolicyResource] with the [path]
  /// and enriches it with the given information in [json].
  ///
  /// Throws an [InvalidJsonSchemaException] if [json] could not be parsed to
  /// valid [grant] and [revoke] parameters.
  factory PolicyResource.fromJson(String path, Map<String, dynamic> json) {
    PolicyResource pR = PolicyResource(path);
    try {
      if (json.containsKey(JsonKey.grant)) {
        pR.grant = _createPermissionSet(json[JsonKey.grant]);
      }
      if (json.containsKey(JsonKey.revoke)) {
        pR.revoke = _createPermissionSet(json[JsonKey.revoke]);
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
    return pR;
  }

  /// Returns the stored information about this [PolicyResource] in a [Map]
  /// which could be directly used to creates a json entry.
  ///
  /// Stores [grant] and [revoke] in the [Map].
  /// The [Map] is empty if both [Set]s don't contains entries.
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.grant] = _createPermissionString(grant);
    newJson[JsonKey.revoke] = _createPermissionString(revoke);
    return newJson;
  }

  @override
  String toString() {
    return "PolicyResource($path [grant: $grant] [revoke: $revoke])";
  }

  static Set<PermissionType> _createPermissionSet(List<dynamic> jsonList) {
    return jsonList.map((permT) => _permissionTypeFromString(permT)).toSet();
  }

  static List<String> _createPermissionString(
      Set<PermissionType> permissionSet) {
    return permissionSet
        .map((permT) => _permissionTypeToString(permT))
        .toList();
  }

  static PermissionType _permissionTypeFromString(String jsonField) {
    switch (jsonField) {
      case "READ":
        return PermissionType.read;
      case "WRITE":
        return PermissionType.write;
      case "EXECUTE":
        return PermissionType.execute;
      default:
        throw TypeError();
    }
  }

  static String _permissionTypeToString(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.read:
        return "READ";
      case PermissionType.write:
        return "WRITE";
      case PermissionType.execute:
        return "EXECUTE";
    }
  }
}
