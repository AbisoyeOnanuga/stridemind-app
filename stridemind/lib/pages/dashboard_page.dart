import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  final mockLogs = const [
    {
      'date': 'Aug 7',
      'activity': 'Morning Run',
      'mood': '😄',
      'feedback': 'You’re thriving after these workouts!',
    },
    {
      'date': 'Aug 6',
      'activity': 'Evening Ride',
      'mood': '😐',
      'feedback': 'Keep tracking to uncover deeper patterns.',
    },
    {
      'date': 'Aug 5',
      'activity': 'Trail Hike',
      'mood': '😊',
      'feedback': 'Nature seems to boost your mood. Consider more trail days.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Dashboard')),
      body: ListView.builder(
        itemCount: mockLogs.length,
        itemBuilder: (context, index) {
          final log = mockLogs[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text('${log['activity']} • ${log['date']}'),
              subtitle: Text(log['feedback']!),
              trailing: Text(log['mood']!, style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }
}
