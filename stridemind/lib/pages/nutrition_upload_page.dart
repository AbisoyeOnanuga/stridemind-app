import 'package:flutter/material.dart';

class NutritionUploadPage extends StatefulWidget {
  const NutritionUploadPage({super.key});

  @override
  State<NutritionUploadPage> createState() => _NutritionUploadPageState();
}

class _NutritionUploadPageState extends State<NutritionUploadPage> {
  bool _isProcessing = false;
  String? _fileName;
  List<Map<String, String>>? _parsedMealPlan;

  @override
  void dispose() {
    super.dispose();
  }

  void _uploadMealPlan() async {
    // Simulate file picking. In a real app, you'd use a package like file_picker.
    setState(() {
      _isProcessing = true;
      _fileName = 'weekly_meal_plan.pdf';
      _parsedMealPlan = null;
    });

    // Simulate network upload and parsing.
    await Future.delayed(const Duration(seconds: 3));

    // Placeholder for a successfully parsed meal plan.
    final plan = [
      {
        'day': 'Monday',
        'meal':
            'Breakfast: Oatmeal, Lunch: Chicken Salad, Dinner: Salmon and Veggies'
      },
      {
        'day': 'Tuesday',
        'meal': 'Breakfast: Eggs, Lunch: Leftover Salmon, Dinner: Tacos'
      },
      {
        'day': 'Wednesday',
        'meal': 'Breakfast: Smoothie, Lunch: Quinoa Bowl, Dinner: Pasta'
      },
    ];

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _parsedMealPlan = plan;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSectionCard(
          title: 'Upload Meal Plan',
          icon: Icons.fastfood_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Upload your meal plan in PDF or Excel format. We will parse it for analysis and feedback.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _uploadMealPlan,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text('Select Meal Plan to Upload'),
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
                      Text('Processing your meal plan...'),
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
        if (_parsedMealPlan != null)
          _buildSectionCard(
            title: 'Your Parsed Meal Plan',
            icon: Icons.receipt_long_outlined,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parsedMealPlan!.length,
              itemBuilder: (context, index) {
                final item = _parsedMealPlan![index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(item['day']!.substring(0, 1)),
                  ),
                  title: Text(item['day']!),
                  subtitle: Text(item['meal']!),
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