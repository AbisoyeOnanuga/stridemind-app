import 'package:flutter/material.dart';
import '../widgets/mood_selector.dart';
import '../widgets/journal_entry.dart';
import '../widgets/feedback_card.dart';
import './dashboard_page.dart';

class MoodLoggerPage extends StatefulWidget {
  const MoodLoggerPage({super.key});

  @override
  State<MoodLoggerPage> createState() => _MoodLoggerPageState();
}

class _MoodLoggerPageState extends State<MoodLoggerPage> {
  String? selectedMood;
  final TextEditingController journalController = TextEditingController();
  String? feedback;

  void submitLog() {
    final mood = selectedMood ?? '😐';
    final journal = journalController.text;

    // Simulate AI feedback
    setState(() {
      feedback = generateMockFeedback(mood, journal);
    });
  }

  String generateMockFeedback(String mood, String journal) {
    if (mood == '😄' && journal.contains('energized')) {
      return "You're thriving after these workouts! Keep up the momentum.";
    } else if (mood == '😢' || journal.contains('pain')) {
      return "It looks like something’s off. Consider a rest day or adjusting intensity.";
    } else {
      return "Thanks for logging. Keep tracking to uncover deeper patterns.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Your Mood')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('How did this workout make you feel?', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            MoodSelector(onMoodSelected: (mood) {
              setState(() {
                selectedMood = mood;
              });
            }),
            const SizedBox(height: 24),
            JournalEntry(controller: journalController),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitLog,
              child: const Text('Submit'),
            ),
            const SizedBox(height: 24),
            if (feedback != null) ...[
            const SizedBox(height: 24),
            FeedbackCard(feedback: feedback!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              },
              child: const Text('View Dashboard'),
            ),
          ],
          ],
        ),
      ),
    );
  }
}
