import 'dart:convert';

import 'package:http/http.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/auth/keycloak_client_representation.dart';
import 'package:s3i_flutter/src/exceptions/network_authentication_exception.dart';
import 'package:s3i_flutter/src/exceptions/response_parsing_exception.dart';
import 'package:s3i_flutter/src/utils/json_keys.dart';

/// The main communication class to the S3I.
///
/// The [S3ICore] provides access to functions to receive and put the different
/// datatype like [Thing] and [PolicyEntry] from/to the directory. (This is
/// subject of change because maybe there will be a directory communicator)
///
/// Secondly it provides functions to communicate with the S3I-Config API.
///
/// Furthermore it provides access to the Broker and Repository classes.
class S3ICore {
  /// Creates a new instance of [S3ICore].
  ///
  /// The [authManager] needs to be correctly setup and if you wish to connect
  /// to a different address of the S3I-Directory you could specify this in
  /// the [directoryUrl]. Use [configApiUrl] to specify an other endpoint
  /// for the Config-API.
  ///
  /// Could throw a [UnsupportedError] if no platform appropriate client
  /// could be created.
  S3ICore(this.authManager,
      {this.directoryUrl = 'https://dir.s3i.vswf.dev/api/2',
      this.configApiUrl = 'https://config.s3i.vswf.dev/'});

  /// The authentication manager used by this instance to get
  /// valid access tokens.
  final AuthenticationManager authManager;

  /// The address which is used for all requests to the directory.
  final String directoryUrl;

  /// The address which is used for all request to the Config-API.
  final String configApiUrl;

  /// Returns a valid [AccessToken] form the [authManager].
  ///
  /// Could throw everything the implementation of
  /// [AuthenticationManager.getAccessToken] could throw.
  Future<AccessToken> login() async {
    return authManager.getAccessToken();
  }

  /// Returns a valid [AccessToken] form the [authManager].
  ///
  /// Could throw everything the implementation of
  /// [AuthenticationManager.getAccessToken] could throw.
  Future<bool> logout() async {
    return authManager.logout();
  }

  //config api --------------------

