import 'package:flutter/material.dart';
import 'package:stridemind/models/strava_activity.dart';

class WeeklySummaryPanel extends StatelessWidget {
  final List<StravaActivity> activities;

  const WeeklySummaryPanel({super.key, required this.activities});

  @override
  Widget build(BuildContext context) {
    final weekStart = DateTime.now().subtract(const Duration(days: 7));
    final weeklyActivities =
        activities.where((a) => a.startDateLocal.isAfter(weekStart)).toList();

    final double totalDistance =
        weeklyActivities.fold(0.0, (sum, a) => sum + a.distance);
    final int totalTime =
        weeklyActivities.fold(0, (sum, a) => sum + a.movingTime);
    final double totalElevation =
        weeklyActivities.fold(0.0, (sum, a) => sum + a.totalElevationGain);

    final duration = Duration(seconds: totalTime);
    final formattedTime =
        '${duration.inHours}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryStat(
              label: 'Distance',
              value: '${(totalDistance / 1000).toStringAsFixed(1)} km',
            ),
            _SummaryStat(
              label: 'Time',
              value: formattedTime,
            ),
            _SummaryStat(
              label: 'Elevation',
              value: '${totalElevation.toStringAsFixed(0)} m',
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}