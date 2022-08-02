import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:s3i_flutter/s3i_flutter.dart';

// TODO(poq): if the broker rest api supports other exchanges -> update

/// The [EventSystemConnector] simplifies the usage of the S3I-Event-System.
///
/// Usable for only one event queue.
///
/// It's provides methods to connect/subscribe to the different events types
/// `namedEvents` and `customEvents` and parses the events messages.
class EventSystemConnector {
  /// Creates a new [EventSystemConnector] with a [s3iCore] and
  /// a [brokerInterface] connected to the "normal" exchange.
  ///
  /// The [brokerInterface] is optional because it's only used for custom
  /// events.
  EventSystemConnector(this.s3iCore, {this.brokerInterface}) {
    _eventBrokerConnector = getActiveBrokerEventConnector(s3iCore.authManager);
    _eventBrokerConnector
      ..subscribeEventMessageReceived((EventMessage event) {
        if (_eventCallbacks.containsKey(event.topic)) {
          for (final Function(EventMessage event) callbackF
              in _eventCallbacks[event.topic]!) {
            callbackF(event);
          }
        }
      })
      ..subscribeConsumingFailed((String endpoint, Exception exception) {
        onErrorCallback(S3IException(exception.toString()));
      });
    if (brokerInterface != null) {
      brokerInterface!.subscribeEventSubscriptionResponseReceived(
          (EventSubscriptionResponse response) {
        if (!response.ok) {
          // TODO(poq): custom event type with topic as member
          onErrorCallback(S3IException('CustomEventSubscription failed'));
        }
      });
    }
  }

  /// The [S3ICore] used to connect to the Config REST API.
  final S3ICore s3iCore;

  /// The [ActiveBrokerInterface] used to communicate with the publisher
  /// via the normal direct exchange.
  final ActiveBrokerInterface? brokerInterface;

  /// This callback is invoked if an error occurs during subscription/message
  /// receiving.
  // ignore: prefer_function_declarations_over_variables
  final Function(S3IException exception) onErrorCallback =
      (S3IException exception) {};

  /// The broker interface for communication with the eventExchange.
  late final ActiveBrokerInterface _eventBrokerConnector;

  /// Stores the topics of the subscribed events and the matching callbacks.
  Map<String, List<Function(EventMessage event)>> _eventCallbacks =
      <String, List<Function(EventMessage event)>>{};

  /// The endpoint to which the [_eventBrokerConnector] is connected.
  Endpoint? _endpoint;

  /// Handles the complete process to receive custom events from an other thing.
  ///
  /// The [brokerInterface] should be connected to the [ownQueue] before
  /// calling this! Throws [S3IException] if [brokerInterface] is NULL.
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
    if (brokerInterface == null) {
      throw S3IException('Missing brokerInterface in subscribeCustomEvent');
    }
    final String thisThingId = s3iCore.authManager.clientIdentity.id;
    final String eventHash = md5
        .convert(
            utf8.encode(filter.generateString() + attributePaths.toString()))
        .toString();
    final String eventTopic = '$publisherThingId.$eventHash';
    //await subscribeNamedEvent(publisherThingId,
    //    eventTopic: {eventTopic}, eventCallback: eventCallback);
    //TDOD: change!
    final EventSubscriptionRequest request = EventSubscriptionRequest(
        receivers: <String>{publisherThingId},
        sender: thisThingId,
        replyToEndpoint: ownQueue,
        filter: filter.generateString(),
        attributePaths: attributePaths);
    brokerInterface!.sendMessage(request, <String>{publisherNormalQueue});
    return eventTopic;
  }

  /// Creates a queue binding to the given [eventTopic] and starts consuming.
  Future<void> subscribeNamedEvent(String publisherThingId,
      {required Map<String, List<Function(EventMessage event)>> events}) async {
    final String thisThingId = s3iCore.authManager.clientIdentity.id;
    // TODO(poq): change!
    _eventCallbacks = events;
    _endpoint = await s3iCore.createEventQueueBinding(
        thisThingId, events.keys.toList());
    await _eventBrokerConnector.startConsuming(_endpoint!.endpoint);
  }

  // TODO(poq): add method for unsubscribe specific events

  /// Shuts down the connection to the broker. Currently the broker queue is
  /// deleted too (the REST-API creates queues with `auto_delete = true`).
  void stopConsumingEvents() {
    if (_endpoint != null) {
      _eventBrokerConnector.stopConsuming(_endpoint!.endpoint);
      _eventCallbacks.clear();
    }
  }
}
