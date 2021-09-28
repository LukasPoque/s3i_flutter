import 'dart:convert';

import 'package:http/http.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/broker/broker_interfaces.dart';
import 'package:s3i_flutter/src/broker/messages/message.dart';
import 'package:s3i_flutter/src/exceptions/network_response_exception.dart';
import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

///Creates a new [BrokerRestConnector].
///
/// The instance is created with the [authManager] and the optional constructor
/// arguments in the [args] (the string-keys should match the name of the
/// parameters).
///
/// This is needed to use the same interface on web and other platforms.
///
///The [args] have defaults for the normal message communication in the S3I:
/// - brokerBaseUrl = 'https://broker.s3i.vswf.dev/'
/// - maxMessagesPerInterval = 10,
/// - pollingInterval = Duration(seconds: 1)
ActiveBrokerInterface getActiveBrokerDefaultConnector(
    AuthenticationManager authManager,
    {Map<String, dynamic> args = const <String, dynamic>{}}) {
  final String brokerBaseUrl =
      args['brokerBaseUrl'] as String? ?? 'https://broker.s3i.vswf.dev/';
  final int maxMessagesPerInterval =
      args['maxMessagesPerInterval'] as int? ?? 10;
  final Duration pollingInterval =
      args['pollingInterval'] as Duration? ?? const Duration(seconds: 1);
  return BrokerRestConnector(authManager,
      brokerBaseUrl: brokerBaseUrl,
      maxMessagesPerInterval: maxMessagesPerInterval,
      pollingInterval: pollingInterval);
}

/// Creates a new [BrokerRestConnector] configured to be used for the
/// Event System.
///
/// See [getActiveBrokerDefaultConnector] for more information.
ActiveBrokerInterface getActiveBrokerEventConnector(
    AuthenticationManager authManager,
    {Map<String, dynamic> args = const <String, dynamic>{}}) {
  throw UnimplementedError('WEB is currently unsupported');
}

/// This [ActiveBrokerInterface] implementation uses the S3I-Broker REST API
/// to send and receive messages.
///
/// Currently SSE (ServerSideEvents) aren't supported by the API so this class
/// polls at the endpoint.
///
/// See https://broker.s3i.vswf.dev/apidoc/#/ for detailed information.
class BrokerRestConnector extends ActiveBrokerInterface {
  /// Creates a [BrokerRestConnector] which polls for a new message every
  /// [pollingInterval].
  BrokerRestConnector(AuthenticationManager authManager,
      {required this.brokerBaseUrl,
      required this.maxMessagesPerInterval,
      required this.pollingInterval})
      : super(authManager);

  /// The base url of the REST-API.
  final String brokerBaseUrl;

  /// The time between two request to the REST-API for new messages.
  ///
  /// Default value is 1 second. The first [startConsuming] is the starting
  /// point and the last [stopConsuming] resets it. If the polling takes longer
  /// than this duration the next poll cycle is started immediately.
  final Duration pollingInterval;

  /// The maximal amount of received messages for each endpoint in one
  /// polling interval.
  final int maxMessagesPerInterval;

  /// Determines if the polling loop should keep going or exits.
  bool _enablePolling = false;

  /// All endpoints which are polled.
  final Set<String> _endpoints = <String>{};

  @override
  void sendMessage(Message message, Set<String> endpoints) {
    _sendMessageToEndpoints(message, endpoints);
  }

  @override
  Future<void> startConsuming(String endpoint) async {
    _endpoints.add(endpoint);
    if (!_enablePolling) _startPolling();
  }

  @override
  void stopConsuming(String endpoint) {
    _endpoints.remove(endpoint);
    if (_endpoints.isEmpty) _enablePolling = false;
  }

  /// Starts the polling loop which runs until [_enablePolling] is false.
  Future<void> _startPolling() async {
    _enablePolling = true;
    DateTime lastRunTime = DateTime.now();
    while (true) {
      if (!_enablePolling) return;
      final Duration pollWait =
          lastRunTime.add(pollingInterval).difference(DateTime.now());
      lastRunTime = DateTime.now();
      await Future<void>.delayed(pollWait);
      await _getMessagesForAllEndpoints();
    }
  }

  /// Requests all endpoints and receives the messages for them
  Future<void> _getMessagesForAllEndpoints() async {
    try {
      final AccessToken token = await authManager.getAccessToken();
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.originalToken}'
      };
      for (final String end in _endpoints) {
        try {
          await _getMessages(end, headers);
        } on Exception catch (e) {
          notifyConsumingFailed(end, e);
        }
      }
    } on Exception catch (e) {
      for (final String end in _endpoints) {
        notifyConsumingFailed(end, e);
      }
    } on Error catch (e) {
      for (final String end in _endpoints) {
        notifyConsumingFailed(end, S3IException(e.stackTrace.toString()));
      }
    }
  }

  /// Receives the messages from the endpoint, respects
  /// [maxMessagesPerInterval].
  Future<void> _getMessages(
      String endpoint, Map<String, String> authHeader) async {
    for (int i = 0; i < maxMessagesPerInterval; i++) {
      final Response response = await Client()
          .get(Uri.parse(brokerBaseUrl + endpoint), headers: authHeader);
      if (response.statusCode != 200) throw NetworkResponseException(response);
      if (response.body.isEmpty) break; // no messages available
      newMessageReceived(utf8.decode(response.bodyBytes));
    }
  }

  Future<void> _sendMessageToEndpoints(
      Message message, Iterable<String> targetEndpoints) async {
    try {
      final AccessToken token = await authManager.getAccessToken();
      final Map<String, String> headers = <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token.originalToken}'
      };
      final Response response = await Client().post(
          Uri.parse(brokerBaseUrl + targetEndpoints.join(',')),
          headers: headers,
          body: utf8.encode(jsonEncode(message.toJson())));
      if (response.statusCode != 201) throw NetworkResponseException(response);
    } on Exception catch (e) {
      notifySendMessageFailed(message, e);
    }
  }
}
