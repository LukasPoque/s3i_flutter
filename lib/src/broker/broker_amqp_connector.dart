import 'dart:convert';

import 'package:dart_amqp/dart_amqp.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/tokens.dart';
import 'package:s3i_flutter/src/broker/broker_interfaces.dart';
import 'package:s3i_flutter/src/broker/message.dart';
import 'package:s3i_flutter/src/exceptions/network_authentication_exception.dart';
import 'package:s3i_flutter/src/exceptions/s3i_exception.dart';

///Creates a new [BrokerAmqpConnector].
///
/// The instance is created with the [authManager] and the optional constructor
/// arguments in the [args] (the string-keys should match the name of the
/// parameters).
///
/// This is needed to use the same interface on web and other platforms.
ActiveBrokerInterface getBrokerDefaultConnector(
    AuthenticationManager authManager,
    {Map<String, dynamic> args = const <String, dynamic>{}}) {
  final String brokerHost =
      args['brokerHost'] as String? ?? 'rabbitmq.s3i.vswf.dev';
  final int port = args['port'] as int? ?? 5672;
  final String virtualHost = args['virtualHost'] as String? ?? 's3i';
  final int maxConnectionAttempts = args['maxConnectionAttempts'] as int? ?? 3;
  final Duration reconnectWaitTime = args['reconnectWaitTime'] as Duration? ??
      const Duration(milliseconds: 1500);
  final String exchangeName = args['exchangeName'] as String? ?? 'demo.direct';
  return BrokerAmqpConnector(authManager,
      brokerHost: brokerHost,
      port: port,
      virtualHost: virtualHost,
      maxConnectionAttempts: maxConnectionAttempts,
      reconnectWaitTime: reconnectWaitTime,
      exchangeName: exchangeName);
}

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

  bool _inBrokerConstruction = false;

  /// Starts the connection to the S3I-Broker.
  ///
  /// Returns an empty string if everything is ready or the error occurred
  /// during the connection as string.
  Future<String> connectToBroker() async {
    if (_keepAlive || _endpointConsumer.isNotEmpty) return 'already connected';
    _keepAlive = true;
    _inBrokerConstruction = true;
    final String createInfo = await _establishConnectionToBroker()
        .then((_) => '')
        .catchError((Object e) => e.toString())
        .whenComplete(() {
      _inBrokerConstruction = false;
    });
    return createInfo;
  }

  /// Disconnects from the S3I-Broker.
  ///
  /// If the application doesn't need the broker, please consider disconnect
  /// from the broker. This cleans all consuming endpoints.
  Future<void> disconnectFromBroker() async {
    _keepAlive = false;
    _inBrokerConstruction = false;
    await _stopListeningToEndpoints(_endpointConsumer.keys);
    _endpointConsumer.clear();
    await _resetConnectionToBroker();
  }

  ///Publishes the given [message] to all [endpoints].
  ///
  /// The endpoints should be in the correct format (s3ib://s3i:+ UUIDv4 for
  /// decrypted communication or s3ibs://s3i: + UUIDv4 for encrypted messages).
  ///
  /// Connects to the Broker if there is no connection open at the time.
  @override
  Future<void> sendMessage(Message message, Set<String> endpoints) async {
    if (_amqpClient == null || _channel == null || _exchange == null) {
      if (_inBrokerConstruction) {
        notifySendMessageFailed(message, S3IException('invalid broker state'));
        return;
      } else {
        final String creationInfo = await connectToBroker();
        if (creationInfo.isNotEmpty) {
          notifySendMessageFailed(message, S3IException(creationInfo));
          return;
        }
      }
    }
    for (final String edp in endpoints) {
      try {
        _exchange!.publish(jsonEncode(message.toJson()), edp);
        notifySendMessageSucceeded(message);
      } on ChannelException catch (e) {
        notifySendMessageFailed(message, e);
      }
    }
  }

  ///Starts consuming on the [endpoint].
  ///
  /// The endpoints should be in the correct format (s3ib://s3i:+ UUIDv4 for
  /// decrypted communication or s3ibs://s3i: + UUIDv4 for encrypted messages).
  ///
  /// Connects to the Broker if there is no connection open at the time.
  @override
  Future<void> startConsuming(String endpoint) async {
    if (_amqpClient == null || _channel == null || _exchange == null) {
      if (_inBrokerConstruction) {
        notifyConsumingFailed(endpoint, S3IException('invalid broker state'));
        return;
      } else {
        final String creationInfo = await connectToBroker();
        if (creationInfo.isNotEmpty) {
          notifyConsumingFailed(endpoint, S3IException(creationInfo));
          return;
        }
      }
    }
    _connectToEndpoint(endpoint).catchError((Object e) {
      notifyConsumingFailed(endpoint, S3IException(e.toString()));
    });
  }

  /// Stops consuming on the [endpoint].
  ///
  /// The endpoints should be in the correct format (s3ib://s3i:+ UUIDv4 for
  /// decrypted communication or s3ibs://s3i: + UUIDv4 for encrypted messages).
  ///
  /// Disconnects from the Broker if no one is listening.
  @override
  Future<void> stopConsuming(String endpoint) async {
    await _stopListeningToEndpoint(endpoint);
    _endpointConsumer.remove(endpoint);
    if (_endpointConsumer.isEmpty) disconnectFromBroker();
  }

  /// Creates a new connection to the broker.
  ///
  /// sets _client, _exchange and _channel
  ///
  /// Throws a [NetworkResponseException] if no token could be received. Throws
  /// [S3IException] if an error occurs during the setup of the amqp part.
  /// See dart_amqp for more exceptions that could be thrown.
  ///
  /// Make sure to set [_inBrokerConstruction] before and after.
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
    _inBrokerConstruction = true;
    await _establishConnectionToBroker().whenComplete(() {
      _inBrokerConstruction = false;
    });
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
