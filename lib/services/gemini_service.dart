import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'cache_service.dart';

class GeminiService {
  final _cache = CacheService();

  String get apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
    }
    return key;
  }

  GeminiService();

  // Helper to generate content with automatic failover for 503 High Demand errors
  Future<GenerateContentResponse> _generateWithRetry(List<Content> content) async {
    final modelsToTry = [
      'gemini-2.5-flash',
      'gemini-2.0-flash',
      'gemini-flash-latest',
    ];

    for (int i = 0; i < modelsToTry.length; i++) {
      try {
        final model = GenerativeModel(
          model: modelsToTry[i],
          apiKey: apiKey,
          generationConfig: GenerationConfig(
            temperature: 0.0,
            maxOutputTokens: 8192, // Maximum allowed to guarantee no truncation
          ),
          safetySettings: [
            SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
            SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          ],
        );
        return await model.generateContent(content);
      } catch (e) {
        if (i == modelsToTry.length - 1) {
          rethrow; // All models failed, throw the final error
        }
        print('Gemini API Error with ${modelsToTry[i]}: $e. Retrying with ${modelsToTry[i+1]}...');
      }
    }
    throw Exception('All AI models are currently overloaded.');
  }

  // Helper to extract JSON from conversational text
  String _extractJson(String text) {
    String clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    try {
      jsonDecode(clean); // If it parses, it's valid
      return clean;
    } catch (_) {}

    int start = clean.indexOf('{');
    int end = clean.lastIndexOf('}');
    
    if (start != -1 && end != -1 && end > start) {
      return clean.substring(start, end + 1);
    }
    
    start = clean.indexOf('[');
    end = clean.lastIndexOf(']');
    
    if (start != -1 && end != -1 && end > start) {
      return clean.substring(start, end + 1);
    }
    
    return clean;
  }

  // PROMPT 1: Severity Analysis & Guidance (Combined for Ultra-Speed)
  Future<Map<String, dynamic>> analyzeSeverity({
    required Uint8List imageBytes,
    required String description,
  }) async {
    // CACHE CHECK
    final cacheKey = 'gemini_triage_v4_${description.hashCode}_${imageBytes.length}';
    final cached = await _cache.get(cacheKey);
    if (cached != null) return Map<String, dynamic>.from(cached);

    const prompt = """
You are an expert emergency medical AI. Analyze this road accident scene based on the image and description.
Provide a detailed but urgent assessment.

Return your analysis strictly in this JSON format:
{
  "severity": "MINOR"|"MODERATE"|"CRITICAL",
  "summary": "A 2-3 sentence professional summary of the visible damage and hazards.",
  "injuries_likely": "Describe the probable types of injuries.",
  "ambulance_needed": true|false,
  "guidance": [
    "Step 1: Specific first aid action and WHY it is important.",
    "Step 2: Specific first aid action and WHY it is important.",
    "Step 3: Specific first aid action and WHY it is important."
  ]
}
Description: """;

    try {
      final content = [
        Content.multi([
          TextPart('$prompt $description'),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _generateWithRetry(content);
      final cleanJson = _extractJson(response.text ?? '{}');
      final result = jsonDecode(cleanJson);
      
      // Ensure aiSummary falls back to summary if needed
      result['injuries_likely'] = result['injuries_likely'] ?? result['summary'];
      
      await _cache.set(cacheKey, result); // Save to cache
      return result;
    } catch (e) {
      throw Exception('Triage Error: $e');
    }
  }

  // PROMPT 2: First Aid Guidance (Actionable Steps)
  Future<List<String>> getEmergencyGuidance(String severity) async {
    final cacheKey = 'guidance_$severity';
    final cached = await _cache.get(cacheKey);
    if (cached != null) return List<String>.from(cached);

    final prompt = """
You are guiding a bystander through a $severity road accident.
Provide 4-5 highly specific, actionable, and life-saving first aid or scene management steps.
Explain briefly *why* each step is important.

Return ONLY a JSON ARRAY of strings. Do not use markdown blocks outside the array.
Example format:
[
  "Check for breathing and pulse: Look, listen, and feel to determine if CPR is immediately required.",
  "Apply firm, direct pressure to any bleeding wounds using a clean cloth to prevent severe blood loss."
]
""";

    try {
      final response = await _generateWithRetry([Content.text(prompt)]);
      final cleanJson = _extractJson(response.text ?? '[]');
      final result = List<String>.from(jsonDecode(cleanJson));
      
      await _cache.set(cacheKey, result);
      return result;
    } catch (e) {
      throw Exception('Guidance Error: $e');
    }
  }

  // PROMPT 3: What NOT to do (Danger Prevention)
  Future<List<String>> getDangerWarnings(String severity) async {
    final cacheKey = 'warnings_$severity';
    final cached = await _cache.get(cacheKey);
    if (cached != null) return List<String>.from(cached);

    final prompt = """
For a $severity road accident, bystanders often make critical mistakes that worsen injuries.
Identify 3-4 dangerous actions they MUST avoid, and briefly explain the medical reason why.

Return ONLY a JSON ARRAY of strings.
Example format:
[
  "DO NOT move the victim unless they are in immediate, life-threatening danger (like fire), as this can worsen spinal injuries.",
  "DO NOT remove a motorcyclist's helmet, as this requires specialized training and can cause severe neck trauma."
]
""";

    try {
      final response = await _generateWithRetry([Content.text(prompt)]);
      final cleanJson = _extractJson(response.text ?? '[]');
      final result = List<String>.from(jsonDecode(cleanJson));
      
      await _cache.set(cacheKey, result);
      return result;
    } catch (e) {
      throw Exception('Warning Error: $e');
    }
  }
}
