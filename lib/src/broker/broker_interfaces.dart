import 'dart:convert';

import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/broker/messages/attribute_value_messages.dart';
import 'package:s3i_flutter/src/broker/messages/event_system_messages.dart';
import 'package:s3i_flutter/src/broker/messages/message.dart';
import 'package:s3i_flutter/src/broker/messages/service_messages.dart';
import 'package:s3i_flutter/src/broker/messages/user_message.dart';
import 'package:s3i_flutter/src/exceptions/invalid_json_schema_exception.dart';
import 'package:s3i_flutter/src/exceptions/json_missing_key_exception.dart';
import 'package:s3i_flutter/src/exceptions/parse_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// The baseclass for all communication interfaces with the `S3I-Broker`.
///
/// There are two different approaches to receive messages from the Broker:
/// - [ActiveBrokerInterface] for interfaces that inform you whenever a new
/// message is available.
/// - [PassiveBrokerInterface] for interfaces where you need to explicitly ask
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
      case BrokerKeys.customEventRequest:
        return EventSubscriptionRequest.fromJson(json);
      case BrokerKeys.customEventReply:
        return EventSubscriptionResponse.fromJson(json);
      case BrokerKeys.eventMessage:
        return EventMessage.fromJson(json);
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

/// The [PassiveBrokerInterface] is the baseclass for all broker interfaces
/// where the user needs to call a method to see if a new message is available.
abstract class PassiveBrokerInterface extends BrokerInterface {
  /// Creates a new [PassiveBrokerInterface] with the given [authManager].
  PassiveBrokerInterface(AuthenticationManager authManager)
      : super(authManager);

  /// Returns a [Message] if it's available at the [endpoint], null otherwise.
  Message? getMessage(String endpoint);
}

/// The [ActiveBrokerInterface] is the baseclass for all broker interfaces
/// which inform the user asynchronous (via a callback) when a new message is
/// available.
abstract class ActiveBrokerInterface extends BrokerInterface {
  /// Creates a new [ActiveBrokerInterface] with the given [authManager].
  ActiveBrokerInterface(AuthenticationManager authManager) : super(authManager);

  /// All registered functions which are invoked if an error occurred during the
  /// message consuming.
  final Set<Function(String, Exception)> _callbacksConsumingFailed =
      <Function(String, Exception)>{};

  /// All registered functions which are invoked if a message could not be sent.
  final Set<Function(Message, Exception)> _callbacksSendMessageFailed =
      <Function(Message, Exception)>{};

  /// All registered functions which are invoked if a message is sent.
  final Set<Function(Message)> _callbacksSendMessageSucceeded =
      <Function(Message)>{};

  /// All registered functions which are invoked if an invalid message is
  /// received.
  final Set<Function(String, Exception)> _callbacksForInvalidMessage =
      <Function(String, Exception)>{};

  /// All registered functions which are invoked if an [UserMessage] is
  /// received.
  final Set<Function(UserMessage)> _callbacksForUserMessage =
      <Function(UserMessage)>{};

  /// All registered functions which are invoked if an [EventMessage] is
  /// received.
  final Set<Function(EventMessage)> _callbacksForEventMessage =
      <Function(EventMessage)>{};

  /// All registered functions which are invoked if an
  /// [EventSubscriptionRequest] is received.
  final Set<Function(EventSubscriptionRequest)>
      _callbacksForEventSubscriptionRequest =
      <Function(EventSubscriptionRequest)>{};

