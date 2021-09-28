import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/broker/messages/event_system_messages.dart';

// TODO(poq): if the broker rest api supports other exchanges -> update

/// The [EventSystemConnector] simplifies the usage of the S3I-Event-System.
///
/// It's provides methods to connect/subscribe to the different events types
/// `namedEvents` and `customEvents` and parses the events messages.
class EventSystemConnector {
  /// Creates a new [EventSystemConnector] with a [s3iCore] and
  /// a [brokerInterface].
  EventSystemConnector(this.s3iCore, this.brokerInterface) {
    _eventBrokerConnector = getActiveBrokerEventConnector(s3iCore.authManager);
    _eventBrokerConnector
      ..subscribeEventMessageReceived((EventMessage event) {
        if (_eventCallbacks.containsKey(event.topic)) {
          _eventCallbacks[event.topic]!(event);
        }
      })
      ..subscribeConsumingFailed((String endpoint, Exception exception) {
        onErrorCallback(S3IException(exception.toString()));
      });
    brokerInterface.subscribeEventSubscriptionResponseReceived(
        (EventSubscriptionResponse response) {
      if (!response.ok) {
        // TODO(poq): custom event type with topic as member
        onErrorCallback(S3IException('CustomEventSubscription failed'));
      }
    });
  }

  /// The [S3ICore] used to connect to the Config REST API.
  final S3ICore s3iCore;

  /// The [ActiveBrokerInterface] used to communicate with the publisher
  /// via the normal direct exchange.
  final ActiveBrokerInterface brokerInterface;

  /// This callback is invoked if an error occurs during subscription/message
  /// receiving.
  // ignore: prefer_function_declarations_over_variables
  final Function(S3IException exception) onErrorCallback =
      (S3IException exception) {};

  /// The broker interface for communication with the eventExchange.
  late final ActiveBrokerInterface _eventBrokerConnector;

  /// Stores the topics of the subscribed events and the matching callbacks.
  final Map<String, Function(EventMessage event)> _eventCallbacks =
      <String, Function(EventMessage event)>{};

  /// Handles the complete process to receive custom events from an other thing.
  ///
  /// The [brokerInterface] should be connected to the [ownQueue] before
  /// calling this!
  ///
  /// Returns the topic of this specific event. If an exception occurs,
  /// [onErrorCallback] is called.
  ///
  /// Sequence:
  /// - create event topic with the md5-hash of the [filter] and
  /// [attributePaths]
  /// - add the callback to [_eventCallbacks]
  /// - create/bind queue to this topic and the event exchange via the REST API
  /// - connect to the queue with the [_eventBrokerConnector]
  /// - send a [EventSubscriptionRequest] to the thing
  Future<String> subscribeCustomEvent(String publisherThingId,
      {required String publisherNormalQueue,
      required String ownQueue,
      required RQLQuery filter,
      required List<String> attributePaths,
      required Function(EventMessage event) eventCallback}) async {
    final String thisThingId = s3iCore.authManager.clientIdentity.id;
    final String eventHash = md5
        .convert(
            utf8.encode(filter.generateString() + attributePaths.toString()))
        .toString();
    final String eventTopic = '$publisherThingId.$eventHash';
    await subscribeNamedEvent(publisherThingId,
        eventTopic: eventTopic, eventCallback: eventCallback);
    final EventSubscriptionRequest request = EventSubscriptionRequest(
        receivers: <String>{publisherThingId},
        sender: thisThingId,
        replyToEndpoint: ownQueue,
        filter: filter.generateString(),
        attributePaths: attributePaths);
    brokerInterface.sendMessage(request, <String>{publisherNormalQueue});
    return eventTopic;
  }

  /// Creates a queue binding to the given [eventTopic] and starts consuming.
  Future<void> subscribeNamedEvent(String publisherThingId,
      {required String eventTopic,
      required Function(EventMessage event) eventCallback}) async {
    final String thisThingId = s3iCore.authManager.clientIdentity.id;
    _eventCallbacks[eventTopic] = eventCallback;
    final Endpoint endpoint =
        await s3iCore.createEventQueueBinding(thisThingId, eventTopic);
    await _eventBrokerConnector.startConsuming(endpoint.endpoint);
  }
}
