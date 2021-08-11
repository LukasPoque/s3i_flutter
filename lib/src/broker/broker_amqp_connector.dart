import 'dart:convert';

import 'package:dart_amqp/dart_amqp.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/broker/broker_interfaces.dart';
import 'package:s3i_flutter/src/broker/message.dart';

/// This [ActiveBrokerInterface] implementation uses the native messaging
/// protocol of the S3I-Broker: AMQP.
///
/// For more information about AMQP see their
/// [specification](https://www.amqp.org/sites/amqp.org/files/amqp.pdf) or refer
/// to the documentation of the used
/// [dart_amqp package](https://pub.dev/packages/dart_amqp).
class BrokerAmqpConnector extends ActiveBrokerInterface {
  /// Creates a [BrokerAmqpConnector] which uses the [authManager] to receive
  /// tokens.
  ///
  /// Unless you know what you are doing, don't change the default values
  /// of the named parameters.
  BrokerAmqpConnector(AuthenticationManager authManager,
      {this.brokerHost = 'rabbitmq.s3i.vswf.dev',
      this.port = 5672,
      this.virtualHost = 's3i',
      this.maxConnectionAttempts = 3,
      this.reconnectWaitTime = const Duration(milliseconds: 1500),
      this.exchangeName = 'demo.direct'})
      : super(authManager);

  /// The host to connect to.
  final String brokerHost;

  /// The port of the amqp broker.
  final int port;

  /// The connection vhost that will be sent to the server.
  final String virtualHost;

  /// The max number of reconnection attempts.
  final int maxConnectionAttempts;

  /// The time between each reconnect attempt.
  final Duration reconnectWaitTime;

  /// The name of the amqp broker exchange.
  final String exchangeName;

  /// Stores all endpoints and their consumer queues.
  final Map<String, Consumer> _endpointConsumer = <String, Consumer>{};

  Client? _amqpClient;

  Channel? _channel;

  Exchange? _exchange;

  bool _keepAlive = false;

  /// Starts the connection to the S3I-Broker.
  ///
  /// Returns an empty string if everything is ready or the error occurred
  /// during the connection as string.
  Future<String> connectToBroker() async {
    if (_keepAlive || _endpointConsumer.isNotEmpty) return 'already connected';
    _keepAlive = true;
    return _establishConnectionToBroker()
        .then((_) => '')
        .catchError((Object e) => e.toString());
  }

  /// Disconnects from the S3I-Broker.
  ///
  /// If the application doesn't need the broker, please consider disconnect
  /// from the broker. This cleans all consuming endpoints.
  Future<void> disconnectFromBroker() async {
    _keepAlive = false;
    await _stopListeningToEndpoints(_endpointConsumer.keys);
    _endpointConsumer.clear();
    await _resetConnectionToBroker();
  }

  ///Publishes the given [message] to all [endpoints].
  ///
  /// The endpoints should be in the correct format (s3ib://s3i:+ UUIDv4 for
  /// decrypted communication or s3ibs://s3i: + UUIDv4 for encrypted messages).
  ///
  /// [connectToBroker] should be called first, otherwise a
  /// SendMessageFailed-Event is emitted.
  @override
  void sendMessage(Message message, Set<String> endpoints) {
    if (_amqpClient == null || _channel == null || _exchange == null) {
      notifySendMessageFailed(message, S3IException('invalid broker state'));
    } else {
      for (final String edp in endpoints) {
        try {
          _exchange!.publish(jsonEncode(message.toJson()), edp);
          notifySendMessageSucceeded(message);
        } on ChannelException catch (e) {
          notifySendMessageFailed(message, e);
        }
      }
    }
  }

  ///Starts consuming on the [endpoint].
  ///
  /// The endpoints should be in the correct format (s3ib://s3i:+ UUIDv4 for
  /// decrypted communication or s3ibs://s3i: + UUIDv4 for encrypted messages).
  ///
  /// [connectToBroker] should be called first, otherwise a
  /// ConsumingFailed-Event is emitted.
  @override
  void startConsuming(String endpoint) {
    if (_amqpClient == null || _channel == null || _exchange == null) {
      notifyConsumingFailed(endpoint, S3IException('invalid broker state'));
    } else {
      _connectToEndpoint(endpoint).catchError((Object e) {
        notifyConsumingFailed(endpoint, S3IException(e.toString()));
      });
    }
  }

