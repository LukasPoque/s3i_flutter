import 'package:s3i_flutter/src/directory/dir_object.dart';
import 'package:s3i_flutter/src/directory/endpoint.dart';
import 'package:s3i_flutter/src/directory/location.dart';
import 'package:s3i_flutter/src/entry.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/exceptions/parse_exception.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

enum ThingType {
  component,
  service,
  hmi,
}

/// Represents a Thing in the S3I-Directory Data Model.
class Thing extends Entry {
  String? name;
  ThingType? thingType;
  String? dataModel;
  String? publicKey;
  List<Endpoint>? allEndpoints;
  Endpoint? defaultEndpoint; //TODO: change to list
  String? defaultHMI;
  Location? location;
  String? ownedBy;
  String? administratedBy;
  String? usedBy;
  String? represents;
  DirObject? thingStructure;

  Thing(String id) : super(id);

  /// Creates a thing from the given map (mostly created via jsonDecode(jsonStr)).
  /// throws ParseException if the map is empty
  /// throws JsonMissingKeyException if there is no thingId in the map | no class in object | no attribute in value | no association in link
  /// throws TypeError if a matching key field mismatches the expected value type
  factory Thing.fromJson(Map<String, dynamic> map) {
    if (map.isEmpty) throw ParseException('empty map');
    String tId = map.containsKey(JsonKey.thingId)
        ? map[JsonKey.thingId]
        : throw JsonMissingKeyException(JsonKey.thingId, map.toString());
    //TODO: check if matching key field mismatches the expected value type and create own error (extended from S3IException)
    Thing t = Thing(tId);
    dynamic attributes = map[JsonKey.attributes];
    if (attributes != null) {
      Map<String, dynamic> attributesMap = attributes;
      t.name = attributesMap[JsonKey.name];
      t.thingType = attributesMap.containsKey(JsonKey.thingType)
          ? _createThingType(attributesMap[JsonKey.thingType])
          : null;
      t.dataModel = attributesMap[JsonKey.dataModel];
      t.publicKey = attributesMap[JsonKey.publicKey];
      t.allEndpoints = attributesMap.containsKey(JsonKey.allEndpoints)
          ? _createEndpointList(attributesMap[JsonKey.allEndpoints])
          : null;
      t.defaultEndpoint = attributesMap.containsKey(JsonKey.defaultEndpoint)
          ? Endpoint(attributesMap[JsonKey.defaultEndpoint])
          : null;
      t.defaultHMI = attributesMap[JsonKey.defaultHMI];
      t.location = attributesMap.containsKey(JsonKey.location)
          ? Location.fromJson(attributesMap[JsonKey.location])
          : null;
      t.ownedBy = attributesMap[JsonKey.ownedBy];
      t.administratedBy = attributesMap[JsonKey.administratedBy];
      t.usedBy = attributesMap[JsonKey.usedBy];
      t.represents = attributesMap[JsonKey.represents];
      t.thingStructure = attributesMap.containsKey(JsonKey.thingStructure)
          ? DirObject.fromJson(attributesMap[JsonKey.thingStructure])
          : null;
    }
    return t;
  }

  static ThingType _createThingType(String jsonField) {
    switch (jsonField) {
      case "component":
        return ThingType.component;
      case "service":
        return ThingType.service;
      case "hmi":
        return ThingType.hmi;
      default:
        throw TypeError();
    }
  }

  static String _thingTypeToString(ThingType thingType) {
    switch (thingType) {
      case ThingType.component:
        return "component";
      case ThingType.service:
        return "service";
      case ThingType.hmi:
        return "hmi";
    }
  }

  static List<Endpoint> _createEndpointList(List<dynamic> jsonList) {
    return jsonList.map((endP) => Endpoint(endP)).toList();
  }

  @override
  Map<String, dynamic> toJson() {
    Map<String, dynamic> newJson = Map();
    newJson[JsonKey.thingId] = id;
    if (name != null) newJson[JsonKey.name] = name;
    if (thingType != null)
      newJson[JsonKey.thingType] = _thingTypeToString(thingType!);
    if (dataModel != null) newJson[JsonKey.dataModel] = dataModel;
    if (publicKey != null) newJson[JsonKey.publicKey] = publicKey;
    if (allEndpoints != null)
      newJson[JsonKey.allEndpoints] =
          allEndpoints!.map((e) => e.endpoint).toList();
    if (defaultEndpoint != null)
      newJson[JsonKey.defaultEndpoint] = defaultEndpoint;
    if (defaultHMI != null) newJson[JsonKey.defaultHMI] = defaultHMI;
    if (location != null) newJson[JsonKey.location] = location!.toJson();
    if (ownedBy != null) newJson[JsonKey.ownedBy] = ownedBy;
    if (administratedBy != null)
      newJson[JsonKey.administratedBy] = administratedBy;
    if (usedBy != null) newJson[JsonKey.usedBy] = usedBy;
    if (represents != null) newJson[JsonKey.represents] = represents;
    if (thingStructure != null)
      newJson[JsonKey.thingStructure] = thingStructure!.toJson();
    return newJson;
  }
}
