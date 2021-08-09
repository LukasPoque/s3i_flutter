import 'package:dart_amqp/dart_amqp.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/broker/broker_interfaces.dart';
import 'package:s3i_flutter/src/broker/message.dart';

///
class BrokerAmqpConnector extends ActiveBrokerInterface {
  ///
  BrokerAmqpConnector(AuthenticationManager authManager) : super(authManager);

  @override
  void sendMessage(Message message, Set<String> endpoints) {
    final ConnectionSettings setting = ConnectionSettings(
      host: 'rabbitmq.s3i.vswf.dev',
      virtualHost: 's3i',
      authProvider: const PlainAuthenticator(' ', ''),
      maxConnectionAttempts: 3,
    );
    // TODO(poq): implement sendMessage
  }

  @override
  void startConsuming(String endpoint) {
    // TODO(poq): implement startConsuming
  }

  @override
  void stopConsuming(String endpoint) {
    // TODO(poq): implement stopConsuming
  }
}
