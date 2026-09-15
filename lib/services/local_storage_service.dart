import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  final SharedPreferences prefs;

  LocalStorageService(this.prefs);

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  Future<void> saveString(String key, String value) async =>
      prefs.setString(key, value);

  String? getString(String key) => prefs.getString(key);

  Future<void> saveBool(String key, bool value) async =>
      prefs.setBool(key, value);

  bool? getBool(String key) => prefs.getBool(key);

  Future<void> saveDouble(String key, double value) async =>
      prefs.setDouble(key, value);

  double? getDouble(String key) => prefs.getDouble(key);

  Future<void> saveInt(String key, int value) async =>
      prefs.setInt(key, value);

  int? getInt(String key) => prefs.getInt(key);

  Future<void> saveStringList(String key, List<String> value) async =>
      prefs.setStringList(key, value);

  List<String>? getStringList(String key) => prefs.getStringList(key);

  Future<void> clear() async => prefs.clear();

  Future<void> remove(String key) async => prefs.remove(key);

  // ✅ دوال جديدة للإشعارات
  Future<void> setLastReadNotificationTime(DateTime time) async {
    await prefs.setString('last_read_notification_time', time.toIso8601String());
  }

  DateTime? getLastReadNotificationTime() {
    final timeStr = prefs.getString('last_read_notification_time');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }
}
