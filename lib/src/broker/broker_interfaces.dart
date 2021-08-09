import 'dart:convert';

import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/broker/attribute_value_messages.dart';
import 'package:s3i_flutter/src/broker/message.dart';
import 'package:s3i_flutter/src/broker/service_messages.dart';
import 'package:s3i_flutter/src/broker/user_message.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// The baseclass for all communication interfaces with the `S3I-Broker`.
///
/// There are two different approaches to receive messages from the Broker:
/// - [ActiveBrokerInterface] for interfaces who inform you whenever a new
/// message is available.
/// - [PassiveBrokerInterface] for interfaces where you need to explicit ask
/// if there are new messages.
abstract class BrokerInterface {
  /// Creates a [BrokerInterface] with the given [authManager].
  BrokerInterface(this.authManager);

  /// The authentication manager used by this instance to get
  /// valid access tokens.
  final AuthenticationManager authManager;

  /// Publishes the given [message] to all [endpoints].
  ///
  /// The endpoints should be in the correct format (`s3ib://s3i:`+ UUIDv4
  /// for decrypted communication or `s3ibs://s3i:` + UUIDv4 for encrypted
  /// messages).
  void sendMessage(Message message, Set<String> endpoints);

  /// Returns a new created [Message] with the information stored in the [json].
  ///
  /// The returned message is ready constructed and could be checked for it's
  /// type by using the `is` keyword.
  ///
  /// Currently supported message types: [UserMessage], [ServiceRequest],
  /// [ServiceReply], [GetValueRequest], [GetValueReply].
  ///
  /// Throws a [JsonMissingKeyException] if there is a missing key in the
  /// [json]. Throws a [InvalidJsonSchemaException] if some values
  /// doesn't match the expected value type or if the [BrokerKeys.messageType]
  /// is unknown/unsupported.
  static Message transformJsonToMessage(Map<String, dynamic> json) {
    final String messageType = json.containsKey(BrokerKeys.messageType)
        ? json[BrokerKeys.messageType] as String
        : throw JsonMissingKeyException(
            BrokerKeys.messageType, json.toString());
    switch (messageType) {
      case BrokerKeys.userMessage:
        return UserMessage.fromJson(json);
      case BrokerKeys.serviceRequest:
        return ServiceRequest.fromJson(json);
      case BrokerKeys.serviceReply:
        return ServiceReply.fromJson(json);
      case BrokerKeys.getValueRequest:
        return GetValueRequest.fromJson(json);
      case BrokerKeys.getValueReply:
        return GetValueReply.fromJson(json);
      default:
        throw InvalidJsonSchemaException(
            'unknown/unsupported message type', json.toString());
    }
  }
}

/// The [ActiveBrokerInterface] is the baseclass for all broker interfaces
/// which inform the user asynchronous (via a callback) when a new message is
/// available.
abstract class ActiveBrokerInterface extends BrokerInterface {
  /// Creates a new [ActiveBrokerInterface] with the given [authManager].
  ActiveBrokerInterface(AuthenticationManager authManager) : super(authManager);

  /// All registered functions which are invoked if an invalid message is
  /// received.
  final Set<Function(String, String)> _callbacksForInvalidMessage =
      <Function(String, String)>{};

  /// All registered functions which are invoked if an [UserMessage] is
  /// received.
  final Set<Function(UserMessage)> _callbacksForUserMessage =
      <Function(UserMessage)>{};

  /// All registered functions which are invoked if an [ServiceRequest] is
  /// received.
  final Set<Function(ServiceRequest)> _callbacksForServiceRequest =
      <Function(ServiceRequest)>{};

  /// All registered functions which are invoked if an [ServiceReply] is
  /// received.
  final Set<Function(ServiceReply)> _callbacksForServiceReply =
      <Function(ServiceReply)>{};

  /// All registered functions which are invoked if an [GetValueRequest] is
  /// received.
  final Set<Function(GetValueRequest)> _callbacksForGetValueRequest =
      <Function(GetValueRequest)>{};

  /// All registered functions which are invoked if an [GetValueReply] is
  /// received.
  final Set<Function(GetValueReply)> _callbacksForGetValueReply =
      <Function(GetValueReply)>{};

  // TODO(poq): add the other message types

  /// Starts consuming on the endpoint.
  ///
  /// The endpoints should be in the correct format (`s3ib://s3i:`+ UUIDv4
  /// for decrypted communication or `s3ibs://s3i:` + UUIDv4 for encrypted
  /// messages).
  void startConsuming(String endpoint);

  /// Stops consuming on the endpoint.
  ///
  /// The endpoints should be in the correct format (`s3ib://s3i:`+ UUIDv4
  /// for decrypted communication or `s3ibs://s3i:` + UUIDv4 for encrypted
  /// messages).
  void stopConsuming(String endpoint);

