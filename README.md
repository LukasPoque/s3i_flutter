<p align="center">
  <h1 align="center">S³I Flutter</h1>
</p>

<p align="center">
  <a href="https://github.com/LukasPoque/s3i_flutter/actions">
    <img src="https://img.shields.io/github/workflow/status/LukasPoque/s3i_flutter/Test%20Project?style=for-the-badge&label=tests&labelColor=333940&logo=github">
  </a>
  <a href="https://github.com/LukasPoque/s3i_flutter/issues">
    <img src="https://img.shields.io/github/issues/LukasPoque/s3i_flutter?style=for-the-badge&labelColor=333940&logo=AdGuard">
  </a>
  <a href="https://github.com/LukasPoque/s3i_flutter/blob/master/LICENSE">
    <img src="https://img.shields.io/github/license/LukasPoque/s3i_flutter?style=for-the-badge&color=%23007A88&labelColor=333940&logo=apache">
  </a>
  <a href="https://flutter.dev">
    <img src="https://img.shields.io/badge/made%20with-Flutter-51c3f8.svg?style=for-the-badge&labelColor=333940&logo=dart">
  </a>
</p>

<h3 align="center">A library that makes it easy to communicate with the S³I</h3>
<p align="center">
  <i>(Smart Systems Service Infrastructure of the Kompetenzzentrum Wald und Holz 4.0)</i>
</p>

<p align="center">
  <b>🚧 currently under construction 🚧</b>
</p>


## About S³I and KWH4.0

