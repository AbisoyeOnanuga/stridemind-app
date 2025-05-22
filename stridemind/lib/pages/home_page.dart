import 'package:flutter/material.dart';
import 'package:stridemind/pages/coach_page.dart';
import 'package:stridemind/pages/login_page.dart';
import 'package:stridemind/models/strava_activity.dart';
import 'package:stridemind/models/strava_athlete.dart';
import 'package:stridemind/pages/nutrition_upload_page.dart';
import 'package:stridemind/pages/training_upload_page.dart';
import 'package:stridemind/services/strava_api_service.dart';
import 'package:stridemind/services/strava_auth_service.dart';
import 'package:stridemind/widgets/activity_card.dart';
import 'package:stridemind/widgets/weekly_summary_panel.dart';

/// A helper class to hold the combined data for the home page.
class HomeData {
  final StravaAthlete athlete;
  final List<StravaActivity> activities;
  HomeData({required this.athlete, required this.activities});
}

class HomePage extends StatefulWidget {
  final StravaAuthService authService;
  const HomePage({super.key, required this.authService});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final List<Widget> _pages;
  final List<String> _pageTitles = const [
    'Activity Dashboard',
    'AI Coach',
    'Upload Training',
    'Upload Nutrition'
  ];
  String? _athleteFirstName;

  @override
  void initState() {
    super.initState();
    _pages = [
      ActivityDashboard(
        authService: widget.authService,
        onAthleteLoaded: (name) {
          if (mounted) {
            setState(() {
              _athleteFirstName = name;
            });
          }
        },
      ),
      CoachPage(authService: widget.authService),
      const TrainingUploadPage(),
      const NutritionUploadPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await widget.authService.logout();
    if (mounted) {
      // Navigate back to the login page and remove all previous routes.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
            builder: (context) => LoginPage(authService: widget.authService)),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String title;
    if (_selectedIndex == 0 && _athleteFirstName != null) {
      title = 'Welcome, $_athleteFirstName';
    } else {
      title = _pageTitles[_selectedIndex];
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.model_training),
            label: 'Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.upload_file),
            label: 'Training',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Nutrition',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
    );
  }
}

class ActivityDashboard extends StatefulWidget {
  final StravaAuthService authService;
  final Function(String) onAthleteLoaded;

  const ActivityDashboard(
      {super.key, required this.authService, required this.onAthleteLoaded});

  @override
  State<ActivityDashboard> createState() => _ActivityDashboardState();
}

class _ActivityDashboardState extends State<ActivityDashboard> {
  Future<HomeData>? _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = _getHomeData();
  }

  Future<HomeData> _getHomeData() async {
    final accessToken = await widget.authService.getValidAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication failed. Please log in again.');
    }
    final apiService = StravaApiService(accessToken: accessToken);
    final results = await Future.wait([
      apiService.getAuthenticatedAthlete(),
      apiService.getRecentActivities(),
    ]);

    final athlete = results[0] as StravaAthlete;
    final activities = results[1] as List<StravaActivity>;

    // Notify parent widget of the athlete's name
    widget.onAthleteLoaded(athlete.firstname);

    return HomeData(
      athlete: athlete,
      activities: activities,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _homeDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Error UI is simple, doesn't need its own Scaffold
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                // Logout button is now in the main AppBar, so we don't need it here.
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _homeDataFuture = _getHomeData();
                    });
                  },
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        } else if (snapshot.hasData) {
          final activities = snapshot.data!.activities;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text('Last 7 Days',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              WeeklySummaryPanel(activities: activities),
              const Divider(indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text('Recent Activities',
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: activities.isEmpty
                    ? const Center(child: Text('No recent activities found.'))
                    : ListView.builder(
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          return ActivityCard(activity: activities[index]);
                        },
                      ),
              ),
            ],
          );
        } else {
          return const Center(child: Text('No data found.'));
        }
      },
    );
  }
}