  @override
  Future<void> stopConsuming(String endpoint) async {
    await _stopListeningToEndpoint(endpoint);
    _endpointConsumer.remove(endpoint);
  }

  /// Creates a new connection to the broker.
  ///
  /// sets _client, _exchange and _channel
  ///
  /// Throws a [NetworkResponseException] if no token could be received. Throws
  /// [S3IException] if an error occurs during the setup of the amqp part.
  /// See dart_amqp for more exceptions that could be thrown.
  Future<void> _establishConnectionToBroker() async {
    _resetConnectionToBroker();
    AccessToken token;
    try {
      token = await authManager.getAccessToken();
      // trigger keep alive
      if (_keepAlive) _keepConnectionAlive(token);
    } on Exception catch (e) {
      throw NetworkAuthenticationException(e);
    }
    final ConnectionSettings setting = ConnectionSettings(
        host: brokerHost,
        port: port,
        virtualHost: virtualHost,
        authProvider: PlainAuthenticator(' ', token.originalToken),
        maxConnectionAttempts: maxConnectionAttempts,
        reconnectWaitTime: reconnectWaitTime);
    _amqpClient = Client(settings: setting);
    if (_amqpClient == null) throw S3IException('amqp client is null');
    try {
      _channel = await _amqpClient!.channel();
      _exchange = await _channel!
          .exchange(exchangeName, ExchangeType.DIRECT, passive: true);
    } on Exception catch (e) {
      throw S3IException('amqp package error: $e');
    }
  }

  /// Closes the connection and sets _client, _exchange and _channel to null.
  Future<void> _resetConnectionToBroker() async {
    if (_amqpClient != null) {
      await _amqpClient!.close();
    }
    _amqpClient = null;
    _channel = null;
    _exchange = null;
  }

  /// Should only be called when _client, _channel, _exchange != null.
  ///
  /// Connects to the endpoint and adds the consumer to the map.
  Future<void> _connectToEndpoint(String endpoint,
      {bool passive = true, bool durable = true}) async {
    if (_amqpClient == null || _channel == null || _exchange == null) return;
    final Queue receiveQueue =
        await _channel!.queue(endpoint, passive: passive, durable: durable);
    final Consumer consume = await receiveQueue.consume();
    consume.listen((AmqpMessage event) {
      newMessageReceived(event.payloadAsString);
    });
    _endpointConsumer[endpoint] = consume;
  }

  /// Cancels all consumers at [endpoints].
  Future<void> _stopListeningToEndpoints(Iterable<String> endpoints) async {
    for (final String end in endpoints) {
      await _stopListeningToEndpoint(end);
    }
  }

  /// Cancels the consumer at [endpoint].
  Future<void> _stopListeningToEndpoint(String endpoint) async {
    if (_endpointConsumer.containsKey(endpoint)) {
      final Consumer consumer = _endpointConsumer[endpoint]!;
      await consumer.cancel();
    }
  }

  /// Closes all connections/subscriptions to the broker and reestablish them
  /// afterwards.
  Future<void> _reestablishConnection() async {
    final Set<String> oldSubEndpoints = _endpointConsumer.keys.toSet();
    await _stopListeningToEndpoints(oldSubEndpoints);
    _endpointConsumer.clear();
    await _resetConnectionToBroker();
    //rebuild all old connections
    await _establishConnectionToBroker();
    for (final String end in oldSubEndpoints) {
      await _connectToEndpoint(end).catchError((Object e) {
        notifyConsumingFailed(end, S3IException(e.toString()));
      });
    }
  }

  /// Checks the expiration time of the token and reconnects to the Broker
  /// when it's expired.
  Future<void> _keepConnectionAlive(AccessToken token) async {
    Future<void>.delayed(token.timeTillExpiration()).then((dynamic _) {
      if (_keepAlive) _reestablishConnection();
    });
  }
}
