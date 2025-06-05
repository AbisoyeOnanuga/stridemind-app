import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stridemind/models/strava_activity.dart' as strava_models;
import 'package:stridemind/services/strava_api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:stridemind/services/strava_auth_service.dart';
import 'package:stridemind/services/feedback_service.dart';
import 'package:stridemind/services/prompt_service.dart';

class CoachPage extends StatefulWidget {
  final StravaAuthService authService;
  const CoachPage({super.key, required this.authService});

  @override
  State<CoachPage> createState() => _CoachPageState();
}

class _CoachPageState extends State<CoachPage> {
  final _noteController = TextEditingController();
  List<dynamic>? _aiFeedback; // For displaying the current feedback or error
  List<Map<String, dynamic>>? _conversationHistory; // For persistence
  bool _isLoading = false;
  final _feedbackService = FeedbackService();
  final _promptService = PromptService();
  Future<List<strava_models.StravaActivity>>? _todaysActivitiesFuture;

  @override
  void initState() {
    super.initState();
    _todaysActivitiesFuture = _getTodaysActivities();
    _loadConversationHistory();
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

  Future<void> _loadConversationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyString = prefs.getString('conversation_history');
    if (historyString != null) {
      if (mounted) {
        final decoded = jsonDecode(historyString) as List<dynamic>;
        final history =
            decoded.map((e) => e as Map<String, dynamic>).toList();
        setState(() {
          _conversationHistory = history;
          if (history.isNotEmpty) {
            // Display the last feedback from history on initial load
            _aiFeedback =
                history.last['feedback']?['feedback'] as List<dynamic>?;
          }
        });
      }
    }
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
      _aiFeedback = null; // Clear previous feedback while loading
    });

    try {
      final todaysActivities = await _todaysActivitiesFuture;
      if (todaysActivities == null) {
        throw Exception("Workout data not loaded yet.");
      }

      final history = _conversationHistory ?? [];
      final prompt = _promptService.buildFeedbackPrompt(
        _noteController.text,
        todaysActivities,
        history,
      );

      final feedbackJsonString = await _feedbackService.getFeedback(prompt);
      // The AI might return the JSON string wrapped in markdown ```json ... ```, so we clean it.
      final cleanedJson =
          feedbackJsonString.replaceAll('```json', '').replaceAll('```', '').trim();
      final feedbackData = jsonDecode(cleanedJson);

      // Create new turn and add to history
      final newTurn = {
        'log': _noteController.text,
        'feedback': feedbackData,
      };
      final updatedHistory = List<Map<String, dynamic>>.from(history)
        ..add(newTurn);

      // Optional: Trim history to keep it from growing too large
      const maxHistoryLength = 10;
      if (updatedHistory.length > maxHistoryLength) {
        updatedHistory.removeRange(0, updatedHistory.length - maxHistoryLength);
      }

      // Save the updated history
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('conversation_history', jsonEncode(updatedHistory));

      if (mounted) {
        setState(() {
          _isLoading = false;
          _conversationHistory = updatedHistory;
          _aiFeedback = feedbackData['feedback'] as List<dynamic>?; // Set display
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _aiFeedback = [
            // Set display to an error message, but DO NOT save to history
            {'type': 'heading', 'content': {'title': 'Error', 'text': 'Failed to get feedback: ${e.toString()}'}}
          ];
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
            child: _buildFeedbackContent(_aiFeedback!),
          ),
      ],
    );
  }

  Widget _buildFeedbackContent(List<dynamic> feedbackSections) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: feedbackSections.map<Widget>((section) {
        final type = section['type'];
        final content = section['content'];

        switch (type) {
          case 'heading':
            return _buildHeadingSection(content);
          case 'table':
            return _buildTableSection(content);
          case 'bold_text':
            return _buildBoldTextSection(content);
          default:
            return Text('Unknown content type: $type');
        }
      }).toList(),
    );
  }

  Widget _buildHeadingSection(dynamic content) {
    final title = content['title'] as String? ?? 'Feedback';
    final text = content['text'] as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          MarkdownBody(
            data: text,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              p: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableSection(dynamic content) {
    final title = content['title'] as String? ?? '';
    final headers = (content['headers'] as List<dynamic>?)
            ?.map((h) => h.toString())
            .toList() ??
        [];
    final rows = (content['rows'] as List<dynamic>?)
            ?.map((row) =>
                (row as List<dynamic>).map((cell) => cell.toString()).toList())
            .toList() ??
        [];

    if (headers.isEmpty || rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: headers
                  .map((header) => DataColumn(
                          label: Text(header,
                              style: const TextStyle(fontWeight: FontWeight.bold))))
                  .toList(),
              rows: rows
                  .map((row) => DataRow(
                      cells: row.map((cell) => DataCell(Text(cell))).toList()))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoldTextSection(dynamic content) {
    final text = content as String? ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
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
              subtitle: 'coming soon...',
            ),
            _buildContextTile(
              icon: Icons.style,
              title: 'Gear',
              subtitle: 'coming soon...',
            ),
          ],
        );
      },
    );
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