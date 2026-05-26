import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-flash-latest', // Verified working model name
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.1,
        maxOutputTokens: 1000,
        responseMimeType: 'application/json',
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  Future<Map<String, dynamic>> analyzeSeverity({
    required List<int> imageBytes,
    required String description,
  }) async {
    final prompt = """
You are an emergency medical AI assistant. Analyze this road accident. 
Description: $description

Return a JSON object with:
{
  "severity": "MINOR" | "MODERATE" | "CRITICAL",
  "injuries_likely": "string",
  "recommended_action": "string",
  "ambulance_needed": true | false
}
""";

    try {
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', Uint8List.fromList(imageBytes)),
        ])
      ];

      final response = await _model.generateContent(content);
      
      if (response.text == null) {
        throw Exception('AI returned no response. Check safety filters or image visibility.');
      }

      // Sanitize response just in case
      String cleanText = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return jsonDecode(cleanText);
    } catch (e) {
      throw Exception('Analysis JSON Error: $e');
    }
  }

  Future<List<String>> getEmergencyGuidance(String severity) async {
    final prompt = """
Provide 5-6 first aid steps for a $severity road accident.
Return as a JSON array of strings ONLY.
Example: ["Step 1", "Step 2"]
""";

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      
      if (response.text == null) {
        throw Exception('AI returned no guidance.');
      }

      String cleanText = response.text!.replaceAll('```json', '').replaceAll('```', '').trim();
      return List<String>.from(jsonDecode(cleanText));
    } catch (e) {
      throw Exception('Guidance JSON Error: $e');
    }
  }
}
