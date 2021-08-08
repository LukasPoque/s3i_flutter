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
  /// Creates a new [PolicyGroup] with the given [name] and optional
  /// [policySubjects] and [policyResources].
  PolicyGroup(this.name,
      {Map<String, PolicySubject>? policySubjects,
      Map<String, PolicyResource>? policyResources}) {
    subjects = <String, PolicySubject>{...?policySubjects};
    resources = <String, PolicyResource>{...?policyResources};
  }

  /// Returns a [PolicyGroup] with the [name] and the [subjects] and [resources]
  /// specified in the given [json].
  ///
  /// Throws a [InvalidJsonSchemaException] if [json] could not be parsed
  /// to valid [subjects] and [resources].
  factory PolicyGroup.fromJson(String name, Map<String, dynamic> json) {
    final PolicyGroup pG = PolicyGroup(name);
    try {
      if (json.containsKey(JsonKey.subjects)) {
        final Map<String, dynamic> sub =
            json[JsonKey.subjects] as Map<String, dynamic>;
        for (final String k in sub.keys) {
          pG.subjects[k] =
              PolicySubject.fromJson(k, sub[k] as Map<String, dynamic>);
        }
      }
      if (json.containsKey(JsonKey.resources)) {
        final Map<String, dynamic> res =
            json[JsonKey.resources] as Map<String, dynamic>;
        for (final String k in res.keys) {
          pG.resources[k] =
              PolicyResource.fromJson(k, res[k] as Map<String, dynamic>);
        }
      }
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
    return pG;
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

  /// Returns the stored information about this [PolicyGroup] in a [Map]
  /// which could be directly used to creates a json entry.
  ///
  /// Stores [subjects] and [resources] in the [Map].
  /// The [Map] is empty if both [Map]s don't contains entries.
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    if (subjects.isNotEmpty) {
      final Map<String, dynamic> sub = subjects.map<String, dynamic>(
          (String key, PolicySubject value) =>
              MapEntry<String, dynamic>(key, value.toJson()));
      newJson[JsonKey.subjects] = sub;
    }
    if (resources.isNotEmpty) {
      final Map<String, dynamic> res = resources.map<String, dynamic>(
          (String key, PolicyResource value) =>
              MapEntry<String, dynamic>(key, value.toJson()));
      newJson[JsonKey.resources] = res;
    }
    return newJson;
  }

  @override
  String toString() {
    return 'PolicyGroup($name {subjects: $subjects} {resources $resources})';
  }
}
