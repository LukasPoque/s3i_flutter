import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// Represents a `Location` in the S3I-Directory data model.
///
/// WGS84 is used as base coordinate system.
class Location implements JsonSerializableObject {
  /// Creates a [Location] at [latitude] and [longitude].
  Location(this.latitude, this.longitude);

  /// Creates a [Location] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [latitude] or [longitude]
  /// could not be found in the json. Throws a [TypeError] if the values
  /// couldn't be parsed as double.
  factory Location.fromJson(Map<String, dynamic> json) {
    final double latitude = json.containsKey(DirectoryKeys.latitude)
        ? json[DirectoryKeys.latitude] as double
        : throw JsonMissingKeyException(
            DirectoryKeys.latitude, json.toString());
    final double longitude = json.containsKey(DirectoryKeys.longitude)
        ? json[DirectoryKeys.longitude] as double
        : throw JsonMissingKeyException(
            DirectoryKeys.longitude, json.toString());
    return Location(latitude, longitude);
  }

  /// The latitude (N x.x°) of the location.
  double latitude;

  /// The longitude (E x.x°) of the location.
  double longitude;

  @override
  String toString() {
    return 'Location(lat: $latitude | long: $longitude)';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DirectoryKeys.latitude] = latitude;
    newJson[DirectoryKeys.longitude] = longitude;
    return newJson;
  }
}
