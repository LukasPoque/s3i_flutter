import 'package:flutter/material.dart';
import 'package:s3i_flutter/s3i_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

//TODO: replace with your own client data
// the client used here has no permissions in the s3i unless your personal
// account grants some
final clientIdentity = ClientIdentity("s3i-flutter-example-client",
    secret: "a3d4752b-396d-4bc8-a337-e54fb2c1706d");

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              _buildAuthArea(),
              Divider(height: 5, thickness: 5),
              _buildThingRequestArea(),
              Divider(height: 5, thickness: 5),
              _buildEditThingArea(),
              Divider(height: 5, thickness: 5),
              _buildPolicyRequestArea()
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
          SelectableText(
              accessToken != null ? accessToken!.decodedPayload.toString() : ""),
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

  @override
  void dispose() {
    thingIdInputController.dispose();
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
