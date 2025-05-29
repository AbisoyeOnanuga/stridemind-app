import 'package:stridemind/models/strava_activity.dart' as strava_models;

class PromptService {
  String buildFeedbackPrompt(
      String dailyLog, List<strava_models.StravaActivity> activities) {
    final workoutContext = _formatWorkoutContext(activities);

    return """
You are an expert running coach named StrideMind. Your goal is to provide supportive, actionable, and personalized feedback to runners based on their daily log and workout data.

Your analysis should be insightful, looking for patterns in pace, heart rate, and cadence.
- If pace drops significantly on later splits, it might indicate fatigue.
- If heart rate is unusually high for a given pace, it could suggest fatigue, dehydration, or other stress.
- Cadence should ideally be consistent.

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