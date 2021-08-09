import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/policy/policy_subject.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// The type of a granted/revoked permission.
///
/// Currently supported:
/// - [PermissionType.read]
/// - [PermissionType.write]
/// - [PermissionType.execute]
///
/// For further information see:
/// https://www.eclipse.org/ditto/basic-policy.html#grant-and-revoke-some-permission
enum PermissionType {
  ///read access
  read,

  ///write access
  write,

  /// execute
  execute
}

/// The protected *Resource* of a ditto policy group.
///
/// This defines to which part of a ditto entry the
/// corresponding [PolicySubject] has which permissions granted/revoked.
/// For more information see:
/// https://www.eclipse.org/ditto/basic-policy.html#which-resources-can-be-controlled
class PolicyResource implements JsonSerializableObject {
  /// Creates a new [PolicyResource] with the [path] and the optional [grants]
  /// and [revokes].
  PolicyResource(this.path,
      {Set<PermissionType>? grants, Set<PermissionType>? revokes}) {
    grant = <PermissionType>{...?grants};
    revoke = <PermissionType>{...?revokes};
  }

  /// Returns a [PolicyResource] with the [path]
  /// and enriches it with the given information in [json].
  ///
  /// Throws an [InvalidJsonSchemaException] if [json] could not be parsed to
  /// valid [grant] and [revoke] parameters.
  factory PolicyResource.fromJson(String path, Map<String, dynamic> json) {
    final PolicyResource pR = PolicyResource(path);
    try {
      if (json.containsKey(DittoKeys.grant)) {
        pR.grant = _createPermissionSet(json[DittoKeys.grant] as List<dynamic>);
      }
      if (json.containsKey(DittoKeys.revoke)) {
        pR.revoke =
            _createPermissionSet(json[DittoKeys.revoke] as List<dynamic>);
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
    return pR;
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

  /// Returns the stored information about this [PolicyResource] in a [Map]
  /// which could be directly used to creates a json entry.
  ///
  /// Stores [grant] and [revoke] in the [Map].
  /// The [Map] is empty if both [Set]s don't contains entries.
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DittoKeys.grant] = _createPermissionString(grant);
    newJson[DittoKeys.revoke] = _createPermissionString(revoke);
    return newJson;
  }

  @override
  String toString() {
    return 'PolicyResource($path [grant: $grant] [revoke: $revoke])';
  }

  static Set<PermissionType> _createPermissionSet(List<dynamic> jsonList) {
    return jsonList
        .map((dynamic permT) => _permissionTypeFromString(permT as String))
        .toSet();
  }

  static List<String> _createPermissionString(
      Set<PermissionType> permissionSet) {
    return permissionSet
        .map((PermissionType permT) => _permissionTypeToString(permT))
        .toList();
  }

  static PermissionType _permissionTypeFromString(String jsonField) {
    switch (jsonField) {
      case 'READ':
        return PermissionType.read;
      case 'WRITE':
        return PermissionType.write;
      case 'EXECUTE':
        return PermissionType.execute;
      default:
        throw TypeError();
    }
  }

  static String _permissionTypeToString(PermissionType permissionType) {
    switch (permissionType) {
      case PermissionType.read:
        return 'READ';
      case PermissionType.write:
        return 'WRITE';
      case PermissionType.execute:
        return 'EXECUTE';
    }
  }
}
