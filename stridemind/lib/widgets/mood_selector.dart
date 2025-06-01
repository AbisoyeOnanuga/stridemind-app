import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final Function(String) onMoodSelected;

  const MoodSelector({super.key, required this.onMoodSelected});

  @override
  Widget build(BuildContext context) {
    final moods = ['😄', '😊', '😐', '😔', '😢'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: moods.map((mood) {
        return GestureDetector(
          onTap: () => onMoodSelected(mood),
          child: Text(
            mood,
            style: const TextStyle(fontSize: 32),
          ),
        );
      }).toList(),
    );
  }
}
