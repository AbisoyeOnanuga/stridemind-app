import 'package:flutter/material.dart';
import 'package:stridemind/models/strava_activity.dart' as strava_models;
import 'package:stridemind/services/strava_api_service.dart';
import 'package:stridemind/services/strava_auth_service.dart';
import 'package:stridemind/services/feedback_service.dart';

class CoachPage extends StatefulWidget {
  final StravaAuthService authService;
  const CoachPage({super.key, required this.authService});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _noteController = TextEditingController();
  String? _aiFeedback;
  bool _isLoading = false;
  final _feedbackService = FeedbackService();
  Future<List<strava_models.StravaActivity>>? _todaysActivitiesFuture;

  @override
  void initState() {
    super.initState();
    _todaysActivitiesFuture = _getTodaysActivities();
  }

  Future<List<strava_models.StravaActivity>> _getTodaysActivities() async {
    final accessToken = await widget.authService.getValidAccessToken();
    if (accessToken == null) {
      throw Exception('Authentication failed.');
    }
    final apiService = StravaApiService(accessToken: accessToken);
    final summaryActivities = await apiService.getTodaysActivities();

    // Fetch detailed data for run activities in parallel
    final detailedActivities =
        await Future.wait(summaryActivities.map((activity) async {
      if (activity.type.toLowerCase() == 'run') {
        try {
          // Fetch details and return a new activity object with combined data
          return await apiService.getActivityDetails(activity.id);
        } catch (e) {
          // If details fail, return the summary activity so the UI doesn't break
          debugPrint('Could not fetch details for activity ${activity.id}: $e');
          return activity;
        }
      } else {
        return activity;
      }
    }));

    return detailedActivities;
  }

  void _generateFeedback() async {
    if (_noteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a note about your day.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _aiFeedback = null;
    });

