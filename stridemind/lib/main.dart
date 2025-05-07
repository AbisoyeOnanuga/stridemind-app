import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:stridemind/services/strava_auth_service.dart';

void main() {
  runApp(StrideMindApp());
}

class StrideMindApp extends StatefulWidget {
  @override
  State<StrideMindApp> createState() => _StrideMindAppState();
}

class _StrideMindAppState extends State<StrideMindApp> {
  late final AppLinks _appLinks;
  final StravaAuthService _stravaAuthService = StravaAuthService();

  @override
  void initState() {
    super.initState();
    initAppLinks();
  }

  void initAppLinks() async {
    _appLinks = AppLinks();

    try {
      // Handles cold start
      final Uri? initialUri = await _appLinks.getInitialAppLink();
      handleIncomingUri(initialUri);

      // Handles runtime deep links
      _appLinks.uriLinkStream.listen((Uri? uri) {
        handleIncomingUri(uri);
      });
    } catch (e) {
      print("Error handling deep link: $e");
    }
  }

  void handleIncomingUri(Uri? uri) {
    if (uri != null && uri.queryParameters.containsKey('code')) {
      final code = uri.queryParameters['code'];
      print("Received Strava code: $code");
      _stravaAuthService.exchangeCodeForToken(code!); // ✅ Integrate your auth logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Strava Login Example")),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Launching Strava login...')),
              );
              _stravaAuthService.loginWithStrava(); // ✅ Trigger login
            },
            child: Text("Login with Strava"),
          ),
        ),
      ),
    );
  }
}

class WorkoutCard extends StatelessWidget {
  final String prescribed;
  final String adjusted;
  final int recoveryScore;

  const WorkoutCard({
    required this.prescribed,
    required this.adjusted,
    required this.recoveryScore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Card(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
      margin: const EdgeInsets.all(16),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Prescribed: $prescribed"),
            Text("Adjusted: $adjusted"),
            Text("Recovery Score: $recoveryScore"),
          ],
        ),
      ),
    );
  }
}
