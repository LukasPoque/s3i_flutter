import 'package:s3i_flutter/src/json_serializable_object.dart';

/// Represents a simple entry (thing or policy) in the Directory/Repository.
abstract class Entry implements JsonSerializableObject{
  final String id;

  Entry(this.id);

  @override
  String toString() {
    return "Entry($id)";
  }
}