  /// All registered functions which are invoked if an
  /// [EventSubscriptionResponse] is received.
  final Set<Function(EventSubscriptionResponse)>
      _callbacksForEventSubscriptionResponse =
      <Function(EventSubscriptionResponse)>{};

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
  Future<void> startConsuming(String endpoint);

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
      } else if (message is EventMessage) {
        _notifyEventMessageReceived(message);
      } else if (message is EventSubscriptionRequest) {
        _notifyEventSubscriptionRequestReceived(message);
      } else if (message is EventSubscriptionResponse) {
        _notifyEventSubscriptionResponseReceived(message);
      } else if (message is ServiceRequest) {
        _notifyServiceRequestReceived(message);
      } else if (message is ServiceReply) {
        _notifyServiceReplyReceived(message);
      } else if (message is GetValueRequest) {
        _notifyGetValueRequestReceived(message);
      } else if (message is GetValueReply) {
        _notifyGetValueReplyReceived(message);
      } else {
        _notifyInvalidMessageReceived(
            messageString, ParseException('unknown message type'));
      }
    } on TypeError catch (e) {
      _notifyInvalidMessageReceived(
          messageString, ParseException(e.stackTrace.toString()));
    } on InvalidJsonSchemaException catch (e) {
      _notifyInvalidMessageReceived(messageString, e);
    }
  }

  /// Subscribes to all errors during consuming from the endpoints.
  /// (ConsumingFailed-Event).
  ///
  /// The first passed String is the endpoint and the second one is the
  /// exception during the connection process.
  void subscribeConsumingFailed(Function(String, Exception) callback) {
    _callbacksConsumingFailed.add(callback);
  }

  /// Unsubscribes the callback from the ConsumingFailed-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeConsumingFailed(Function(String, Exception) callback) {
    _callbacksConsumingFailed.remove(callback);
  }

  /// Subscribes to all messages which couldn't be sent correctly
  /// (SendMessageFailed-Event).
  ///
  /// The first passed Message is the original message and the second one is
  /// the exception during the sending process.
  void subscribeSendMessageFailed(Function(Message, Exception) callback) {
    _callbacksSendMessageFailed.add(callback);
  }

  /// Unsubscribes the callback from the SendMessageFailed-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeSendMessageFailed(Function(Message, Exception) callback) {
    _callbacksSendMessageFailed.remove(callback);
  }

  /// Subscribes to all received messages which can't be parsed correctly
  /// (SendMessageSucceeded-Event).
  ///
  /// The first passed String is the original message and the second one is a
  /// textual representation of the error during the parsing process.
  void subscribeSendMessageSucceeded(Function(Message) callback) {
    _callbacksSendMessageSucceeded.add(callback);
  }

  /// Unsubscribes the callback from the SendMessageSucceeded-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeSendMessageSucceeded(Function(Message) callback) {
    _callbacksSendMessageSucceeded.remove(callback);
  }

  /// Subscribes to all received messages which can't be parsed correctly
  /// (InvalidMessageReceived-Event).
  ///
  /// The first passed String is the original message and the second one is the
  /// exception during the parsing process.
  void subscribeInvalidMessageReceived(Function(String, Exception) callback) {
    _callbacksForInvalidMessage.add(callback);
  }

  /// Unsubscribes the callback from the InvalidMessageReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeInvalidMessageReceived(Function(String, Exception) callback) {
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

  /// Subscribes to all received event messages (EventMessageReceived-Event).
  void subscribeEventMessageReceived(Function(EventMessage) callback) {
    _callbacksForEventMessage.add(callback);
  }

  /// Unsubscribes the callback from the EventMessageReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeEventMessageReceived(Function(EventMessage) callback) {
    _callbacksForEventMessage.remove(callback);
  }

  /// Subscribes to all received EventSubscriptionRequest
  /// (EventSubscriptionRequestReceived-Event).
  void subscribeEventSubscriptionRequestReceived(
      Function(EventSubscriptionRequest) callback) {
    _callbacksForEventSubscriptionRequest.add(callback);
  }

  /// Unsubscribes the callback from the EventSubscriptionRequestReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeEventSubscriptionRequestReceived(
      Function(EventSubscriptionRequest) callback) {
    _callbacksForEventSubscriptionRequest.remove(callback);
  }

  /// Subscribes to all received EventSubscriptionResponse
  /// (EventSubscriptionResponseReceived-Event).
  void subscribeEventSubscriptionResponse(
      Function(EventSubscriptionResponse) callback) {
    _callbacksForEventSubscriptionResponse.add(callback);
  }

  /// Unsubscribes the callback from the
  /// EventSubscriptionResponseReceived-Event.
  ///
  /// The [callback] needs to be exactly the same as the one used while
  /// subscribing.
  void unsubscribeEventSubscriptionResponseReceived(
      Function(EventSubscriptionResponse) callback) {
    _callbacksForEventSubscriptionResponse.remove(callback);
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

  /// PROTECTED: DO NOT USE UNLESS YOU ARE AN [ActiveBrokerInterface].
  void notifyConsumingFailed(String endpoint, Exception error) {
    for (final Function(String, Exception) callback
        in _callbacksConsumingFailed) {
      callback(endpoint, error);
    }
  }

  /// PROTECTED: DO NOT USE UNLESS YOU ARE AN [ActiveBrokerInterface].
  void notifySendMessageFailed(Message message, Exception error) {
    for (final Function(Message, Exception) callback
        in _callbacksSendMessageFailed) {
      callback(message, error);
    }
  }

  /// PROTECTED: DO NOT USE UNLESS YOU ARE AN [ActiveBrokerInterface].
  void notifySendMessageSucceeded(Message message) {
    for (final Function(Message) callback in _callbacksSendMessageSucceeded) {
      callback(message);
    }
  }

  void _notifyInvalidMessageReceived(String original, Exception error) {
    for (final Function(String, Exception) callback
        in _callbacksForInvalidMessage) {
      callback(original, error);
    }
  }

  void _notifyUserMessageReceived(UserMessage message) {
    for (final Function(UserMessage) callback in _callbacksForUserMessage) {
      callback(message);
    }
  }

  void _notifyEventMessageReceived(EventMessage message) {
    for (final Function(EventMessage) callback in _callbacksForEventMessage) {
      callback(message);
    }
  }

  void _notifyEventSubscriptionRequestReceived(
      EventSubscriptionRequest message) {
    for (final Function(EventSubscriptionRequest) callback
        in _callbacksForEventSubscriptionRequest) {
      callback(message);
    }
  }

  void _notifyEventSubscriptionResponseReceived(
      EventSubscriptionResponse message) {
    for (final Function(EventSubscriptionResponse) callback
        in _callbacksForEventSubscriptionResponse) {
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
