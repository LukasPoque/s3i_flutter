import 'package:s3i_flutter/src/query/query_param.dart';

/// Represents additional options for a query to the S3I-Directory/Repository.
///
/// There are two different option types: `Sort operations` ([SortConfig]) and
/// `Paging operation` ([pageSize], [cursor]).
///
/// See the [Ditto-API](https://dir.s3i.vswf.dev/apidoc/#/Things-Search/get_search_things)
/// for more information.
class OptionQuery extends QueryParam {
  /// Creates a [OptionQuery] with the given [sortOptions], a [pageSize] and
  /// a [cursor] (all optional).
  OptionQuery(
      {this.sortOptions = const <SortConfig>[], this.pageSize, this.cursor});

  /// All [SortConfig]s in this query.
  List<SortConfig> sortOptions;

  /// The maximum count of entries returned by one request.
  ///
  /// Without specifying ditto returns `25` entries, the maximum allowed
  /// size is `200`.
  int? pageSize;

  /// The cursor from which the search starts (used for pagination search).
  ///
  /// From the [Ditto-API](https://dir.s3i.vswf.dev/apidoc/#/Things-Search/get_search_things):
  /// > Cursor IDs are given in responses and mark the position after the final
  /// > search result. The meaning of cursor IDs is unspecified and may change
  /// > without notice.
  String? cursor;

  @override
  String generateString() {
    if (sortOptions.isEmpty && pageSize == null && cursor == null) return '';
    String o = 'option=';
    if (sortOptions.isNotEmpty) {
      o += 'sort(';
      for (int i = 0; i < sortOptions.length; i++) {
        o += sortOptions[i].generateString();
        if (i < sortOptions.length - 1) {
          o += ',';
        }
      }
      o += ')';
      if (pageSize != null || cursor != null) {
        o += ',';
      }
    }
    if (pageSize != null) {
      o += 'size($pageSize)';
      if (cursor != null) {
        o += ',';
      }
    }
    if (cursor != null) {
      o += 'cursor($cursor)';
    }
    return o;
  }
}

/// The sorting operations which could be applied to a [SortConfig].
enum SortOption {
  /// Sorts the property ascending (+).
  ascending,

  /// Sorts the property descending (-).
  descending
}

/// Represents one specific sort option to a specified property.
class SortConfig {
  /// Creates a [SortConfig] which sorts the [property] in the way
  /// [sortOption] specifies.
  SortConfig(this.sortOption, this.property);

  /// The sorting operation: [SortOption.ascending] or [SortOption.descending].
  final SortOption sortOption;

  /// The JSON Pointer to the property which is going to be sorted.
  ///
  /// See [RFC-6901](https://datatracker.ietf.org/doc/html/rfc6901) for the
  /// JSON Pointer notation.
  final String property;

  /// Returns the stored information of this [SortConfig] ready to use in an
  /// [OptionQuery].
  String generateString() {
    String s = '';
    switch (sortOption) {
      case SortOption.ascending:
        s += '+';
        break;
      case SortOption.descending:
        s += '-';
        break;
    }
    s += property;
    return s;
  }
}
