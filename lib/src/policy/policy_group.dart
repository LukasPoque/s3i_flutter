import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/policy/policy_entry.dart';
import 'package:s3i_flutter/src/policy/policy_resource.dart';
import 'package:s3i_flutter/src/policy/policy_subject.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// A specific *Group* in a policy entry.
///
/// This ties specific [PolicySubject]s and [PolicyResource]s together.
/// Default groups in the S3I-Concept are `owner` and `observer`.
/// See [PolicyEntry] for more information.
class PolicyGroup implements JsonSerializableObject {
  PolicyGroup(this.name,
      {Map<String, PolicySubject>? policySubjects,
      Map<String, PolicyResource>? policyResources}) {
    subjects = {...?policySubjects};
    resources = {...?policyResources};
  }

  /// The identifier of this [PolicyGroup].
  ///
  /// This could be everything but should be self explanatory
  /// and consider readability.
  /// Default names in the S3I-Concept are `owner` and `observer`.
  final String name;

  /// The subjects of this [PolicyGroup].
  ///
  /// > Subjects in a policy define who gets permissions granted/revoked
  /// > on the resources of a policy entry.
  ///
  /// The key is the id of the subject.
  late Map<String, PolicySubject> subjects;

  /// The protected resources of this [PolicyGroup].
  ///
  /// The key is the path of the resource.
  late Map<String, PolicyResource> resources;

  /// Returns a [PolicyGroup] with the [name] and the [subjects] and [resources]
  /// specified in the given [json].
  ///
  /// Throws a [InvalidJsonSchemaException] if [json] could not be parsed
  /// to valid [subjects] and [resources].
  factory PolicyGroup.fromJson(String name, Map<String, dynamic> json) {
    PolicyGroup pG = PolicyGroup(name);
    try {
      if (json.containsKey(JsonKey.subjects)) {
        Map<String, dynamic> sub = json[JsonKey.subjects];
        for (var k in sub.keys) {
          pG.subjects[k] = PolicySubject.fromJson(k, sub[k]);
        }
      }
      if (json.containsKey(JsonKey.resources)) {
        Map<String, dynamic> res = json[JsonKey.resources];
        for (var k in res.keys) {
          pG.resources[k] = PolicyResource.fromJson(k, res[k]);
        }
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
    return pG;
  }

  /// Returns the stored information about this [PolicyGroup] in a [Map]
  /// which could be directly used to creates a json entry.
  ///
  /// Stores [subjects] and [resources] in the [Map].
  /// The [Map] is empty if both [Map]s don't contains entries.
  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    if (subjects.isNotEmpty) {
      Map<String, dynamic> sub = subjects
          .map((key, value) => MapEntry<String, dynamic>(key, value.toJson()));
      newJson[JsonKey.subjects] = sub;
    }
    if (resources.isNotEmpty) {
      Map<String, dynamic> res = resources
          .map((key, value) => MapEntry<String, dynamic>(key, value.toJson()));
      newJson[JsonKey.resources] = res;
    }
    return newJson;
  }

  @override
  String toString() {
    return "PolicyGroup($name {subjects: $subjects} {resources $resources})";
  }
}
