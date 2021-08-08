import 'package:s3i_flutter/src/query/query_param.dart';

/// Represents a the namespace filter parameter in a query.
///
/// The namespaces list is used to limit the query to things in the given
/// namespaces only. When this parameter is omitted, all namespaces will be
/// queried.
///
/// See the [Ditto-API](https://dir.s3i.vswf.dev/apidoc/#/Things-Search/get_search_things)
/// for more information.
class NamespaceQuery extends QueryParam {
  /// Creates a new [NamespaceQuery] with a list of [namespaces].
  NamespaceQuery(this.namespaces);

  /// The list of namespaces, leave it empty to query all namespaces.
  List<String> namespaces;

  @override
  String generateString() {
    if (namespaces.isEmpty) return '';
    String n = 'namespaces=';
    for (int i = 0; i < namespaces.length; i++) {
      n += namespaces[i];
      if (i < namespaces.length - 1) {
        n += ',';
      }
    }
    return n;
  }
}
