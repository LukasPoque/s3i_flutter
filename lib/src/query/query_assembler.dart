import 'package:s3i_flutter/src/query/field_query.dart';
import 'package:s3i_flutter/src/query/namespace_query.dart';
import 'package:s3i_flutter/src/query/option_query.dart';
import 'package:s3i_flutter/src/query/rql_query.dart';

class QueryAssembler {
  //TODO: maybe a List<QueryParam> is easier + more flexible
  static String generatePath(String base,
      {RQLQuery? rqlFilter,
      NamespaceQuery? namespaceQuery,
      FieldQuery? fieldQuery,
      OptionQuery? optionQuery}) {
    String path = base;
    if (rqlFilter != null ||
        namespaceQuery != null ||
        fieldQuery != null ||
        optionQuery != null) {
      path += "?";
      if (rqlFilter != null) {
        path += "filter=" + rqlFilter.generateString();
        if (namespaceQuery != null || fieldQuery != null || optionQuery != null)
          path += "&";
      }
      if (namespaceQuery != null) {
        path += namespaceQuery.generateString();
        if (fieldQuery != null || optionQuery != null) path += "&";
      }
      if (fieldQuery != null) {
        path += fieldQuery.generateString();
        if (optionQuery != null) path += "&";
      }
      if (optionQuery != null) {
        path += optionQuery.generateString();
      }
    }
    return path;
  }
}
