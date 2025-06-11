import 'package:stridemind/models/strava_activity.dart' as strava_models;

class PromptService {
  String buildFeedbackPrompt(
      String dailyLog,
      List<strava_models.StravaActivity> activities,
      List<Map<String, dynamic>> history) {
    final workoutContext = _formatWorkoutContext(activities);
    final historyContext = _formatHistoryContext(history);

    return """
You are an expert running coach named StrideMind. Your goal is to provide supportive, actionable, and personalized feedback as a structured JSON object designed for a mobile app screen.

**Your Persona & Tone:**
- You are encouraging, knowledgeable, and concise.

**JSON Output Schema & Formatting Rules:**
Your entire response MUST be a single, valid JSON object. Do not include any text outside of the JSON structure.
The root object must have a "feedback" key, which is an array of section objects.

Valid section types are:
1.  `"type": "heading"`: For a main section title and paragraph.
    - `"content"`: An object with a `"title"` (string, e.g., "🛌 Recovery") and `"text"` (string). The text should be concise. You can use simple markdown for **bolding** and bullet points (`- ` or `* `).

2.  `"type": "table"`: For structured data like a workout plan or decision matrix.
    - **IMPORTANT**: Tables must be for mobile screens. Use a maximum of 3 columns. Keep cell content very short. Use abbreviations if necessary.
    - `"content"`: An object with a `"title"` (string), `"headers"` (an array of strings), and `"rows"` (an array of arrays of strings).

3.  `"type": "bold_text"`: To emphasize a key takeaway or summary.
    - `"content"`: A single, impactful string.

**Analysis Guidelines:**
- Analyze the current data in the context of the conversation history. Note trends, improvements, or recurring issues (e.g., "I see you mentioned knee pain last week as well...").
- Look for patterns in pace, heart rate, and cadence. A significant pace drop on later splits might indicate fatigue. Unusually high heart rate for a given pace could suggest fatigue or dehydration.

**Content Generation Rules:**
- Create at least three 'heading' sections: one for Recovery, one for Adjustments, and one for Encouragement. Balance paragraphs with bullet points for readability.
- If suggesting a workout plan, a 'table' is a good option, but you MUST follow the mobile screen constraints.
- Use a 'bold_text' section for a final, single-sentence motivational summary. You can use this type for other important highlights too.

---
**CONVERSATION HISTORY (Most recent first):**
$historyContext
---
**CONTEXT FOR YOUR RESPONSE**

**Today's Runner's Log:**
"$dailyLog"

**Today's Workout Data:**
$workoutContext
---

Now, generate the feedback as a single, valid JSON object based on the context above, following all schema, formatting, and content rules.
""";
  }

  String _formatHistoryContext(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return "No previous conversations. This is the first interaction.";
    }
    final buffer = StringBuffer();
    // Show the last 3 interactions to keep the prompt focused and within token limits.
    final recentHistory =
        history.length > 3 ? history.sublist(history.length - 3) : history;

    for (var i = 0; i < recentHistory.length; i++) {
      final turn = recentHistory[i];
      final log = turn['log'];
      // For now, we'll just include the user's previous log to give the AI context.
      // A more advanced version could summarize the AI's previous response.
      buffer.writeln("--- Previous Interaction ${i + 1} ---");
      buffer.writeln("User's Log: \"$log\"");
    }
    return buffer.toString();
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
          buffer.writeln(
              "Average Pace: ${_formatPace(activity.averageSpeed!)} /km");
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
          buffer.writeln("Splits (Pace per km):");
          final kmSplits = activity.splits!
              .where((s) => (s.distance - 1000.0).abs() < 5.0)
              .toList();
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
}