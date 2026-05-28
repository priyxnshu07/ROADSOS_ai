import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/accident_report.dart';

class HistoryService {
  static const String _historyKey = 'roadsos_history';
  static const int _maxHistory = 5;

  Future<List<AccidentReport>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString(_historyKey);
    if (historyJson == null) return [];
    
    final List<dynamic> decoded = jsonDecode(historyJson);
    return decoded.map((h) => AccidentReport.fromJson(h)).toList();
  }

  Future<void> saveReport(AccidentReport report) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AccidentReport> currentHistory = await getHistory();
    
    // Add new report at the beginning
    currentHistory.insert(0, report);
    
    // Keep only the latest _maxHistory items
    if (currentHistory.length > _maxHistory) {
      currentHistory.removeRange(_maxHistory, currentHistory.length);
    }
    
    final String encoded = jsonEncode(currentHistory.map((h) => h.toJson()).toList());
    await prefs.setString(_historyKey, encoded);
  }

  Future<void> deleteReport(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final List<AccidentReport> currentHistory = await getHistory();
    
    if (index >= 0 && index < currentHistory.length) {
      currentHistory.removeAt(index);
      final String encoded = jsonEncode(currentHistory.map((h) => h.toJson()).toList());
      await prefs.setString(_historyKey, encoded);
    }
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}