  /// PROTECTED: DO NOT USE THIS METHOD UNLESS YOU ARE AN
  /// [ActiveBrokerInterface] !
  ///
  /// This method could be used from an implementation of this interface when
  /// it receives a message. It decodes the [messageString], creates a new
  /// message and notifies the subscribed callbacks.
  ///
  /// This shouldn't throw anything for safe usage.
  void newMessageReceived(String messageString) {
    try {
      final Map<String, dynamic> decodedMessage =
          jsonDecode(messageString) as Map<String, dynamic>;
      final Message message =
          BrokerInterface.transformJsonToMessage(decodedMessage);
      if (message is UserMessage) {
        _notifyUserMessageReceived(message);
      } else if (message is ServiceRequest) {
        _notifyServiceRequestReceived(message);
      } else if (message is ServiceReply) {
        _notifyServiceReplyReceived(message);
      } else if (message is GetValueRequest) {
        _notifyGetValueRequestReceived(message);
      } else if (message is GetValueReply) {
        _notifyGetValueReplyReceived(message);
      } else {
        _notifyInvalidMessageReceived(messageString, 'unknown type');
      }
    } on TypeError catch (e) {
      _notifyInvalidMessageReceived(messageString, e.stackTrace.toString());
    } on InvalidJsonSchemaException catch (e) {
      _notifyInvalidMessageReceived(messageString, e.toString());
    }
  }

  /// Subscribes to all received messages which can't be parsed correctly
  /// (InvalidMessageReceived-Event).
  ///
  /// The first passed String is the original message and the second one is a
  /// textual representation of the error during the parsing process.
  void subscribeInvalidMessageReceived(Function(String, String) callback) {
    _callbacksForInvalidMessage.add(callback);
  }

  /// Unsubscribes the callback from the InvalidMessageReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeInvalidMessageReceived(Function(String, String) callback) {
    _callbacksForInvalidMessage.remove(callback);
  }

  /// Subscribes to all received user messages (UserMessageReceived-Event).
  void subscribeUserMessageReceived(Function(UserMessage) callback) {
    _callbacksForUserMessage.add(callback);
  }

  /// Unsubscribes the callback from the UserMessageReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeUserMessageReceived(Function(UserMessage) callback) {
    _callbacksForUserMessage.remove(callback);
  }

  /// Subscribes to all ServiceRequestReceived-Events.
  void subscribeServiceRequestReceived(Function(ServiceRequest) callback) {
    _callbacksForServiceRequest.add(callback);
  }

  /// Unsubscribes the callback from the ServiceRequestReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeServiceRequestReceived(Function(ServiceRequest) callback) {
    _callbacksForServiceRequest.remove(callback);
  }

  /// Subscribes to all ServiceReplyReceived-Events.
  void subscribeServiceReplyReceived(Function(ServiceReply) callback) {
    _callbacksForServiceReply.add(callback);
  }

  /// Unsubscribes the callback from the ServiceReplyReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeServiceReplyReceived(Function(ServiceReply) callback) {
    _callbacksForServiceReply.remove(callback);
  }

  /// Subscribes to all GetValueRequestReceived-Events.
  void subscribeGetValueRequestReceived(Function(GetValueRequest) callback) {
    _callbacksForGetValueRequest.add(callback);
  }

  /// Unsubscribes the callback from the GetValueRequestReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeGetValueRequestReceived(Function(GetValueRequest) callback) {
    _callbacksForGetValueRequest.remove(callback);
  }

  /// Subscribes to all GetValueReplyReceived-Events.
  void subscribeGetValueReplyReceived(Function(GetValueReply) callback) {
    _callbacksForGetValueReply.add(callback);
  }

  /// Unsubscribes the callback from the GetValueReplyReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeGetValueReplyReceived(Function(GetValueReply) callback) {
    _callbacksForGetValueReply.remove(callback);
  }

  void _notifyInvalidMessageReceived(String original, String error) {
    for (final Function(String, String) callback
        in _callbacksForInvalidMessage) {
      callback(original, error);
    }
  }

  void _notifyUserMessageReceived(UserMessage message) {
    for (final Function(UserMessage) callback in _callbacksForUserMessage) {
      callback(message);
    }
  }

  void _notifyServiceRequestReceived(ServiceRequest message) {
    for (final Function(ServiceRequest) callback
        in _callbacksForServiceRequest) {
      callback(message);
    }
  }

  void _notifyServiceReplyReceived(ServiceReply message) {
    for (final Function(ServiceReply) callback in _callbacksForServiceReply) {
      callback(message);
    }
  }

  void _notifyGetValueRequestReceived(GetValueRequest message) {
    for (final Function(GetValueRequest) callback
        in _callbacksForGetValueRequest) {
      callback(message);
    }
  }

  void _notifyGetValueReplyReceived(GetValueReply message) {
    for (final Function(GetValueReply) callback in _callbacksForGetValueReply) {
      callback(message);
    }
  }
}

/// The [PassiveBrokerInterface] is the baseclass for all broker interfaces
/// where the user needs to call a method to see if a new message is available.
abstract class PassiveBrokerInterface extends BrokerInterface {
  /// Creates a new [PassiveBrokerInterface] with the given [authManager].
  PassiveBrokerInterface(AuthenticationManager authManager)
      : super(authManager);

  /// Returns a [Message] if it's available at the [endpoint], null otherwise.
  Message? getMessage(String endpoint);
}