The S³I is a centralized infrastructure with currently five main services for the decentralized IoT of WH4.0 Things (Forestry4.0 Things) developed by the [KWH4.0](https://www.kwh40.de/).

If you are not familiar with the S³I concepts, please read the 
[KWH4.0-Standpunkt](https://www.kwh40.de/wp-content/uploads/2020/04/KWH40-Standpunkt-S3I-v2.0.pdf).

For further information see the [KWH Glossar](https://www.kwh40.de/glossar/) and the other [Standpunkte](https://www.kwh40.de/veroffentlichungen/).

## Contributing

PRs are always welcome, check [CONTRIBUTING.md](https://github.com/LukasPoque/s3i_flutter/blob/master/CONTRIBUTING.md) for more info.

## Installing

Please see [pub.dev](https://pub.dev/packages/s3i_flutter/install) for instructions how to install this package to your flutter app. 

If you like this package, consider supporting it by giving a star on [GitHub](https://github.com/LukasPoque/s3i_flutter) and 
a like on [pub.dev](https://pub.dev/packages/s3i_flutter) :heart:

## Features

The goal for `Version 1.0.0` is to cover the important endpoints of the main S³I components and provide useful data classes to wrap the JSON-data. For `Version 2.0.0` there should be more functionality to work with the data classes, especially with the (F)ML4.0 language.

#### Roadmap to Version 1.0.0

- Authentication
  - [x] Authenticate an user via the S3I-OAuthProxy
  - [x] Use an refresh/offline token for less user interaction during authentication
  - [ ] Enable saving the refresh/offline token for authentication after a restart or offline
  - [ ] Authenticate an user via default OpenId-Connect (with redirect url)

- Directory
  - [x] Provide basic PUT/GET/DELETE request methods
  - [x] Request a single thing (with filter options)
  - [x] Modify a single thing
  - [x] Request a policy entry
  - [x] Modify a policy entry
  - [ ] Query the directory via thing search
  - [ ] Find the owner of a thing
  - [ ] Find all things that belongs to a specific person
  - [ ] Create/delete a new thing in the S³I (adds a basic thing entry to the directory and creates a client in the identity provider)

- Repository
  - [ ] Provide basic PUT/GET/DELETE request methods
  - [ ] Request a single thing (with filter options)
  - [ ] Modify a single thing
  - [ ] Request a policy entry
  - [ ] Modify a policy entry
  - [ ] Query the repository via thing search
  - [ ] Create/delete a new thing entry in the repository
  - [ ] Receive live updates from the cloud copy of a thing
  - [ ] Send live updates to the cloud copy of a thing
  
- Messaging
  - [x] Create/delete a new broker queue (bound to the direct exchange)
  - [x] Receive/send messages using AMQP (not usable for web)
  - [x] Receive/sent messages using the REST endpoint of the S3I-Broker-API
  - [x] Work with UserMessages
  - [x] Work with ServiceMessages
  - [x] Work with GetValueMessages
  - [ ] Work with SetValueMessages
  - [ ] Work with DeleteAttributeMessages
  - [ ] Work with CreateAttributeMessages
  - [x] Work with messages from the EventSystem
  - [x] Create/delete broker queues for the EventSystem
  - [ ] Simple to use wrapper for the EventSystem


## Usage

For a basic example application see the [example](https://github.com/LukasPoque/s3i_flutter/tree/master/example).

Use the [documentation](https://pub.dev/documentation/s3i_flutter/latest/s3i_flutter/s3i_flutter-library.html) of this package for 
explicit information about every public method or class.

### Setup authentication

First you need to create a `ClientIdentity` used by your app. Please contact the [KWH4.0](https://www.kwh40.de/kontakt/) to get an app 
specific client. If you need special client settings like redirect urls (e.g. for the use of the S3I-OAuthProxy) please include this in your
request.
```dart
final clientIdentity = ClientIdentity(<CLIENT-ID>, <CLIENT-SECRET>);
```

Now you can pass this to an `AuthenticationManager` of your choice. 
See [here](https://github.com/LukasPoque/s3i_flutter#Auth) for a list of some implementations.
In this example we use the `OAuthProxyFlow`. You can specify some scopes to add specific claims in your token.
```dart
final authManager = OAuthProxyFlow(clientIdentity,
      openUrlCallback: (uri) {debugPrint("Please visit:" + uri.toString());}, 
      onAuthSuccess: () {debugPrint("Auth succeeded");},
      scopes: ["group", "offline_access"]);
```

If you want to assure that the user is authenticated before going on with other requests 
you could trigger the auth process explicit by calling the `getAccessToken()` function:
````dart
try {
  await authManager.getAccessToken();
} on S3IException catch (e) {
 debugPrint("Auth failed: " + e.toString());
}
````

### Use the S3I-Directory

If you want to access the S3I-Directory, use the previous constructed `AuthenticationManager`-Instance to create a `S3ICore`-Instance.
```dart
final s3i = S3ICore(authManager);
```

If the `S3ICore`-Instance is ready to use you can now receive and update information from the S3I-Directory (This is subject of
a change in the next releases pls. consider this in your structure). 

#### Get data from the directory

To get data about a specific thing you can simply call `getThing()` on your `S3ICore`-Instance. 
If you don't need the whole thing it's recommended to use a `FieldQuery` so you only receive a part of the entry 
which is faster and safes network data.
```dart
try {
  var thing = await s3i.getThing(<THING_ID>, fields: FieldQuery(["attributes/ownedBy"]));
} on S3IException catch (e) {
  debugPrint("Request Thing failed: " + e.toString());
}
```

Similar to this you can request a specific policy from the directory:
```dart
try {
  var policy = await s3i.getPolicy(<POLICY_ID>));
} on S3IException catch (e) {
  debugPrint("Request Policy failed: " + e.toString());
}
```

TODO: add search example

#### Update data in the directory

To update data in the directory it's recommended to request the target before changing it. 
This is not needed, because all data classes cloud be created without a version from the cloud but since this package doesn't support `PATCH` requests,
using only local data could lead  much more likely to unintentionally overwriting of values.

To update an entry in the directory simply use the `putThing()` or `putPolicy()` method with the locally modified object:
```dart
policyEntry.insertObserver(PolicySubject("nginx:new_test_observer"));
try {
  await s3i.putPolicy(policyEntry);
} on S3IException catch (e) {
  debugPrint("Update Policy failed: " + e.toString());
}
```

### Use the S3I-Broker

In order to send and receive messages via S3I-Broker you need an implementation of a `BrokerInterface`.
See [here](https://github.com/LukasPoque/s3i_flutter#Broker) for a list of implementations and some background information.
In this example we use an `ActiveBrokerInterface`, because it notifies us if new messages are available. If you are targeting web as a platform too,
use the `getActiveBrokerDefaultConnector` function. This function returns either an AMQPConnector (if your app is not running as web-app) or a 
RESTConnector. You can pass the different constructor arguments via the args-map.
```dart
// used to determine if the app is running on the web
import 'package:flutter/foundation.dart' show kIsWeb;

static final ActiveBrokerInterface brokerConnector = kIsWeb
      ? getActiveBrokerDefaultConnector(authManager,
          args: {'pollingInterval': const Duration(milliseconds: 500)})
      : getActiveBrokerDefaultConnector(authManager);
```

Now you can register for different events of the brokerConnector. You can even register multiple times for the same event. This is useful
if you want to use the information at different locations in the app (e.g. logging, ui, etc.).
```dart
brokerConnector
    ..subscribeConsumingFailed((String endpoint, Exception error) {
      print('Error on connection $endpoint: $error');
    })
    ..subscribeSendMessageFailed((Message msg, Exception error) {
      print('Error while sending message (${msg.identifier}) $error');
    })
    ..subscribeSendMessageSucceeded((Message msg) {
      print('Message with id ${msg.identifier} sent');
    })
```

#### Receive messages

To receive messages and working with them in your app it's a good idea to register callback for the receiving functions of the brokerConnector.
In this example we're only interested in `ServiceReply`s:
```dart
brokerConnector.subscribeServiceReplyReceived((ServiceReply msg) {
    print('Message with id ${msg.identifier} received');
});
```

If all callbacks you're interested in are registered it's time to start consuming on one (or multiple) queues on the S3I-Broker. 
For that simply call `startConsuming`. If you don't want any open connections left when your app closes, call `stopConsuming` with the same endpoint
in your dispose method.
```dart
final String ownEndpoint = '<YOUR ENDPOINT ID>';
brokerConnector.startConsuming(ownEndpoint);
//...
// dispose() or equivalent method
brokerConnector.stopConsuming(ownEndpoint);
```

#### Send messages

To send messages to other things you need to construct a message first. Then you can simply call `sendMessage` with the message and all receiver 
endpoints on your broker instance. 
```dart
static final request = ServiceRequest(
      receivers: <String>{'<SERVICE ID>'},
      sender: '<YOUR CLIENT ID>',
      replyToEndpoint: '<YOUR ENDPOINT ID>',
      serviceType: '<FML40 SERVICE TYPE>',
      parameters: <String, dynamic>{<NEEDED PARAMETERS MAP>});

brokerConnector.sendMessage(requestMsg, <String>{'<SERVICE ENDPOINT>'});
```

## Project Structure

The package is divided in domain specific folders.

The `S3ICore` uses this classes and provides methods to access the REST-APIs easier.

### Auth

The `auth` folder includes classes which are used to authenticate an user/client in the S3I and could provide valid token to 
the other parts of this package where they are used. The folder includes classes for `AccessToken` and `RefreshToken` too.

Currently only the following `AuthenticationManager` implementations are available: 
- `OAuthProxyFlow`: This implementation uses the S3I-OAuthProxy to obtain an access and refresh token.
  But it doesn't refreshes the tokens automatically, only only if `getAccessToken` is called and the previous token is expired.

### Broker

The `broker` folder includes data classes for the different messages specified in the S3I-B-Protocol and different implementations
of the `BrokerInterface` for communication with the S3I-Broker.

There are two different approaches to receive messages from the Broker. An `ActiveBrokerInterface` is for interfaces that inform you 
whenever a new message is available. A `PassiveBrokerInterface` is for interfaces where you need to explicitly ask if there are new 
messages.

At the moment, there are only active broker interfaces implemented:
- `BrokerAmqpConnector`: uses the native communication protocol of the S3i-Broker: AMQP. This is not available for the *web* platform.
- `BrokerRestConnector`: uses the S3I-Broker REST API for sending/receiving of messages.

Currently the following message types are supported:
- `UserMessage`: used for communication between two real users.
- `ServiceMessages`: used to invoke service functions or receive service answers from S3I-Services.
- `GetValueMessages`: used to get a specific value from an other thing.
- `EventSystemMessages`: used to receive/subscribe to events via the [S3I-Event-System](https://github.com/LukasPoque/s3i_flutter/issues/9#issuecomment-925665563).

### Directory

The `directory` folder includes data classes to store and manipulate the entries of a thing from the directory.

The classes are following the *S3I-Directory-Data-Model* with the `Thing` class as their root followed by different chains of 
`DirObject`, `Link` and `Value`.

### Exceptions

The `exceptions` folder includes all customized exceptions from this package.

The base class is the `S3IException` which only wraps a normal `Exception` making it easier to catch all specific S3I exceptions.

### Policy

The `policy` folder includes data classes to store and manipulate the policy entries of a thing from the directory OR repository.

A `PolicyEntry` consists of `PolicyGroup`s and manages the access control to one specific `Entry`.
Each one has it's own policy entry which is only valid for the the service where it's stored (directory/repository).
For more background information see: https://www.eclipse.org/ditto/basic-policy.html

In the S3I-Concept there are two special `PolicyGroup`s which have a specific meaning:
- owner: An owner has READ and WRITE permission to everything (thing:/, policy:/, message:/)
- observer: An observer has only READ permission to the thing part (thing:/)

### Query

The `query` folder includes the parameters for a (query)request to the S3I-Directory/Repository and the S3I-EventSystem.

Currently the following parameters are used:
- `FieldQuery`: Only the selected fields will be included in the returned json, good for faster and smaller responses.
- `NamespaceQuery`: Limit the query to things in the given namespaces only.
- `OptionQuery`: Used for sorting the responses or enable paging/cursor mechanisms.
- `RQLQuery`: A lightweight query language for the use in URLs (this could be separated to an external package in the future).

### Utils

The `utils` folder includes useful tools for the whole package. Currently it contains constant json-keys from the S3I-Services.
