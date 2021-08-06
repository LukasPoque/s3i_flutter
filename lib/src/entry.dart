import 'package:s3i_flutter/src/json_serializable_object.dart';

/// Represents a simple entry (thing or policy) in the Directory/Repository.
abstract class Entry implements JsonSerializableObject {
  /// Creates an [Entry] with the given [id].
  Entry(this.id);

  /// The unique identifier of this entry.
  ///
  /// In the S3I, most identifiers starts with `s3i:` following by an UUIDv4.
  final String id;

  @override
  String toString() {
    return 'Entry($id)';
  }
}
