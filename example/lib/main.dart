import 'package:flutter/material.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// used to determine if the app is running on the web
import 'package:flutter/foundation.dart' show kIsWeb;

//TODO: replace with your own client data
// the client used here has no permissions in the s3i unless your personal
// account grants some
final clientIdentity = ClientIdentity("s3i:flutter-example-client",
    secret: "86c0025d-3cb4-4db8-a8d3-4bf30e2e0930");
final String ownEndpoint = 's3ib://s3i:cb420dbc-0d0f-4c57-8cf6-12bdf96b8578';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S3I Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: MyHomePage(title: 'S3I Flutter Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  // place this instances somewhere else in your application and use a proper
  // state management solution for the things/login state etc.
  static final authManager = OAuthProxyFlow(clientIdentity,
      maxRetryPickup: 500,
      retryWaitingTimeMilliSec: 100,
      openUrlCallback: openUrl, onAuthSuccess: () {
    debugPrint("Auth succeeded");
  }, scopes: ["group", "offline_access"]);
  static final s3i = S3ICore(authManager);

  static final Future<void> Function(Uri) openUrl = (url) async {
    // open the given url in the default browser
    await canLaunch(url.toString())
        ? await launch(url.toString())
        : throw "Could not open the login page" + url.toString();
  };

  /// pass extra information to the REST connector (if we are running on web)
  static final ActiveBrokerInterface brokerConnector = kIsWeb
      ? getActiveBrokerDefaultConnector(authManager,
          args: {'pollingInterval': const Duration(milliseconds: 500)})
      : getActiveBrokerDefaultConnector(authManager)
    // subscribe to events of the active broker interface
    ..subscribeConsumingFailed((endpoint, error) {
      print('Error on connection $endpoint: $error');
    })
    ..subscribeSendMessageFailed((msg, error) {
      print('Error while sending message (${msg.identifier}) $error');
    })
    ..subscribeSendMessageSucceeded((msg) {
      print('Message with id ${msg.identifier} sent');
    })
    ..subscribeServiceReplyReceived((msg) {
      print('Message with id ${msg.identifier} received');
    });

  //id of the vSFL passability service (could be offline)
  static final String serviceId = 's3i:aae1178b-0499-47bf-a7c6-58fa92102e1a';
  static final String serviceEndpoint = 's3ib://$serviceId';

  //create new service request
  static final request = ServiceRequest(
      receivers: <String>{serviceId},
      sender: clientIdentity.id,
      replyToEndpoint: ownEndpoint,
      serviceType: 'fml40::ProvidesPassabilityInformation/calculatePassability',
      parameters: <String, String>{'load': '40', 'moisture': '60'});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final thingIdInputController = TextEditingController();
  final policyIdInputController = TextEditingController();

  // s3i values
  AccessToken? accessToken;
  Thing? requestedThing;
  PolicyEntry? requestedPolicy;
  ServiceReply? lastReply;

  _MyHomePageState() {
    //connect to service reply a second time to setState
    MyHomePage.brokerConnector.subscribeServiceReplyReceived((msg) {
      setState(() {
        lastReply = msg;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: ListView(
            children: <Widget>[
              _buildAuthArea(),
              Divider(height: 5, thickness: 5),
              _buildThingRequestArea(),
              Divider(height: 5, thickness: 5),
              _buildEditThingArea(),
              Divider(height: 5, thickness: 5),
              _buildPolicyRequestArea(),
              Divider(height: 5, thickness: 5),
              _buildBrokerArea(),
            ],
          ),
        ));
  }

  Widget _buildAuthArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // use try/catch and handle the "expected" errors that could be thrown
              try {
                var token = await MyHomePage.s3i.login();
                setState(() {
                  accessToken = token;
                });
              } on S3IException catch (e) {
                debugPrint("Auth failed");
                debugPrint(e.toString());
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Login via S³I'),
            ),
          ),
          SizedBox(height: 16),
          SelectableText(accessToken != null ? accessToken!.originalToken : ""),
          SizedBox(height: 8),
          SelectableText(accessToken != null
              ? accessToken!.decodedPayload.toString()
              : ""),
        ],
      ),
    );
  }

  Widget _buildThingRequestArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: thingIdInputController,
                ),
              ),
              SizedBox(width: 8),
              OutlinedButton(
                  onPressed: () async {
                    try {
                      // requests the given thing id
                      // you need read access to the thing
                      var thing = await MyHomePage.s3i
                          .getThing(thingIdInputController.text);
                      setState(() {
                        requestedThing = thing;
                      });
                    } on S3IException catch (e) {
                      debugPrint("Request Thing failed");
                      debugPrint(e.toString());
                      setState(() {
                        requestedThing = null;
                      });
                    }
                  },
                  child: Text("Request Thing"))
            ],
          ),
          SizedBox(height: 8),
          if (requestedThing != null) _buildThingRep(requestedThing!)
        ],
      ),
    );
  }

  Widget _buildEditThingArea() {
    return requestedThing != null
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  // adds an fictional feature to the thing which is loaded
                  // you need write access to the thing
                  var newLink = Link("feature");
                  newLink.target = DirObject("s3i_test");
                  // you need to check every nullable value for safe usage!
                  requestedThing!.thingStructure!.links!.add(newLink);
                  await MyHomePage.s3i.putThing(requestedThing!);
                } on S3IException catch (e) {
                  debugPrint("Put Thing failed");
                  debugPrint(e.toString());
                }
              },
              child: Text("Add Feature <s3i_test> to the thing"),
            ),
          )
        : Container();
  }

  Widget _buildPolicyRequestArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: policyIdInputController,
                ),
              ),
              SizedBox(width: 8),
              OutlinedButton(
                  onPressed: () async {
                    try {
                      // requests the given policy
                      // you need read access to the policy
                      var policy = await MyHomePage.s3i
                          .getPolicy(policyIdInputController.text);
                      setState(() {
                        requestedPolicy = policy;
                      });
                    } on S3IException catch (e) {
                      debugPrint("Request Policy failed");
                      debugPrint(e.toString());
                      setState(() {
                        requestedPolicy = null;
                      });
                    }
                  },
                  child: Text("Request Policy"))
            ],
          ),
          SizedBox(height: 8),
          if (requestedPolicy != null) Text(requestedPolicy.toString())
        ],
      ),
    );
  }

  Widget _buildBrokerArea() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              // subscribe to our own queue
              MyHomePage.brokerConnector.startConsuming(ownEndpoint);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Start consuming own endpoint'),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              // Unsubscribe to our own queue
              MyHomePage.brokerConnector.stopConsuming(ownEndpoint);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Stop consuming own endpoint'),
            ),
          ),
          SizedBox(width: 8),
          OutlinedButton(
              onPressed: () async {
                //send service request
                MyHomePage.brokerConnector.sendMessage(
                    MyHomePage.request, <String>{MyHomePage.serviceEndpoint});
              },
              child: Text("Send Service-Request to Passability-Service")),
          SizedBox(height: 8),
          if (lastReply != null) Text(lastReply!.toJson().toString()),
        ],
      ),
    );
  }

  @override
  void dispose() {
    thingIdInputController.dispose();
    // Unsubscribe to our own queue, disconnect from the broker
    // this is not necessary
    MyHomePage.brokerConnector.stopConsuming(ownEndpoint);
    super.dispose();
  }
}

Widget _buildThingRep(Thing requestedThing) {
  return Column(
    children: [
      Row(
        children: [
          Text("Name:"),
          SizedBox(width: 8),
          Expanded(
              child: Text(
                  requestedThing.name != null ? requestedThing.name! : "-")),
        ],
      ),
      SizedBox(height: 8),
      Row(
        children: [
          Text("Owned By:"),
          SizedBox(width: 8),
          Expanded(
              child: Text(requestedThing.ownedBy != null
                  ? requestedThing.ownedBy!
                  : "-")),
        ],
      ),
      SizedBox(height: 8),
      Row(
        children: [
          Text("Attributes:"),
          SizedBox(width: 8),
          Expanded(
            child: Text(requestedThing.thingStructure != null
                ? requestedThing.thingStructure!.toString()
                : "-"),
          ),
        ],
      )
    ],
  );
}
