import 'package:s3i_flutter/src/directory/dir_object.dart';
import 'package:s3i_flutter/src/directory/endpoint.dart';
import 'package:s3i_flutter/src/directory/location.dart';
import 'package:s3i_flutter/src/entry.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

// TODO(poq): add ditto specific attributes like definition,_revision,_modified

/// Represents a `Thing` in the S3I-Directory data model.
///
/// See the [KWH Standpunkt](https://www.kwh40.de/wp-content/uploads/2020/04/KWH40-Standpunkt-S3I-v2.0.pdf)
/// for more information about a thing an its function.
///
/// Simple UML diagram for the S3I-Directory data model:
/// ```
/// +--------------+
/// |              |
/// |  S3I::Thing  |
/// |              |
/// +--------------+
///         ^
///         |
///         |thingStructure
///         |
///         |0..1
/// +-------+-------+0..1   target    +--------------+
/// |               +---------------->|              |
/// |  S3I::Object  |                 |  S3I::Link   |
/// |               |<----------------+              |
/// +---------------+  links        * +--------------+
///         ^
///         |
///         |values
///         |
///         |*
/// +-------+------+
/// |              |
/// |  S3I::Value  |
/// |              |
/// +--------------+
/// ```
class Thing extends Entry {
  /// Creates a new [Thing] with the given [id].
  Thing(String id) : super(id);

  /// Creates a [Thing] from a decoded [json] entry.
  ///
  /// Could throw [InvalidJsonSchemaException] or a specific
  /// [JsonMissingKeyException] and if something went wrong during the parsing
  /// to the directory objects.
  factory Thing.fromJson(Map<String, dynamic> map) {
    try {
      final String tId = map.containsKey(DittoKeys.thingId)
          ? map[DittoKeys.thingId] as String
          : throw JsonMissingKeyException(DittoKeys.thingId, map.toString());
      final Thing internalThing = Thing(tId);
      if (map.containsKey(DittoKeys.attributes)) {
        final Map<String, dynamic> attributesMap =
            map[DittoKeys.attributes] as Map<String, dynamic>;
        internalThing.name = attributesMap[DirectoryKeys.name] as String?;
        try {
          internalThing.thingType =
              attributesMap.containsKey(DirectoryKeys.thingType)
                  ? _createThingType(
                      attributesMap[DirectoryKeys.thingType] as String)
                  : null;
        } on FallThroughError {
          throw InvalidJsonSchemaException(
              'unknown thing type', map.toString());
        } on TypeError {
          throw InvalidJsonSchemaException(
              'thing type is no string', map.toString());
        }
        internalThing
          ..dataModel = attributesMap[DirectoryKeys.dataModel] as String?
          ..publicKey = attributesMap[DirectoryKeys.publicKey] as String?
          ..allEndpoints = attributesMap.containsKey(DirectoryKeys.allEndpoints)
              ? _createEndpointList(
                  attributesMap[DirectoryKeys.allEndpoints] as List<dynamic>)
              : null
          ..defaultEndpoint = attributesMap
                  .containsKey(DirectoryKeys.defaultEndpoint)
              ? Endpoint(attributesMap[DirectoryKeys.defaultEndpoint] as String)
              : null
          ..defaultHMI = attributesMap[DirectoryKeys.defaultHMI] as String?
          ..location = attributesMap.containsKey(DirectoryKeys.location)
              ? Location.fromJson(
                  attributesMap[DirectoryKeys.location] as Map<String, dynamic>)
              : null
          ..ownedBy = attributesMap[DirectoryKeys.ownedBy] as String?
          ..administratedBy =
              attributesMap[DirectoryKeys.administratedBy] as String?
          ..usedBy = attributesMap[DirectoryKeys.usedBy] as String?
          ..represents = attributesMap[DirectoryKeys.represents] as String?
          ..thingStructure = attributesMap
                  .containsKey(DirectoryKeys.thingStructure)
              ? DirObject.fromJson(attributesMap[DirectoryKeys.thingStructure]
                  as Map<String, dynamic>)
              : null;
      }
      return internalThing;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(e.stackTrace.toString(), map.toString());
    }
  }

