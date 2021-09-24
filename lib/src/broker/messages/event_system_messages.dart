import 'package:s3i_flutter/src/broker/messages/message.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// Used to send a Subscription Request to an other thing.
///
/// This is used for the S3I-Event-System, see
/// https://github.com/LukasPoque/s3i_flutter/issues/9#issuecomment-925665563
/// for the current draft.
class EventSubscriptionRequest extends Message {
  /// Creates a [EventSubscriptionRequest] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers], [sender], [filter]
  /// and [attributePaths].
  EventSubscriptionRequest(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.filter = '',
      this.attributePaths = const <String>[]})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// Creates a [EventSubscriptionRequest] with the information stored in
  /// the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.serviceType], [BrokerKeys.filter], [BrokerKeys.attributePaths]
  /// ) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory EventSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    try {
      final EventSubscriptionRequest msg = EventSubscriptionRequest()
        ..generateFromJson(json)
        ..filter = json.containsKey(BrokerKeys.filter)
            ? json[BrokerKeys.filter] as String
            : throw JsonMissingKeyException(BrokerKeys.filter, json.toString())
        ..attributePaths = json.containsKey(BrokerKeys.attributePaths)
            ? json[BrokerKeys.attributePaths] as List<String>
            : throw JsonMissingKeyException(
                BrokerKeys.attributePaths, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The RQL Filter used to check if a event is triggered.
  String filter;

  /// The JSON pointer to the attributes which should be included in the event.
  List<String> attributePaths;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.customEventRequest;
    newJson[BrokerKeys.filter] = filter;
    newJson[BrokerKeys.attributePaths] = attributePaths;
    return newJson;
  }
}

/// Used to send a Subscription Response to an other thing.
///
/// This is used for the S3I-Event-System, see
/// https://github.com/LukasPoque/s3i_flutter/issues/9#issuecomment-925665563
/// for the current draft.
class EventSubscriptionResponse extends Message {
  /// Creates a [EventSubscriptionResponse] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers], [sender], [topic] and sets [ok]
  /// to false.
  EventSubscriptionResponse(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.topic = '',
      this.ok = false})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// Creates a [EventSubscriptionResponse] with the information stored in the
  /// [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.serviceType], [BrokerKeys.ok]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory EventSubscriptionResponse.fromJson(Map<String, dynamic> json) {
    try {
      final EventSubscriptionResponse msg = EventSubscriptionResponse()
        ..generateFromJson(json)
        ..topic = json.containsKey(BrokerKeys.topic)
            ? json[BrokerKeys.topic] as String
            : ''
        ..ok = json.containsKey(BrokerKeys.ok)
            ? json[BrokerKeys.ok] as bool
            : throw JsonMissingKeyException(BrokerKeys.ok, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The topic used to publish the event messages (ThingId.eventTopic).
  String topic;

  /// Indicates if the [EventSubscriptionRequest] was correct.
  bool ok;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.customEventReply;
    newJson[BrokerKeys.ok] = ok;
    if (topic.isNotEmpty) newJson[BrokerKeys.topic] = topic;
    return newJson;
  }
}

/// Used to send an Event (named/custom).
///
/// This is used for the S3I-Event-System, see
/// https://github.com/LukasPoque/s3i_flutter/issues/9#issuecomment-925665563
/// for the current draft.
class EventMessage extends Message {
  /// Creates a [EventMessage] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers], [sender], [topic],
  /// [timestamp] to the epoch start and [content] to an empty map.
  EventMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.topic = '',
      DateTime? timestampEvent,
      this.content = const <String, dynamic>{}})
      : timestamp = timestampEvent ?? DateTime(1970),
        super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// Creates a [EventMessage] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.serviceType], [BrokerKeys.topic], [BrokerKeys.timestamp],
  /// [BrokerKeys.content]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory EventMessage.fromJson(Map<String, dynamic> json) {
    try {
      final EventMessage msg = EventMessage()
        ..generateFromJson(json)
        ..topic = json.containsKey(BrokerKeys.topic)
            ? json[BrokerKeys.topic] as String
            : throw JsonMissingKeyException(BrokerKeys.topic, json.toString())
        ..timestamp = json.containsKey(BrokerKeys.timestamp)
            ? DateTime.fromMillisecondsSinceEpoch(json[BrokerKeys.ok] as int)
            : throw JsonMissingKeyException(
                BrokerKeys.timestamp, json.toString())
        ..content = json.containsKey(BrokerKeys.content)
            ? json[BrokerKeys.content] as Map<String, dynamic>
            : throw JsonMissingKeyException(
                BrokerKeys.content, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The topic used to publish the event messages (ThingId.eventTopic).
  String topic;

  /// The timestamp when the event took place.
  DateTime timestamp;

  /// The content of the event message.
  Map<String, dynamic> content;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.eventMessage;
    newJson[BrokerKeys.topic] = topic;
    newJson[BrokerKeys.content] = content;
    return newJson;
  }
}
