import 'package:flutter/material.dart';

class JournalEntry extends StatelessWidget {
  final TextEditingController controller;

  const JournalEntry({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 5,
      decoration: const InputDecoration(
        labelText: 'Write about your workout...',
        border: OutlineInputBorder(),
      ),
    );
  }
}
