import 'package:s3i_flutter/src/query/query_param.dart';

/// Represents a the field filter parameter in a query.
///
/// Only the selected fields will be included in the returned json. This is a
/// very useful feature to reduce internet traffic and increase the speed of a
/// query if only party of an entry is relevant.
///
/// From the [Ditto-API](https://dir.s3i.vswf.dev/apidoc/#/Things-Search/get_search_things):
/// > Selectable fields:
///
/// > - thingId
/// >
/// > - policyId
/// >
/// > - _policy: Specifically selects the policy of the Thing. (The policy is
/// > not contained in the returned JSON per default.)
/// >
/// > - attributes: Supports selecting arbitrary sub-fields by using a
/// > comma separated list (like `attributes/ownedBy/` or `attributes/name`)
/// >
/// > - definition
/// >
/// > - features: Supports selecting arbitrary fields in features similar to
/// > attributes (see also Features documentation for more details)
/// >
/// > - _namespace: Specifically selects the namespace also contained in
/// > the thingId
/// >
/// > - _revision: Specifically selects the revision of the Thing. The revision
/// > is a counter which is incremented on each modification of a Thing.
/// >
/// > - _modified: Specifically selects the modified timestamp of the Thing in
/// > ISO-8601 UTC format. The timestamp is set on each modification of a Thing.
class FieldQuery extends QueryParam {
  /// Creates a new [FieldQuery] with the given [fields].
  FieldQuery(this.fields);

  /// The path to the specified fields which wild be included in the response.
  ///
  /// See [RFC-6901](https://datatracker.ietf.org/doc/html/rfc6901) for the
  ///  JSON Pointer notation and [FieldQuery] for a complete description of
  ///  the possible fields.
  List<String> fields;

  // ?fields=attributes/model
  // ?fields=attributes/address/postal(city,street)
  @override
  String generateString() {
    if (fields.isEmpty) return '';
    String n = 'fields=';
    for (int i = 0; i < fields.length; i++) {
      n += fields[i];
      if (i < fields.length - 1) {
        n += ',';
      }
    }
    return n;
  }
}