  /// Generates an authorized `POST` to the Config-API.
  ///
  /// The [path] should starts with a `/` and the [jsonBody] should be a valid
  /// json. For more information see `https://config.s3i.vswf.dev/apidoc/#/`.
  /// If you need to add additional information to the header,
  /// use [additionalHeaderFields].
  ///
  /// Throws a [FormatException] if the [path] could not be parsed to a
  /// valid [Uri]. Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] throws an exception. If there is no
  /// internet connection available a [SocketException] is thrown.
  Future<Response> postConfig(String path,
      {Map<String, String> additionalHeaderFields = const <String, String>{},
      required Map<String, dynamic> jsonBody}) async {
    String originalToken = '';
    try {
      final AccessToken token = await authManager.getAccessToken();
      originalToken = token.originalToken;
    } on Exception catch (e) {
      throw NetworkAuthenticationException(e);
    }
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json'
    }
      ..addAll(<String, String>{'Authorization': 'Bearer $originalToken'})
      ..addAll(additionalHeaderFields);
    return Client().post(Uri.parse(configApiUrl + path),
        headers: headers, body: utf8.encode(jsonEncode(jsonBody)));
  }

  /// Generates an authorized `DELETE` to the Config-API.
  ///
  /// The [path] should starts with a `/`. For more information see
  /// `https://config.s3i.vswf.dev/apidoc/#/`.
  /// If you need to add additional information to the header,
  /// use [additionalHeaderFields].
  ///
  /// Throws a [FormatException] if the [path] could not be parsed to a
  /// valid [Uri]. Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] throws an exception. If there is no
  /// internet connection available a [SocketException] is thrown.
  Future<Response> deleteConfig(String path,
      {Map<String, String> additionalHeaderFields =
          const <String, String>{}}) async {
    String originalToken = '';
    try {
      final AccessToken token = await authManager.getAccessToken();
      originalToken = token.originalToken;
    } on Exception catch (e) {
      throw NetworkAuthenticationException(e);
    }
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json'
    }
      ..addAll(<String, String>{'Authorization': 'Bearer $originalToken'})
      ..addAll(additionalHeaderFields);
    return Client().delete(Uri.parse(configApiUrl + path), headers: headers);
  }

  /// Creates a new thing in the S3I with the current user as owner.
  ///
  /// Returns the id and the secret of the new created thing. See
  /// https://config.s3i.vswf.dev/apidoc/#/Things/post_things_ for more
  /// information.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 201. Throws
  /// a [ResponseParsingException] if something went wrong during the parsing
  /// to an [Endpoint].
  Future<ClientIdentity> createNewThing(
      {KeycloakClientRepresentation? fullClient}) async {
    fullClient ??= KeycloakClientRepresentation();
    final Response response =
        await postConfig('/things/', jsonBody: fullClient.toJson());
    if (response.statusCode != 201) throw NetworkResponseException(response);
    try {
      return ClientIdentity.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on InvalidJsonSchemaException catch (e) {
      throw ResponseParsingException(e);
    } on TypeError catch (e) {
      throw ResponseParsingException(S3IException(e.stackTrace.toString()));
    }
  }

  /// Delete the thing in the whole S3I, including directory, repository,
  /// identity provider and the broker.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 204.
  Future<void> deleteThing(String thingId) async {
    final Response response = await deleteConfig('/things/$thingId');
    if (response.statusCode != 204) throw NetworkResponseException(response);
  }

  /// Creates a new endpoint (queue with the matching binding) in the
  /// S3I-Broker.
  ///
  /// Use [encrypted] to specify if the endpoint should indicate that decrypted
  /// messages are expected.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 201. Throws
  /// a [ResponseParsingException] if something went wrong during the parsing
  /// to an [Endpoint].
  Future<Endpoint> createBrokerEndpoint(String thingId,
      {bool encrypted = false}) async {
    final Response response = await postConfig('/things/$thingId/broker',
        jsonBody: <String, bool>{'encrypted': encrypted});
    if (response.statusCode != 201) throw NetworkResponseException(response);
    try {
      return Endpoint((jsonDecode(response.body)
          as Map<String, dynamic>)['queue_name'] as String);
    } on TypeError catch (e) {
      throw ResponseParsingException(
          InvalidJsonSchemaException(e.stackTrace.toString(), response.body));
    }
  }

  /// Removes an endpoint (queue with the matching binding) from the
  /// S3I-Broker.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 204.
  Future<void> removeBrokerEndpoint(String thingId) async {
    final Response response = await deleteConfig('/things/$thingId/broker');
    if (response.statusCode != 204) throw NetworkResponseException(response);
  }

  /// Creates a new queue binding to the `eventExchange` in the
  /// S3I-Broker.
  ///
  /// Use [topic] to specify on which AMQP message topic the queue should be
  /// bound. Use the optional parameter [queueLength] (> 0) if you need a
  /// specific queue length.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 201. Throws
  /// a [ResponseParsingException] if something went wrong during the parsing
  /// to an [Endpoint].
  Future<Endpoint> createEventQueueBinding(String thingId, String topic,
      {int queueLength = 0}) async {
    final Map<String, dynamic> requestBody = <String, dynamic>{'topic': topic};
    if (queueLength > 0) {
      requestBody['queue_length'] = queueLength;
    }
    final Response response = await postConfig('/things/$thingId/broker/event',
        jsonBody: requestBody);
    if (response.statusCode != 201) throw NetworkResponseException(response);
    try {
      return Endpoint((jsonDecode(response.body)
          as Map<String, dynamic>)['queue_name'] as String);
    } on TypeError catch (e) {
      throw ResponseParsingException(
          InvalidJsonSchemaException(e.stackTrace.toString(), response.body));
    }
  }

  /// Removes the event endpoint from the S3I-Broker.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 204.
  Future<void> removeEventQueue(String thingId) async {
    final Response response =
        await deleteConfig('/things/$thingId/broker/event');
    if (response.statusCode != 204) throw NetworkResponseException(response);
  }

  //directory --------------------

  /// Generates an authorized `GET` to the S3I-Directory.
  ///
  /// The [path] should starts with a `/`. For more information
  /// see `https://dir.s3i.vswf.dev/apidoc/#`. If you need to add additional
  /// information to the header (e.g. ETag), use [additionalHeaderFields].
  ///
  /// Throws a [FormatException] if the [path] could not be parsed to a
  /// valid [Uri]. Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] throws an exception. If there is no
  /// internet connection available a [SocketException] is thrown.
  Future<Response> getDirectory(String path,
      {Map<String, String> additionalHeaderFields =
          const <String, String>{}}) async {
    String originalToken = '';
    try {
      final AccessToken token = await authManager.getAccessToken();
      originalToken = token.originalToken;
    } on Exception catch (e) {
      throw NetworkAuthenticationException(e);
    }
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json'
    }
      ..addAll(<String, String>{'Authorization': 'Bearer $originalToken'})
      ..addAll(additionalHeaderFields);
    return Client().get(Uri.parse(directoryUrl + path), headers: headers);
  }

  /// Generates an authorized `PUT` to the S3I-Directory.
  ///
  /// The [path] should starts with a `/` and the [jsonBody] should be a valid
  /// ditto entry. For more information see `https://dir.s3i.vswf.dev/apidoc/#`.
  /// If you need to add additional information to the header (e.g. ETag),
  /// use [additionalHeaderFields].
  ///
  /// Throws a [FormatException] if the [path] could not be parsed to a
  /// valid [Uri]. Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] throws an exception. If there is no
  /// internet connection available a [SocketException] is thrown.
  Future<Response> putDirectory(String path,
      {Map<String, String> additionalHeaderFields = const <String, String>{},
      required Map<String, dynamic> jsonBody}) async {
    String originalToken = '';
    try {
      final AccessToken token = await authManager.getAccessToken();
      originalToken = token.originalToken;
    } on Exception catch (e) {
      throw NetworkAuthenticationException(e);
    }
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json'
    }
      ..addAll(<String, String>{'Authorization': 'Bearer $originalToken'})
      ..addAll(additionalHeaderFields);
    return Client().put(Uri.parse(directoryUrl + path),
        headers: headers, body: utf8.encode(jsonEncode(jsonBody)));
  }

  /// Requests a directory thing entry (matching the [thingId]) from the
  /// S3I-Directory.
  ///
  /// Specify [fields] if only a subset of thing information is
  /// required. See [FieldQuery] for more information.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 200. Throws
  /// a [ResponseParsingException] if something went wrong during the parsing
  /// to the directory objects.
  Future<Thing> getThing(String thingId, {FieldQuery? fields}) async {
    //if some fields are specified we need to add thingId
    //to create a valid thing
    if (fields != null) {
      if (fields.fields.isNotEmpty &&
          !fields.fields.contains(DittoKeys.thingId)) {
        fields.fields.add(DittoKeys.thingId);
      }
    }
    final Response response = await getDirectory(
        assembleQuery('/things/$thingId', fieldQuery: fields));
    if (response.statusCode != 200) throw NetworkResponseException(response);
    try {
      return Thing.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on InvalidJsonSchemaException catch (e) {
      throw ResponseParsingException(e);
    } on TypeError catch (e) {
      throw ResponseParsingException(
          InvalidJsonSchemaException(e.stackTrace.toString(), response.body));
    }
  }

  /// Puts a directory thing entry to the S3I-Directory.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 204 or 201.
  Future<void> putThing(Thing thing) async {
    final Response response =
        await putDirectory('/things/${thing.id}', jsonBody: thing.toJson());
    if (response.statusCode != 204 && response.statusCode != 201) {
      throw NetworkResponseException(response);
    }
  }

  /// Requests a policy entry (matching the [policyId]) from the
  /// S3I-Directory.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 200. Throws
  /// a [ResponseParsingException] if something went wrong during the parsing
  /// to the directory objects.
  Future<PolicyEntry> getPolicy(String policyId) async {
    final Response response = await getDirectory('/policies/$policyId');
    if (response.statusCode != 200) throw NetworkResponseException(response);
    try {
      return PolicyEntry.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    } on FormatException catch (e) {
      throw ResponseParsingException(e);
    } on InvalidJsonSchemaException catch (e) {
      throw ResponseParsingException(e);
    } on TypeError catch (e) {
      throw ResponseParsingException(
          InvalidJsonSchemaException(e.stackTrace.toString(), response.body));
    }
  }

  /// Puts a policy entry to the S3I-Directory.
  ///
  /// Throws a [NetworkAuthenticationException] if
  /// [AuthenticationManager.getAccessToken] fails. Throws a [SocketException]
  /// if no internet connection is available. Throws a
  /// [NetworkResponseException] if the received status code is not 204 or 201.
  Future<void> putPolicy(PolicyEntry policy) async {
    final Response response =
        await putDirectory('/policies/${policy.id}', jsonBody: policy.toJson());
    if (response.statusCode != 204 && response.statusCode != 201) {
      throw NetworkResponseException(response);
    }
  }
}