    try {
      final todaysActivities = await _todaysActivitiesFuture;
      if (todaysActivities == null) {
        throw Exception("Workout data not loaded yet.");
      }

      final prompt = _buildPrompt(
        _noteController.text,
        todaysActivities,
      );

      final feedback = await _feedbackService.getFeedback(prompt);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _aiFeedback = feedback;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _aiFeedback = "Failed to get feedback: ${e.toString()}";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error generating feedback. Please try again. ${e.toString()}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          title: 'Daily Log',
          icon: Icons.edit_note,
          child: TextField(
            controller: _noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'How was your training? How are you feeling?',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: "Today's Context",
          icon: Icons.checklist_rtl,
          child: _buildTodaysContext(),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _generateFeedback,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Get AI Feedback'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 24),
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        if (_aiFeedback != null)
          _buildSectionCard(
            title: 'AI Coach Feedback',
            icon: Icons.chat_bubble_outline,
            child: Text(
              _aiFeedback!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildTodaysContext() {
    return FutureBuilder<List<strava_models.StravaActivity>>(
      future: _todaysActivitiesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          // You might want to offer a retry button here
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final activities = snapshot.data ?? [];

        return Column(
          children: [
            if (activities.isEmpty)
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text("No activities logged today."),
                contentPadding: EdgeInsets.zero,
              ),
            ...activities.map((activity) {
              // If it's a run and we have detailed data, show the details.
              if (activity.type.toLowerCase() == 'run' &&
                  activity.averageSpeed != null) {
                return _buildRunDetails(activity);
              } else {
                // Otherwise, show the basic summary tile.
                return _buildContextTile(
                  icon: _getIconForActivityType(activity.type),
                  title: activity.name,
                  subtitle:
                      '${activity.type} - ${_formatDistance(activity.distance)} - ${_formatDuration(activity.movingTime)}',
                );
              }
            }).toList(),
            // You can add back other static context tiles here if needed
            _buildContextTile(
              icon: Icons.event_note,
              title: 'Training Plan',
              subtitle: 'Tomorrow: Rest Day',
            ),
            _buildContextTile(
              icon: Icons.style,
              title: 'Gear',
              subtitle: 'Running Shoes (250km used)',
            ),
          ],
        );
      },
    );
  }

  String _buildPrompt(
      String dailyLog, List<strava_models.StravaActivity> activities) {
    final workoutContext = _formatWorkoutContext(activities);

    return """
You are an expert running coach named StrideMind. Your goal is to provide supportive, actionable, and personalized feedback to runners based on their daily log and workout data.

Here is the runner's log for today:
---
$dailyLog
---

Here is the runner's workout data for today:
---
$workoutContext
---

Based on this information, provide feedback that covers these areas:
1.  **Recovery:** Comment on their perceived effort, fatigue, or any pains mentioned. Suggest recovery strategies (e.g., sleep, nutrition, stretching).
2.  **Adjustments:** Based on the data and their log, suggest any adjustments to their upcoming training. If things look good, affirm their current plan.
3.  **Encouragement:** Provide positive reinforcement and motivation. Highlight their successes and consistency.

Keep the tone encouraging and professional. Use markdown for formatting, like **bolding** key terms.
""";
  }

  String _formatWorkoutContext(List<strava_models.StravaActivity> activities) {
    if (activities.isEmpty) {
      return "No workouts logged today.";
    }

    final buffer = StringBuffer();
    for (final activity in activities) {
      buffer.writeln("Activity: ${activity.name} (${activity.type})");
      buffer.writeln("Distance: ${_formatDistance(activity.distance)}");
      buffer.writeln("Moving Time: ${_formatDuration(activity.movingTime)}");

      if (activity.type.toLowerCase() == 'run' &&
          activity.averageSpeed != null) {
        if (activity.averageSpeed! > 0) {
          buffer.writeln("Average Pace: ${_formatPace(activity.averageSpeed!)} /km");
        }
        if (activity.averageHeartrate != null) {
          buffer.writeln(
              "Average Heart Rate: ${activity.averageHeartrate!.toStringAsFixed(0)} bpm");
        }
        if (activity.averageCadence != null) {
          buffer.writeln(
              "Average Cadence: ${(activity.averageCadence! * 2).toStringAsFixed(0)} spm");
        }
        if (activity.splits != null && activity.splits!.isNotEmpty) {
          buffer.writeln("Splits:");
          final kmSplits =
              activity.splits!.where((s) => (s.distance - 1000.0).abs() < 5.0).toList();
          for (var i = 0; i < kmSplits.length; i++) {
            final split = kmSplits[i];
            buffer.writeln(
                "  - Km ${i + 1}: ${_formatPace(split.averageSpeed)} (${_formatDuration(split.movingTime)})");
          }
        }
      }
      buffer.writeln(); // Add a blank line between activities
    }

    return buffer.toString();
  }

  Widget _buildRunDetails(strava_models.StravaActivity activity) {
    final details = <String>[];
    if (activity.averageSpeed != null && activity.averageSpeed! > 0) {
      details.add('Avg Pace: ${_formatPace(activity.averageSpeed!)} /km');
    }
    if (activity.averageHeartrate != null) {
      details.add('Avg HR: ${activity.averageHeartrate!.toStringAsFixed(0)} bpm');
    }
    if (activity.averageCadence != null) {
      details.add('Avg Cadence: ${(activity.averageCadence! * 2).toStringAsFixed(0)} spm');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContextTile(
          icon: _getIconForActivityType(activity.type),
          title: activity.name,
          subtitle:
              '${_formatDistance(activity.distance)} - ${_formatDuration(activity.movingTime)}',
        ),
        if (details.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 56, top: 4, bottom: 8),
            child: Text(details.join('  •  ')),
          ),
        if (activity.splits != null && activity.splits!.isNotEmpty)
          _buildSplitsTable(activity.splits!),
      ],
    );
  }

  Widget _buildSplitsTable(List<strava_models.Split> splits) {
    // Filter for metric splits (which are per km)
    final kmSplits =
        splits.where((s) => (s.distance - 1000.0).abs() < 5.0).toList();

    if (kmSplits.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 40.0, right: 16, top: 0, bottom: 8),
      child: DataTable(
        columnSpacing: 24,
        horizontalMargin: 0,
        headingRowHeight: 24,
        dataRowMinHeight: 24,
        dataRowMaxHeight: 32,
        columns: const [
          DataColumn(label: Text('Split')),
          DataColumn(label: Text('Pace/km'), numeric: true),
          DataColumn(label: Text('Time'), numeric: true),
        ],
        rows: List.generate(kmSplits.length, (index) {
          final split = kmSplits[index];
          return DataRow(
            cells: [
              DataCell(Text('${index + 1}')),
              DataCell(Text(_formatPace(split.averageSpeed))),
              DataCell(Text(_formatDuration(split.movingTime))),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildContextTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600]),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    }
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }

  String _formatPace(double speedInMps) {
    if (speedInMps <= 0) return 'N/A';
    final secondsPerKm = 1000 / speedInMps;
    final pace = Duration(seconds: secondsPerKm.round());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(pace.inMinutes.remainder(60));
    final seconds = twoDigits(pace.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final secs = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return "$hours:$minutes:$secs";
    }
    return "$minutes:$secs min";
  }

  IconData _getIconForActivityType(String type) {
    switch (type.toLowerCase()) {
      case 'run':
        return Icons.directions_run;
      default:
        return Icons.fitness_center;
    }
  }
}