import 'package:s3i_flutter/src/query/query_param.dart';

class NamespaceQuery extends QueryParam {
  List<String> namespaces;

  NamespaceQuery(this.namespaces);

  @override
  String generateString() {
    if (namespaces.isEmpty) return "";
    String n = "namespaces=";
    for (int i = 0; i < namespaces.length; i++) {
      n += namespaces[i];
      if (i < namespaces.length - 1) {
        n += ",";
      }
    }
    return n;
  }
}
