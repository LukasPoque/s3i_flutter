import 'package:s3i_flutter/src/broker/messages/message.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// Represents a `S3I::B::ServiceMessage` - used to invoke service functions
/// or receive service answers.
abstract class ServiceMessage extends Message {
  /// Creates a [ServiceMessage] with a newly generated UUIDv4 if [messageId] is
  /// not set.
  ///
  /// Creates empty defaults for [receivers], [sender] and [serviceType].
  ServiceMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.serviceType = ''})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// The fml4.0 key to a specific service functionality.
  ///
  /// Example: `fml40.Harvester.getProductionData`
  String serviceType;

  /// Fills this [ServiceMessage] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.serviceType])
  /// in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  @override
  void generateFromJson(Map<String, dynamic> json) {
    super.generateFromJson(json);
    try {
      serviceType = json.containsKey(BrokerKeys.serviceType)
          ? json[BrokerKeys.serviceType] as String
          : throw JsonMissingKeyException(
              BrokerKeys.serviceType, json.toString());
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.serviceType] = serviceType;
    return newJson;
  }
}

/// Used to invoke a specific service function with optional parameters.
class ServiceRequest extends ServiceMessage {
  /// Creates a [ServiceRequest] with a newly generated UUIDv4 if [messageId] is
  /// not set.
  ///
  /// Creates empty defaults for [receivers], [sender] and [serviceType].
  ServiceRequest(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      String serviceType = '',
      this.parameters = const <String, dynamic>{}})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint,
            serviceType: serviceType);

  /// Creates a [ServiceRequest] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.serviceType], [BrokerKeys.parameters]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    try {
      final ServiceRequest msg = ServiceRequest()
        ..generateFromJson(json)
        ..parameters = json.containsKey(BrokerKeys.parameters)
            ? json[BrokerKeys.parameters] as Map<String, dynamic>
            : throw JsonMissingKeyException(
                BrokerKeys.parameters, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The parameter passed to the service.
  ///
  /// If and what for parameters needed is documented in the fml4.0 method.
  Map<String, dynamic> parameters;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.serviceRequest;
    newJson[BrokerKeys.parameters] = parameters;
    return newJson;
  }
}

/// Used to return the results of a specific service function.
class ServiceReply extends ServiceMessage {
  /// Creates a [ServiceReply] with a newly generated UUIDv4 if [messageId] is
  /// not set.
  ///
  /// Creates empty defaults for [receivers], [sender] and [serviceType].
  ServiceReply(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      String serviceType = '',
      this.results = const <String, dynamic>{}})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint,
            serviceType: serviceType);

  /// Creates a [ServiceReply] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.serviceType], [BrokerKeys.results]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory ServiceReply.fromJson(Map<String, dynamic> json) {
    try {
      final ServiceReply msg = ServiceReply()
        ..generateFromJson(json)
        ..results = json.containsKey(BrokerKeys.results)
            ? json[BrokerKeys.results] as Map<String, dynamic>
            : throw JsonMissingKeyException(
                BrokerKeys.results, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The results generated by the service function.
  ///
  /// If and what for parameters are returned is documented in the
  /// fml4.0 method.
  Map<String, dynamic> results;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.serviceReply;
    newJson[BrokerKeys.results] = results;
    return newJson;
  }
}
