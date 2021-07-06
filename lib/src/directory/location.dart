import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

/// Represents a Location in the S3I-Directory Data Model.
/// needs latitude and longitude
class Location implements JsonSerializableObject {
  final String latitude;
  final String longitude;

  Location(this.latitude, this.longitude);

  factory Location.fromJson(Map<String, dynamic> json) {
    String latitude = json.containsKey(JsonKey.latitude)
        ? json[JsonKey.latitude]
        : throw JsonMissingKeyException(JsonKey.latitude, json.toString());
    String longitude = json.containsKey(JsonKey.longitude)
        ? json[JsonKey.longitude]
        : throw JsonMissingKeyException(JsonKey.longitude, json.toString());
    return Location(latitude, longitude);
  }

  @override
  String toString() {
    return "Location(lat: $latitude | long: $longitude)";
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.latitude] = latitude;
    newJson[JsonKey.longitude] = longitude;
    return newJson;
  }
}
