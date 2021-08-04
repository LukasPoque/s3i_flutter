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

The S³I is a centralised infrastructure with currentyl five main services for the decentralized IoT of WH4.0 Things (Forestry4.0 Things) developed by the [KWH4.0](https://www.kwh40.de/).

If you are not familiar with the S³I concepts, please read the 
[KWH4.0-Standpunkt](https://www.kwh40.de/wp-content/uploads/2020/04/KWH40-Standpunkt-S3I-v2.0.pdf).

For further information see the [KWH Glossar](https://www.kwh40.de/glossar/) and the other [Standpunkte](https://www.kwh40.de/veroffentlichungen/).

## Installing

Add it to your `pubspec.yaml` file:
```yaml
dependencies:
  s3i_flutter: ^0.2.1
```
Install packages from the command line
```
flutter packages get
```

If you like this package, consider supporting it by giving a star on [GitHub](https://github.com/LukasPoque/s3i_flutter) and 
a like on [pub.dev](https://pub.dev/packages/s3i_flutter) :heart:

## Usage

For a basic example application see the [example](https://github.com/LukasPoque/s3i_flutter/tree/master/example).

### Setup authentication

First you need to create a `ClientIdentity` used by your app. Please contact the [KWH4.0](https://www.kwh40.de/kontakt/) to get an app specific client.
```dart
final clientIdentity = ClientIdentity(<CLIENT-ID>, <CLIENT-SECRET>);
```

Now you can pass this to an `AuthenticationManager` of your choice. 
See [here](https://github.com/LukasPoque/s3i_flutter#auth) for a list of some implementations.
In this example we use the `OAuthProxyFlow`. You can specify some scopes to add specific claims in your token.
```dart
final authManager = OAuthProxyFlow(clientIdentity,
      openUrlCallback: (uri) {debugPrint("Please visit:" + uri.toString());}, 
      onAuthSuccess: () {debugPrint("Auth succeeded");},
      scopes: ["group", "offline_access"]);
```

Last but not least you should use this `AuthenticationManager`-Instance to create a `S3ICore`-Instance.
```dart
final s3i = S3ICore(authManager);
```

If you want to assure that the user is authenticated before going on with other requests 
you could trigger the auth process explicit by calling the `login()` function:
````dart
try {
  await s3i.login();
} on S3IException catch (e) {
 debugPrint("Auth failed: " + e.toString());
}
````

If the `S3ICore`-Instance is ready to use you can now receive and update information from the S3I-Services. 

### Get data from the directory

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

### Update data in the directory

To update data in the directory it's recommended to request the target before changing it. 
This is not needed, because all data classes cloud be created without a version from the cloud but since this package doesn't support `PATCH` requests,
using only local data could lead  much more likely to unintentionally overwriting of values.

To update an entry in the directory simply use the `putThing()` or `putPolicy()` method with the locally modified object:
```dart
policyEntry.insertObserver(PolicySubject("nginx:test_observer"));
try {
  await s3i.putPolicy(policyEntry);
} on S3IException catch (e) {
  debugPrint("Update Policy failed: " + e.toString());
}
```

### Send and receive messages via S3I-Broker

TODO: ...

## Project Structure

TODO: s3i core / entry

### directory

### auth

The `auth` folder includes classes which are used to authenticate a user/client in the S3I.

The `S3ICore` needs a valid instance of a `AuthenticationManager` to work.

Currently there is only one implementation available: `OAuthProxyFlow`.
This implementation of the `AuthenticationManager` uses the S3I-OAuthProxy to obtain an access and refresh token.
But it doesn't refreshes the tokens automatically, only only if `getAccessToken` is called and the `accessToken` is expired.

### policy

The `policy` folder includes data classes to store and manipulate the policy entries of a thing from the directory OR repository.

A `PolicyEntry` consists of `PolicyGroup`s and manages the access control to one specific `Entry`.
Each one has it's own policy entry which is only valid for the the service where it's stored (directory/repository).
For more background information see: https://www.eclipse.org/ditto/basic-policy.html

In the S3I-Concept there are two special `PolicyGroup`s which have a specific meaning:
- owner: An owner has READ and WRITE permission to everything (thing:/, policy:/, message:/)
- observer: An observer has only READ permission to the thing part (thing:/)

### broker

### exceptions

### query

### utils
