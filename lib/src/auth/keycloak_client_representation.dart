import 'package:s3i_flutter/src/json_serializable_object.dart';

/// Represents a client in the S3I-IdentityProvider (Keycloak).
///
/// See the [documentation](https://www.keycloak.org/docs-api/5.0/rest-api/index.html#_clientrepresentation)
/// for more specific information about the representation.
class KeycloakClientRepresentation extends JsonSerializableObject {
  /// Creates a new [KeycloakClientRepresentation] with the optional parameters.
  KeycloakClientRepresentation({
    //this.access,
    //this.adminUrl,
    //this.attributes,
    //this.authenticationFlowBindingOverrides,
    //this.authorizationServicesEnabled,
    //this.authorizationSettings,
    //this.baseUrl,
    //this.bearerOnly,
    //this.clientAuthenticatorType,
    //this.clientId,
    //this.consentRequired,
    //this.defaultClientScopes,
    //this.defaultRoles,
    //this.description,
    //this.directAccessGrantsEnabled,
    //this.enabled,
    //this.frontChannelLogout,
    //this.fullScopeAllowed,
    //this.id,
    //this.implicitFlowEnabled,
    //this.name,
    //this.nodeReRegistrationTimeout,
    //this.notBefore,
    //this.clientScopes,
    //this.origin,
    this.optionalClientScopes,
    //this.protocol,
    //this.protocolMappers,
    //this.publicClient,
    this.redirectUris,
    //this.registeredNodes,
    //this.registrationAccessToken,
    //this.rootUrl,
    //this.secret,
    //this.serviceAccountsEnabled,
    //this.standardFlowEnabled,
    //this.surrogateAuthRequired,
    //this.webOrigins
  });

  // TODO(poq): activate all members

  //Map<String, String>? access;
  //String? adminUrl;
  //Map<String, String>? attributes;
  //Map<String, String>? authenticationFlowBindingOverrides;
  //bool? authorizationServicesEnabled;
  //ResourceServerRepresentation? authorizationSettings;
  //String? baseUrl;
  //bool? bearerOnly;
  //String? clientAuthenticatorType;
  //String? clientId;
  //bool? consentRequired;
  //List<String>? defaultClientScopes;
  //List<String>? defaultRoles;
  //String? description;
  //bool? directAccessGrantsEnabled;
  //bool? enabled;
  //bool? frontChannelLogout;
  //bool? fullScopeAllowed;
  //String? id;
  //bool? implicitFlowEnabled;
  //String? name;
  //int? nodeReRegistrationTimeout;
  //int? notBefore;
  //List<String>? clientScopes;
  //String? origin;

  /// The optional client scopes of a client.
  ///
  /// Often used scopes:
  /// - group
  /// - offline_access
  List<String>? optionalClientScopes;

  //String? protocol;
  //List<ProtocolMapperRepresentation>? protocolMappers;
  //bool? publicClient;

  /// The redirect urls this client could use after authentication.
  ///
  /// Could be e.g. `https://auth.s3i.vswf.dev/*` to use the S3I-AuthProxy.
  List<String>? redirectUris;

  //Map<String, String>? registeredNodes;
  //String? registrationAccessToken;
  //String? rootUrl;
  //String? secret;
  //bool? serviceAccountsEnabled;
  //bool? standardFlowEnabled;
  //bool? surrogateAuthRequired;
  //List<String>? webOrigins;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> newJson = <String, dynamic>{};
    if (optionalClientScopes != null)
      newJson['optionalClientScopes'] = optionalClientScopes;
    if (redirectUris != null) newJson['redirectUris'] = redirectUris;
    return newJson;
  }
}

/// See the [keycloak documentation]
/// (https://www.keycloak.org/docs-api/5.0/rest-api/index.html#_clientrepresentation)
class ResourceServerRepresentation {
  // TODO(poq): implement
}

/// See the [keycloak documentation]
/// (https://www.keycloak.org/docs-api/5.0/rest-api/index.html#_clientrepresentation)
class ProtocolMapperRepresentation {
  // TODO(poq): implement
}
