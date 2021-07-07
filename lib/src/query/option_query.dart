import 'package:s3i_flutter/src/query/query_param.dart';

enum SortOption { ascending, descending }

class SortConfig {
  final SortOption sortOption;
  final String property;

  SortConfig(this.sortOption, this.property);

  String generateString() {
    String s = "";
    switch (sortOption) {
      case SortOption.ascending:
        s += "+";
        break;
      case SortOption.descending:
        s += "-";
        break;
    }
    s += property;
    return s;
  }
}

class OptionQuery extends QueryParam {
  List<SortConfig> sortO;
  int? requestSize;
  String? cursor;

  OptionQuery({this.sortO = const [], this.requestSize, this.cursor});

  @override
  String generateString() {
    if (sortO.isEmpty && requestSize == null && cursor == null) return "";
    String o = "option=";
    if (sortO.isNotEmpty) {
      o += "sort(";
      for (int i = 0; i < sortO.length; i++) {
        o += sortO[i].generateString();
        if (i < sortO.length - 1) {
          o += ",";
        }
      }
      o += ")";
      if (requestSize != null || cursor != null) {
        o += ",";
      }
    }
    if (requestSize != null) {
      o += "size($requestSize)";
      if (cursor != null) {
        o += ",";
      }
    }
    if (cursor != null) {
      o += "cursor($cursor)";
    }
    return o;
  }
}
