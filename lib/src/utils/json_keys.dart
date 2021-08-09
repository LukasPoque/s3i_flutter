// TODO(poq): add more documentation

/// Stores universal string keys constants for Ditto.
class DittoKeys {
  ///thingId
  static const String thingId = 'thingId';

  ///policyId
  static const String policyId = 'policyId';

  ///attributes
  static const String attributes = 'attributes';

  ///items
  static const String items = 'items';

  ///cursor
  static const String cursor = 'cursor';

  ///type
  static const String type = 'type';

  ///expiry
  static const String expiry = 'expiry';

  ///grant
  static const String grant = 'grant';

  ///revoke
  static const String revoke = 'revoke';

  ///subjects
  static const String subjects = 'subjects';

  ///resources
  static const String resources = 'resources';

  ///entries
  static const String entries = 'entries';
}

/// Stores universal string keys constants for the S3I-IdentityProvider.
class KeycloakKeys {
  ///grant_type
  static const String grantType = 'grant_type';

  ///client_id
  static const String clientId = 'client_id';

  ///client_secret
  static const String clientSecret = 'client_secret';

  ///access_token
  static const String accessToken = 'access_token';

  ///refresh_token
  static const String refreshToken = 'refresh_token';
}

/// Stores universal string keys constants for the data model of the
/// S3I-Directory.
class DirectoryKeys {
  ///name
  static const String name = 'name';

  ///type
  static const String thingType = 'type';

  ///dataModel
  static const String dataModel = 'dataModel';

  ///publicKey
  static const String publicKey = 'publicKey';

  ///allEndpoints
  static const String allEndpoints = 'allEndpoints';

  ///defaultEndpoint
  static const String defaultEndpoint = 'defaultEndpoint';

  ///defaultHMI
  static const String defaultHMI = 'defaultHMI';

  ///location
  static const String location = 'location';

  ///latitude
  static const String latitude = 'latitude';

  ///longitude
  static const String longitude = 'longitude';

  ///ownedBy
  static const String ownedBy = 'ownedBy';

  ///administratedBy
  static const String administratedBy = 'administratedBy';

  ///usedBy
  static const String usedBy = 'usedBy';

  ///represents
  static const String represents = 'represents';

  ///thingStructure
  static const String thingStructure = 'thingStructure';

  ///class
  static const String classString = 'class';

  ///links
  static const String links = 'links';

  ///identifier
  static const String identifier = 'identifier';

  ///values
  static const String values = 'values';

  ///association
  static const String association = 'association';

  ///target
  static const String target = 'target';

  ///attribute
  static const String attribute = 'attribute';

  ///value
  static const String value = 'value';
}

/// Stores universal string keys constants for the S3I-B protocol.
class BrokerKeys {
  ///identifier
  static const String identifier = 'identifier';

  ///messageType
  static const String messageType = 'messageType';

  //start messageTypes-------------------------------

  ///userMessage
  static const String userMessage = 'userMessage';

  ///serviceRequest
  static const String serviceRequest = 'serviceRequest';

  ///serviceReply
  static const String serviceReply = 'serviceReply';

  ///getValueRequest
  static const String getValueRequest = 'getValueRequest';

  ///getValueReply
  static const String getValueReply = 'getValueReply';

  ///setValueRequest
  static const String setValueRequest = 'setValueRequest';

  ///setValueReply
  static const String setValueReply = 'setValueReply';

  ///deleteAttributeRequest
  static const String deleteAttributeRequest = 'deleteAttributeRequest';

  ///deleteAttributeReply
  static const String deleteAttributeReply = 'deleteAttributeReply';

  ///createAttributeRequest
  static const String createAttributeRequest = 'createAttributeRequest';

  ///createAttributeReply
  static const String createAttributeReply = 'createAttributeReply';

  //end messageTypes---------------------------------

  ///receivers
  static const String receivers = 'receivers';

  ///replyingToMessage
  static const String replyingToMessage = 'replyingToMessage';

  ///replyToEndpoint
  static const String replyToEndpoint = 'replyToEndpoint';

  ///sender
  static const String sender = 'sender';

  ///attachments
  static const String attachments = 'attachments';

  ///subject
  static const String subject = 'subject';

  ///text
  static const String text = 'text';

  ///data
  static const String data = 'data';

  ///filename
  static const String filename = 'filename';

  ///serviceType
  static const String serviceType = 'serviceType';

  ///parameters
  static const String parameters = 'parameters';

  ///results
  static const String results = 'results';

  ///attributePath
  static const String attributePath = 'attributePath';

  ///newValue
  static const String newValue = 'newValue';

  ///value
  static const String value = 'value';

  ///ok
  static const String ok = 'ok';
}
