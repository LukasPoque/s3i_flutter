import 'package:s3i_flutter/src/query/query_param.dart';

/// ?fields=attributes/model
/// ?fields=attributes/address/postal(city,street)
class FieldQuery extends QueryParam {
  List<String> fields;

  FieldQuery(this.fields);

  @override
  String generateString() {
    if (fields.isEmpty) return "";
    String n = "fields=";
    for (int i = 0; i < fields.length; i++) {
      n += fields[i];
      if (i < fields.length - 1) {
        n += ",";
      }
    }
    return n;
  }
}
