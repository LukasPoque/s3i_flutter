import 'package:s3i_flutter/src/broker/message.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// Represents a `S3I::B::AttributeValueMessage` - used to modify specific
/// data at an other thing in the S3I.
abstract class AttributeValueMessage extends Message {
  /// Creates a [AttributeValueMessage] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  AttributeValueMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);
}

/// Represents a `S3I::B::GetValueMessage` - used to get a specific value.
abstract class GetValueMessage extends AttributeValueMessage {
  /// Creates a [GetValueMessage] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  GetValueMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);
}

/// Represents a `S3I::B::SetValueMessage` - used to set a specific value.
abstract class SetValueMessage extends AttributeValueMessage {
  /// Creates a [SetValueMessage] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  SetValueMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);
}

/// Represents a `S3I::B::DeleteAttributeMessage` - used to delete a specific
/// value.
abstract class DeleteAttributeMessage extends AttributeValueMessage {
  /// Creates a [DeleteAttributeMessage] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  DeleteAttributeMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);
}

/// Represents a `S3I::B::GetValueMessage` - used to create a specific value.
abstract class CreateAttributeMessage extends AttributeValueMessage {
  /// Creates a [CreateAttributeMessage] with a newly generated UUIDv4 if
  /// [messageId] is not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  CreateAttributeMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);
}

/// Represents a `S3I::B::GetValueRequest` - used to request to get a
/// specific value.
class GetValueRequest extends GetValueMessage {
  /// Creates a [GetValueRequest] with a newly generated UUIDv4 if [messageId]
  /// is not set.
  ///
  /// Creates empty defaults for [receivers], [sender] and [attributePath].
  GetValueRequest(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.attributePath = ''})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// Creates a [GetValueRequest] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.attributePath]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory GetValueRequest.fromJson(Map<String, dynamic> json) {
    try {
      final GetValueRequest msg = GetValueRequest()
        ..generateFromJson(json)
        ..attributePath = json.containsKey(BrokerKeys.attributePath)
            ? json[BrokerKeys.attributePath] as String
            : throw JsonMissingKeyException(
                BrokerKeys.attributePath, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The fml4.0 path to a specific value.
  ///
  /// Example: `features/location`
  String attributePath;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.getValueRequest;
    newJson[BrokerKeys.attributePath] = attributePath;
    return newJson;
  }
}

/// Represents a `S3I::B::GetValueReply` - used to answer a GetValueRequest.
class GetValueReply extends GetValueMessage {
  /// Creates a [GetValueReply] with a newly generated UUIDv4 if [messageId]
  /// is not set.
  ///
  /// Creates empty defaults for [receivers], [sender] and [value] (null).
  GetValueReply(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.value})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// Creates a [GetValueReply] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender],
  /// [BrokerKeys.value]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory GetValueReply.fromJson(Map<String, dynamic> json) {
    try {
      final GetValueReply msg = GetValueReply()
        ..generateFromJson(json)
        ..value = json.containsKey(BrokerKeys.value)
            ? json[BrokerKeys.value] as String
            : throw JsonMissingKeyException(BrokerKeys.value, json.toString());
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The value of the requested attributePath.
  dynamic value;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.getValueReply;
    newJson[BrokerKeys.value] = value;
    return newJson;
  }
}

// TODO(poq): add support for SetValueRequest, SetValueReply,
//  DeleteAttributeRequest, DeleteAttributeReply, CreateAttributeRequest,
//  CreateAttributeReply