  /// The display name.
  String? name;

  /// The type, see [ThingType].
  ThingType? thingType;

  /// The data model of this entry (fml40).
  String? dataModel;

  /// The public key for secure communication.
  String? publicKey;

  /// All endpoints of this thing (e.g. S3I-B, OPC UA, MQTT, etc - addresses).
  List<Endpoint>? allEndpoints;

  /// The currently active endpoint of the thing.
  Endpoint? defaultEndpoint; // TODO(poq): change to list

  /// The current active hmi (e.g. app, website, etc.).
  String? defaultHMI;

  /// The last know location of this thing.
  Location? location;

  /// The owner id of this thing (UUIDv4).
  ///
  /// Query for `represents == currentThing.ownedBy` to get information about
  /// the owner.
  String? ownedBy;

  /// The administrator of this thing (UUIDv4).
  String? administratedBy;

  /// The current user of this thing (UUIDv4).
  String? usedBy;

  /// The user id who is represented by this thing (digital twin) [UUID.4].
  String? represents;

  /// The fml40 structure/information of this thing.
  DirObject? thingStructure;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DittoKeys.thingId] = id;
    newJson[DittoKeys.policyId] = id;
    final Map<String, dynamic> attributesMap = <String, dynamic>{};
    if (name != null) attributesMap[DirectoryKeys.name] = name;
    if (thingType != null) {
      attributesMap[DirectoryKeys.thingType] = _thingTypeToString(thingType!);
    }
    if (dataModel != null) attributesMap[DirectoryKeys.dataModel] = dataModel;
    if (publicKey != null) attributesMap[DirectoryKeys.publicKey] = publicKey;
    if (allEndpoints != null) {
      attributesMap[DirectoryKeys.allEndpoints] =
          allEndpoints!.map((Endpoint e) => e.endpoint).toList();
    }
    if (defaultEndpoint != null) {
      attributesMap[DirectoryKeys.defaultEndpoint] = defaultEndpoint;
    }
    if (defaultHMI != null) {
      attributesMap[DirectoryKeys.defaultHMI] = defaultHMI;
    }
    if (location != null) {
      attributesMap[DirectoryKeys.location] = location!.toJson();
    }
    if (ownedBy != null) attributesMap[DirectoryKeys.ownedBy] = ownedBy;
    if (administratedBy != null) {
      attributesMap[DirectoryKeys.administratedBy] = administratedBy;
    }
    if (usedBy != null) attributesMap[DirectoryKeys.usedBy] = usedBy;
    if (represents != null) {
      attributesMap[DirectoryKeys.represents] = represents;
    }
    if (thingStructure != null) {
      attributesMap[DirectoryKeys.thingStructure] = thingStructure!.toJson();
    }
    if (attributesMap.isNotEmpty) newJson[DittoKeys.attributes] = attributesMap;
    return newJson;
  }

  static ThingType _createThingType(String jsonField) {
    switch (jsonField) {
      case 'component':
        return ThingType.component;
      case 'service':
        return ThingType.service;
      case 'hmi':
        return ThingType.hmi;
      default:
        throw FallThroughError();
    }
  }

  static String _thingTypeToString(ThingType thingType) {
    switch (thingType) {
      case ThingType.component:
        return 'component';
      case ThingType.service:
        return 'service';
      case ThingType.hmi:
        return 'hmi';
    }
  }

  static List<Endpoint> _createEndpointList(List<dynamic> jsonList) {
    return jsonList.map((dynamic endP) => Endpoint(endP as String)).toList();
  }
}

/// The different types of a thing in the fml4.0 language.
///
/// [ThingType.component], [ThingType.service], [ThingType.hmi]
enum ThingType {
  /// Component.
  component,

  /// Service.
  service,

  /// HumanMachineInterface.
  hmi,
}
