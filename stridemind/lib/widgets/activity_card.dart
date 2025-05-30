import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stridemind/models/strava_activity.dart';

class ActivityCard extends StatelessWidget {
  final StravaActivity activity;

  const ActivityCard({super.key, required this.activity});

  IconData _getIconForActivityType(String type) {
    switch (type) {
      case 'Run':
        return Icons.directions_run;
      case 'Ride':
      case 'VirtualRide':
        return Icons.directions_bike;
      case 'Swim':
        return Icons.pool;
      case 'Walk':
        return Icons.directions_walk;
      case 'Hike':
        return Icons.hiking;
      case 'WeightTraining':
        return Icons.fitness_center;
      default:
        return Icons.sports;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getIconForActivityType(activity.type),
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(activity.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(activity.startDateLocal),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${activity.distanceInKm.toStringAsFixed(2)} km',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text(activity.formattedMovingTime,
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }
}