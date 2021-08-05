import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// The *Subject* of a ditto policy group.
///
/// From https://www.eclipse.org/ditto/basic-policy.html#subjects:
/// > Subjects in a policy define who gets permissions granted/revoked
/// > on the resources of a policy entry. Each subject ID contains a prefix
/// > defining the subject “issuer” (so which party issued the authentication)
/// > and an actual subject, separated with a colon.
class PolicySubject implements JsonSerializableObject {
  /// Creates a [PolicySubject] with the [id] and the optional
  /// [expiringTimestamp] and [type].
  PolicySubject(this.id, {this.expiringTimestamp, this.type});

  /// Returns a [PolicySubject] with the [id]
  /// and enriches it with the given information in [json].
  ///
  /// Throws an [InvalidJsonSchemaException] if [json] contains an "expiry" key
  /// which could not be parsed by [DateTime.parse()] OR if [json] contains
  /// an "type" key which isn't a [String].
  factory PolicySubject.fromJson(String id, Map<String, dynamic> json) {
    final PolicySubject pS = PolicySubject(id);
    try {
      if (json.containsKey(JsonKey.expiry)) {
        pS.expiringTimestamp = DateTime.parse(json[JsonKey.expiry] as String);
      }
      pS.type = json[JsonKey.type] as String;
    } on FormatException catch (e) {
      //datetime parsing failed
      throw InvalidJsonSchemaException(e.message, json.toString());
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
    return pS;
  }

  ///  The subject-id (WHO gets the permissions granted/revoked).
  ///
  ///  This could be:
  ///  - a s3i-identifier
  ///  - a s3i-idp-group name
  ///  - a specific user id
  ///
  /// Use "nginx:<ID>" as pattern.
  final String id;

  /// The optional validation date of this subject.
  ///
  /// Converts to/from an ISO-8601 string for/from ditto.
  /// For more information see https://www.eclipse.org/ditto/basic-policy.html#expiring-policy-subjects.
  DateTime? expiringTimestamp;

  /// An optional description of the subject.
  String? type;

  /// Returns the stored information about this [PolicySubject] in a [Map]
  /// which could be directly used to creates a json entry.
  ///
  /// Stores [expiringTimestamp] and [type] in the [Map].
  /// The [Map] is empty if both fields are [null].
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    if (expiringTimestamp != null)
      newJson[JsonKey.expiry] = expiringTimestamp!.toIso8601String();
    if (type != null) newJson[JsonKey.type] = type;
    return newJson;
  }

  @override
  String toString() {
    return 'PolicySubject($id:[$expiringTimestamp | $type])';
  }
}
