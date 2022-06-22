import 'dart:ffi';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/directory/link.dart';
import 'package:s3i_flutter/src/directory/property.dart';
import 'package:s3i_flutter/src/directory/value.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

// TODO(Bek): This was added (do we need it?)

/// Represents a 'Service' in the S3I-Directory data model.

class Service implements JsonSerializableObject {
  /// Creates a [Service] with the given [serviceType][endPoint][parameterTypes][resultTypes].
  Service();

  /// Creates a [Service] from a decoded [json] entry.
  ///
  /// Could throw a [JsonMissingKeyException] if [classString] (or other
  /// required keys) could not be found in the json. Throws a [TypeError]
  /// if the values couldn't be parsed as expected.
  factory Service.fromJson(Map<String, dynamic> json) {

    final Service s = Service()

    ..serviceType = json.containsKey(DirectoryKeys.serveiceType)
        ? json[DirectoryKeys.serveiceType] as String
        : throw JsonMissingKeyException(
        DirectoryKeys.serveiceType, json.toString())
    ..endPoints = json.containsKey(DirectoryKeys.endpoints) ? _createEndpointList(
        json[DirectoryKeys.endpoints] as List<dynamic>)
        : throw JsonMissingKeyException(
        DirectoryKeys.endpoints, json.toString())
    ..parameterTypes = json.containsKey(DirectoryKeys.parameterTypes)? _createParameterTypeList(json[DirectoryKeys.parameterTypes])
        : throw JsonMissingKeyException(DirectoryKeys.parameterTypes, json.toString())
    ..resultTypes = json.containsKey(DirectoryKeys.resultTypes)? _createResultTypeList(json[DirectoryKeys.resultTypes])
          : throw JsonMissingKeyException(DirectoryKeys.resultTypes, json.toString());

    return s;
  }

  /// only for the moment
  factory Service.temp(String serviceType, List<Endpoint> endpoints, List<ParameterType> parameterTypes, List<ResultType> resultTypes){
    Service s = Service()
        ..serviceType = serviceType
        ..endPoints = endpoints
        ..parameterTypes = parameterTypes
        ..resultTypes = resultTypes;
    return s;
  }

  late String serviceType;
  late List<Endpoint> endPoints;
  late List<ParameterType> parameterTypes;
  late List<ResultType> resultTypes;


  /// Maps the [jsonList] to a [List<ParameterType>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed. Throws a
  /// [JsonMissingKeyException] if a needed key is missing.
  static List<ParameterType> _createParameterTypeList(Map<String,dynamic> jsonMap) {
    return jsonMap.entries.map((e) => ParameterType(e.key, e.value)).toList();
  }

  /// Maps the [jsonList] to a [List<ResultType>].
  ///
  /// Throws a [TypeError] if a element in the list could not be parsed. Throws a
  /// [JsonMissingKeyException] if a needed key is missing.
  static List<ResultType> _createResultTypeList(Map<String,dynamic> jsonMap) {
    return jsonMap.entries.map((e) => ResultType(e.key, e.value)).toList();
  }

  static List<Endpoint> _createEndpointList(List<dynamic> jsonList) {
    return jsonList.map((dynamic endP) => Endpoint(endP as String)).toList();
  }



  @override
  String toString() {
    return 'Object($serviceType ---- $endPoints ---- $parameterTypes ---- $resultTypes';
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[DirectoryKeys.serveiceType] = serviceType;

    newJson[DirectoryKeys.endpoints] =
          endPoints.map((Endpoint e) => e.endpoint).toList();

    Map paramTypes = <String,String>{};
    parameterTypes.forEach((element) {paramTypes[element.paramName] = element.paramType;});
    newJson[DirectoryKeys.parameterTypes] = paramTypes;

    Map resTypes = <String,String>{};
    resultTypes.forEach((element) {resTypes[element.paramName] = element.paramType;});
    newJson[DirectoryKeys.resultTypes] = resTypes;
    return newJson;
  }

}


class IoParameterType {

  IoParameterType(this.iotype, this.paramName, this.paramType);
  final IoType iotype;
  final String paramName;
  final String paramType;
}

class ParameterType extends IoParameterType{
  ParameterType(String name, String type): super(IoType.input, name, type);
}

class ResultType extends IoParameterType{
  ResultType(String name, String type): super(IoType.result, name, type);
}

enum IoType{
  input,
  result
}
