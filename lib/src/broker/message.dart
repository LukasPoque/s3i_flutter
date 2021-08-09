import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/json_serializable_object.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';
import 'package:uuid/uuid.dart';

// TODO(poq): add support for encrypted messages

/// The baseclass for decrypted `S3I-B-Messages`.
///
/// See the [KWH-Standpunkt](https://www.kwh40.de/wp-content/uploads/2020/04/KWH40-Standpunkt-S3I-v2.0.pdf)
/// for detailed information.
abstract class Message extends JsonSerializableObject {
  /// Creates a new [Message] with a newly generated UUIDv4 if [messageId] is
  /// not set.
  ///
  /// Creates empty defaults for [receivers] and [sender].
  Message(
      {String? messageId,
      this.receivers = const <String>{},
      this.sender = '',
      this.replyingToMessage,
      this.replyToEndpoint}) {
    _identifier = messageId ?? const Uuid().v4();
  }

  /// Fills this [Message] with the information stored in the [json].
  ///
  /// Throws a [JsonMissingKeyException] if there is missing one of the needed
  /// keys ([BrokerKeys.identifier], [BrokerKeys.receivers],[BrokerKeys.sender])
  /// in the [json].
  /// Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type.
  void generateFromJson(Map<String, dynamic> json) {
    try {
      _identifier = json.containsKey(BrokerKeys.identifier)
          ? json[BrokerKeys.identifier] as String
          : throw JsonMissingKeyException(
              BrokerKeys.identifier, json.toString());
      receivers = json.containsKey(BrokerKeys.receivers)
          ? _createReceiversSet(json[BrokerKeys.receivers] as List<dynamic>)
          : throw JsonMissingKeyException(
              BrokerKeys.receivers, json.toString());
      sender = json.containsKey(BrokerKeys.sender)
          ? json[BrokerKeys.sender] as String
          : throw JsonMissingKeyException(BrokerKeys.sender, json.toString());
      replyingToMessage = json[BrokerKeys.replyingToMessage] as String?;
      replyToEndpoint = json[BrokerKeys.replyToEndpoint] as String?;
    } on TypeError catch (e) {
      throw InvalidJsonSchemaException(
          e.stackTrace.toString(), json.toString());
    }
  }

  /// Should be not editable from the outside, see [identifier] for the getter.
  late String _identifier;

  /// The unique identifier of this message (UUIDv4).
  ///
  /// Is generated in the constructor if not other specified.
  String get identifier => _identifier;

  /// All receivers of this message (should be a `s3I:UUIDv4` of the
  /// receiving thing).
  Set<String> receivers;

  /// The sender of this message (should be a `s3I:UUIDv4` of the publishing
  /// thing).
  String sender;

  /// The identifier of the message to which this message is answering.
  String? replyingToMessage;

  /// The endpoint to which the answer to this message should be sent.
  String? replyToEndpoint;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    newJson[BrokerKeys.identifier] = _identifier;
    newJson[BrokerKeys.receivers] = receivers.toList();
    newJson[BrokerKeys.sender] = sender;
    if (replyingToMessage != null)
      newJson[BrokerKeys.replyingToMessage] = replyingToMessage;
    if (replyToEndpoint != null)
      newJson[BrokerKeys.replyToEndpoint] = replyToEndpoint;
    return newJson;
  }

  static Set<String> _createReceiversSet(List<dynamic> jsonList) {
    return jsonList.map((dynamic dynString) => dynString as String).toSet();
  }
}
