import 'package:s3i_flutter/src/entry.dart';
import 'package:s3i_flutter/src/exceptions/invalid_argument_exception.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/policy/policy_group.dart';
import 'package:s3i_flutter/src/policy/policy_resource.dart';
import 'package:s3i_flutter/src/policy/policy_subject.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// A specific *Policy* for one [Entry] in the directory or repository.
///
/// A policy consists of [PolicyGroup]s and manages the access control to one
/// specific [Entry] in the S3I-Directory or S3i-Repository.
/// For more background information see: https://www.eclipse.org/ditto/basic-policy.html
///
/// In the S3I-Concept there are two special [PolicyGroup]s which have a specific
/// meaning:
/// - owner: An owner has READ and WRITE permission to everything
/// (thing:/, policy:/, message:/)
/// - observer: An observer has only READ permission to the thing part (thing:/)
class PolicyEntry extends Entry {
  PolicyEntry(String id, {Map<String, PolicyGroup>? entryGroups}) : super(id) {
    _groups = {...?entryGroups};
  }

  /// The key of the special `owner` group.
  static final String ownerGroupKey = "owner";

  /// The key of the special `observer` group.
  static final String observerGroupKey = "observer";

  /// The policy groups of this [PolicyEntry].
  ///
  /// The key is the name of the group.
  late Map<String, PolicyGroup> _groups;

  /// Returns a [PolicyEntry] with groups (subjects and resources) specified
  /// in the [map].
  ///
  /// Throws a [InvalidArgumentException] if the map is empty.
  /// Throws a [JsonMissingKeyException] if there is no `policyId` key in
  /// the [map].
  /// Throws a [InvalidJsonSchemaException] if the `entry` key doesn't contain
  /// valid [PolicyGroup]s.
  factory PolicyEntry.fromJson(Map<String, dynamic> map) {
    if (map.isEmpty) throw InvalidArgumentException('empty map');
    String pId = map.containsKey(JsonKey.policyId)
        ? map[JsonKey.policyId]
        : throw JsonMissingKeyException(JsonKey.policyId, map.toString());
    PolicyEntry pE = PolicyEntry(pId);
    try {
      if (map.containsKey(JsonKey.entries)) {
        Map<String, dynamic> gro = map[JsonKey.entries];
        for (var k in gro.keys) {
          pE._groups[k] = PolicyGroup.fromJson(k, gro[k]);
        }
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(e.stackTrace.toString(), map.toString());
    }
    return pE;
  }

  /// Returns the stored information about this [PolicyEntry] in a [Map]
  /// which could be directly used to creates a json entry.
  ///
  /// Stores [id] and [_groups] in the [Map].
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.policyId] = id;
    if (_groups.isNotEmpty) {
      Map<String, dynamic> gro = _groups
          .map((key, value) => MapEntry<String, dynamic>(key, value.toJson()));
      newJson[JsonKey.entries] = gro;
    }
    return newJson;
  }

  @override
  String toString() {
    return "PolicyEntry($id: $_groups)";
  }

  /// Returns the value of [_groups].
  Map<String, PolicyGroup> getGroups() {
    return _groups;
  }

  /// Returns the [PolicyGroup] in [_groups] matching [name].
  ///
  /// Throws [InvalidArgumentException] if there is no group with this name.
  PolicyGroup getGroup(String name) {
    if (_groups.containsKey(name)) return _groups[name]!;
    throw InvalidArgumentException("No group [$name] found");
  }

  /// Adds the given [group] to the [_groups] of this entry.
  ///
  /// If [PolicyGroup._name] is already a key in [_groups], the old group
  /// gets overwritten.
  void insertGroup(PolicyGroup group) {
    _groups[group.name] = group;
  }

  /// Removes [name] and its associated [PolicyGroup] from [_groups].
  ///
  /// Returns the [PolicyGroup] associated with [name] before it was removed.
  /// Returns `null` if [name] was not in the map.
  PolicyGroup? deleteGroup(String name) {
    return _groups.remove(name);
  }

  /// Returns a map of [PolicySubject]s who are in the special group `owner`.
  ///
  /// Throws [InvalidArgumentException] if there is no `owner` group.
  Map<String, PolicySubject> getAllOwners() {
    var owner = getGroup(ownerGroupKey);
    return owner.subjects;
  }

  /// Adds the given [owner] to the special group `owner`.
  ///
  /// If [PolicySubject._id] is already a member of the group, the old value
  /// gets overwritten. If there is no `owner` group present, this method
  /// will create one.
  void insertOwner(PolicySubject owner) {
    if (!_groups.containsKey(ownerGroupKey)) {
      Map<String, PolicyResource> resource = {
        "thing:/": PolicyResource("thing:/",
            grants: {PermissionType.read, PermissionType.write}),
        "policy:/": PolicyResource("policy:/",
            grants: {PermissionType.read, PermissionType.write}),
        "message:/": PolicyResource("message:/",
            grants: {PermissionType.read, PermissionType.write})
      };
      //TODO: add s3i admin entry?
      insertGroup(PolicyGroup(ownerGroupKey,
          policySubjects: {owner.id: owner}, policyResources: resource));
    } else {
      _groups[ownerGroupKey]!.subjects[owner.id] = owner;
    }
  }

  /// Removes [name] and its associated [PolicySubject] from the `owner` group.
  ///
  /// Returns the [PolicySubject] associated with [name] before it was removed.
  /// Returns `null` if [name] was no `owner` or there is no `owner` group.
  PolicySubject? removeOwner(String name) {
    if (!_groups.containsKey(ownerGroupKey)) return null;
    var owner = _groups[ownerGroupKey];
    return owner!.subjects.remove(name);
  }

  /// Returns a map of [PolicySubject]s who are in the special group `observer`.
  ///
  /// Throws [InvalidArgumentException] if there is no `observer` group.
  Map<String, PolicySubject> getAllObservers() {
    var observer = getGroup(observerGroupKey);
    return observer.subjects;
  }

  /// Adds the given [observer] to the special group `observer`.
  ///
  /// If [PolicySubject._id] is already a member of the group, the old value
  /// gets overwritten. If there is no `observer` group present, this method
  /// will create one.
  void insertObserver(PolicySubject observer) {
    if (!_groups.containsKey(observerGroupKey)) {
      Map<String, PolicyResource> resource = {
        "thing:/": PolicyResource("thing:/", grants: {PermissionType.read})
      };
      insertGroup(PolicyGroup(observerGroupKey,
          policySubjects: {observer.id: observer}, policyResources: resource));
    } else {
      _groups[observerGroupKey]!.subjects[observer.id] = observer;
    }
  }

  /// Removes [name] and its associated [PolicySubject] from
  /// the `observer` group.
  ///
  /// Returns the [PolicySubject] associated with [name] before it was removed.
  /// Returns `null` if [name] was no `observer` or
  /// there is no `observer` group.
  PolicySubject? removeObserver(String name) {
    if (!_groups.containsKey(observerGroupKey)) return null;
    var observer = _groups[observerGroupKey];
    return observer!.subjects.remove(name);
  }
}
