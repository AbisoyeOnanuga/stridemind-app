import 'package:flutter/material.dart';

class FeedbackCard extends StatelessWidget {
  final String feedback;

  const FeedbackCard({super.key, required this.feedback});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          feedback,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
