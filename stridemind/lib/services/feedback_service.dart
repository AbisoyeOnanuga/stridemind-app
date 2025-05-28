import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class FeedbackService {
  final GenerativeModel _model;

  FeedbackService()
      : _model = GenerativeModel(
          // For 'gemini-pro', use `model: 'gemini-pro'`
          model: 'gemini-1.5-flash-latest',
          apiKey: dotenv.env['GEMINI_API_KEY']!,
        );

  Future<String> getFeedback(String prompt) async {
    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);
      return response.text ?? "Sorry, I couldn't generate feedback right now.";
    } catch (e) {
      // Handle API errors
      return "Error generating feedback: ${e.toString()}";
    }
  }
}