import 'dart:convert';

import 'package:http/http.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:s3i_flutter/src/auth/authentication_manager.dart';
import 'package:s3i_flutter/src/utils/json_key.dart';

class S3ICore {
  final AuthenticationManager authManager;
  final String directoryUrl;
  late Client _directoryClient;

  S3ICore(this.authManager,
      {this.directoryUrl = "https://dir.s3i.vswf.dev/api/2"}) {
    _directoryClient = Client();
  }

  Future<AccessToken> login() async {
    return authManager.getAccessToken();
  }

  Future<bool> logout() async {
    return authManager.logout();
  }

  //directory

  /// Generates an authorized `GET` to the S3I-Directory.
  ///
  /// The [path] should starts with a `/`.
  /// For more information see `https://dir.s3i.vswf.dev/apidoc/#`.
  /// Could throw everything [getAccessToken] throws.
  Future<Response> getDirectory(String path,
      {Map<String, String> additionalHeaderFields = const {}}) async {
    final token = await authManager.getAccessToken();
    var headers = {"Content-Type": "application/json"};
    headers.addAll({"Authorization": "Bearer " + token.originalToken});
    headers.addAll(additionalHeaderFields);
    return _directoryClient.get(Uri.parse(directoryUrl + path),
        headers: headers);
  }

  /// Generates an authorized `PUT` to the S3I-Directory.
  ///
  /// The [path] should starts with a `/`.
  /// For more information see `https://dir.s3i.vswf.dev/apidoc/#`.
  /// Could throw everything [getAccessToken] throws.
  Future<Response> putDirectory(String path,
      {Map<String, String> additionalHeaderFields = const {},
      required Map<String, dynamic> jsonBody}) async {
    final token = await authManager.getAccessToken();
    var headers = {"Content-Type": "application/json"};
    headers.addAll({"Authorization": "Bearer " + token.originalToken});
    headers.addAll(additionalHeaderFields);
    return _directoryClient.put(Uri.parse(directoryUrl + path),
        headers: headers, body: jsonEncode(jsonBody));
  }

  Future<Thing> getThing(String thingId, {FieldQuery? fields}) async {
    //if some fields are specified we need to add thingId to know from where the data comes
    if (fields != null) {
      if (fields.fields.isNotEmpty &&
          !fields.fields.contains(JsonKey.thingId)) {
        fields.fields.add(JsonKey.thingId);
      }
    }
    var response = await getDirectory(
        QueryAssembler.generatePath("/things/" + thingId, fieldQuery: fields));
    if (response.statusCode != 200) throw NetworkResponseException(response);
    return Thing.fromJson(jsonDecode(response.body));
  }

  Future<void> putThing(Thing thing) async {
    var response =
        await putDirectory("/things/" + thing.id, jsonBody: thing.toJson());
    if (response.statusCode != 204 && response.statusCode != 201) {
      throw NetworkResponseException(response);
    }
  }
}
