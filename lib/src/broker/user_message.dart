import 'package:s3i_flutter/src/broker/message.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// Represents a `S3I::B::UserMessage` - used for communication between two
/// real users.
class UserMessage extends Message {
  /// Creates a [UserMessage] with a newly generated UUIDv4 if [messageId] is
  /// not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  UserMessage(
      {String? messageId,
      Set<String> receivers = const <String>{},
      String sender = '',
      String? replyingToMessage,
      String? replyToEndpoint,
      this.attachment,
      this.subject,
      this.text})
      : super(
            messageId: messageId,
            receivers: receivers,
            sender: sender,
            replyingToMessage: replyingToMessage,
            replyToEndpoint: replyToEndpoint);

  /// Creates a [UserMessage] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender])
  /// in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  factory UserMessage.fromJson(Map<String, dynamic> json) {
    try {
      final UserMessage msg = UserMessage()
        ..generateFromJson(json)
        ..attachment = json.containsKey(BrokerKeys.attachments)
            ? Attachment.fromJson(
                json[BrokerKeys.attachments] as Map<String, dynamic>)
            : null
        ..subject = json[BrokerKeys.subject] as String?
        ..text = json[BrokerKeys.text] as String?;
      return msg;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The optional attachment of an user message.
  Attachment? attachment;

  /// The subject of a user message - should be a short topic (optional).
  String? subject;

  /// The content of the user message (optional).
  String? text;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = super.toJson();
    newJson[BrokerKeys.messageType] = BrokerKeys.userMessage;
    if (attachment != null)
      newJson[BrokerKeys.attachments] = attachment!.toJson();
    if (subject != null) newJson[BrokerKeys.subject] = subject;
    if (text != null) newJson[BrokerKeys.text] = text;
    return newJson;
  }
}

/// Represents a `S3I::B::Attachment` - an optional field of a [UserMessage].
class Attachment extends JsonSerializableObject {
  /// Creates an [Attachment] with a [filename] and [data] (both empty by
  /// default).
  Attachment({this.filename = '', this.data = ''});

  /// Returns an [Attachment] with a [filename] and the corresponding [data]
  /// from [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.filename], [BrokerKeys.data]) in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type string.
  factory Attachment.fromJson(Map<String, dynamic> json) {
    try {
      final Attachment attachment = Attachment()
        ..filename = json.containsKey(BrokerKeys.filename)
            ? json[BrokerKeys.filename] as String
            : throw JsonMissingKeyException(
                BrokerKeys.filename, json.toString())
        ..data = json.containsKey(BrokerKeys.data)
            ? json[BrokerKeys.data] as String
            : throw JsonMissingKeyException(BrokerKeys.data, json.toString());
      return attachment;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// The name of the file stored in [data].
  String filename;

  /// The data of this attachment encoded as base64 string.
  String data;

  // TODO(poq): add methods for converting base64Binary data?

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[BrokerKeys.filename] = filename;
    newJson[BrokerKeys.data] = data;
    return newJson;
  }
}
