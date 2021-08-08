import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/exceptions/network_authentication_exception.dart';
import 'package:s3i_flutter/src/exceptions/response_parsing_exception.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

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
  /// the [directoryUrl].
  ///
  /// Could throw a [UnsupportedError] if no platform appropriate client
  /// could be created.
  S3ICore(this.authManager,
      {this.directoryUrl = 'https://dir.s3i.vswf.dev/api/2'}) {
    _directoryClient = Client();
  }

  /// The authentication manager used by this instance to get
  /// valid access tokens.
  final AuthenticationManager authManager;

  /// The address which is used for all requests to the directory.
  final String directoryUrl;

  /// The http client which is used for all request to the directory.
  late Client _directoryClient; // TODO(poq): when to close?

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
    return _directoryClient.get(Uri.parse(directoryUrl + path),
        headers: headers);
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
    return _directoryClient.put(Uri.parse(directoryUrl + path),
        headers: headers, body: jsonEncode(jsonBody));
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
          !fields.fields.contains(JsonKey.thingId)) {
        fields.fields.add(JsonKey.thingId);
      }
    }
    final Response response = await getDirectory(
        assembleQuery('/things/$thingId', fieldQuery: fields));
    if (response.statusCode != 200) throw NetworkResponseException(response);
    try {
      return Thing.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    } on InvalidJsonSchemaException catch (e) {
      throw ResponseParsingException(e);
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
          jsonDecode(response.body) as Map<String, dynamic>);
    } on FormatException catch (e) {
      throw ResponseParsingException(e);
    } on InvalidJsonSchemaException catch (e) {
      throw ResponseParsingException(e);
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
