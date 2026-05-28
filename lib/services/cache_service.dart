import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _keyPrefix = 'roadsos_cache_v3_';
  static const Duration _defaultTTL = Duration(hours: 24);

  /// Saves data to cache with a timestamp
  Future<void> set(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheData = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'content': data,
    };
    await prefs.setString(_keyPrefix + key, jsonEncode(cacheData));
  }

  /// Retrieves data if it exists and is not expired
  Future<dynamic> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedString = prefs.getString(_keyPrefix + key);
    
    if (cachedString == null) return null;

    final cachedMap = jsonDecode(cachedString);
    final timestamp = cachedMap['timestamp'] as int;
    final content = cachedMap['content'];

    // Check if expired (24 hours)
    if (DateTime.now().millisecondsSinceEpoch - timestamp > _defaultTTL.inMilliseconds) {
      await prefs.remove(_keyPrefix + key);
      return null;
    }

    return content;
  }

  /// Specialized key generator for coordinates (rounds to 4 decimals ~11m precision)
  String getCoordsKey(double lat, double lng, String type) {
    return 'map_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}_$type';
  }
}
