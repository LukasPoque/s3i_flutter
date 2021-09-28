## 0.5.0

Add S3I Event System functionality:

-  EventMessage, EventSubscriptionRequest, EventSubscriptionReply
-  `POST` and `DELETE` methods for the S3I-Config-API
-  Methods to create/remove normal and event broker endpoints (queues)
-  Method to configure the `ActiveBrokerInterfaces` to be used as an event broker
-  `EventSystemConnector` - a class to simplify the subscription to custom/named events

## 0.4.1

Fix utf8 encoding problems.

## 0.4.0

Add S3I-Broker functionality:
- S3I-B-Messages classes (Message, UserMessage, ServiceMessage (ServiceRequest, ServiceReply), AttributeValueMessage (GetValueRequest, GetValueReply))
- Basic interfaces for the Broker communication (BrokerInterface, ActiveBrokerInterface, PassiveBrokerInterface):
  - ActiveBrokerInterface for interfaces that inform you whenever a new message is available
  - PassiveBrokerInterface for interfaces where you need to explicitly ask if there are new messages
- An implementation of the ActiveBrokerInterface using the AMQP protocol (not usable for web)
- An implementation of the ActiveBrokerInterface using the REST API of the broker

## 0.3.0

Add linting rules and fulfill them.
- add documentation to all public members, classes and methods
- restructure some of the exceptions and add every thrown exception to the documentation of the method
- improve tests

## 0.2.1

Add web support and fix formatting + README.

## 0.2.0

Add Policy classes.
- add policies: `PolicyEntry` as class for all policies in the directory or repository, using `PolicyGroup`, `PolicyResource`, `PolicySubject` for
a better data encapsulation
- add `InvalidArgumentException` for arguments which are not matching the expectations

## 0.1.0

First release of the S3I Flutter package. Currently supported:
- Authenticate via `OAuthProxyFlow`
- Request a single thing from the directory
- Modify a single thing in the directory
