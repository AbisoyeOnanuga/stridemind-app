import 'package:flutter/material.dart';

class TrainingUploadPage extends StatefulWidget {
  const TrainingUploadPage({super.key});

  @override
  State<TrainingUploadPage> createState() => _TrainingUploadPageState();
}

class _TrainingUploadPageState extends State<TrainingUploadPage> {
  bool _isProcessing = false;
  String? _fileName;
  List<Map<String, String>>? _parsedPlan;

  void _uploadPlan() async {
    // Simulate file picking. In a real app, you'd use a package like file_picker.
    setState(() {
      _isProcessing = true;
      _fileName = 'my_marathon_plan.pdf';
      _parsedPlan = null;
    });

    // Simulate network upload and parsing.
    await Future.delayed(const Duration(seconds: 3));

    // Placeholder for a successfully parsed plan.
    final plan = [
      {'date': 'Mon, Oct 23', 'activity': 'Rest or cross-train'},
      {'date': 'Tue, Oct 24', 'activity': '5km Easy Run'},
      {'date': 'Wed, Oct 25', 'activity': 'Intervals: 6x800m @ 5k pace'},
      {'date': 'Thu, Oct 26', 'activity': '5km Easy Run'},
      {'date': 'Fri, Oct 27', 'activity': 'Rest'},
      {'date': 'Sat, Oct 28', 'activity': '10km Long, Slow Run'},
      {'date': 'Sun, Oct 29', 'activity': 'Rest'},
    ];

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _parsedPlan = plan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          title: 'Upload Plan',
          icon: Icons.upload_file,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload your training plan in PDF or Excel format. We will parse it and match it to your calendar.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _uploadPlan,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Select Plan to Upload'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Processing your plan...'),
                    ],
                  ),
                ),
              if (_fileName != null && !_isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green),
                    label: Text('$_fileName uploaded successfully!'),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_parsedPlan != null)
          _buildSectionCard(
            title: 'Your Parsed Plan',
            icon: Icons.calendar_today,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parsedPlan!.length,
              itemBuilder: (context, index) {
                final item = _parsedPlan![index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(item['date']!.substring(0, 3)),
                  ),
                  title: Text(item['activity']!),
                  subtitle: Text(item['date']!),
                );
              },
              separatorBuilder: (context, index) => const Divider(),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionCard(
      {required String title, required IconData icon, required Widget child}) {
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
}