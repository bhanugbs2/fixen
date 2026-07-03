import 'package:hive_flutter/hive_flutter.dart';

class HiveHelper {
  static const String profileBoxName = 'profile_cache';
  static const String bookingsBoxName = 'bookings_cache';
  static const String notificationsBoxName = 'notifications_cache';
  static const String settingsBoxName = 'settings_cache';

  static Future<void> initialize() async {
    await Hive.initFlutter();
    await Hive.openBox(profileBoxName);
    await Hive.openBox(bookingsBoxName);
    await Hive.openBox(notificationsBoxName);
    await Hive.openBox(settingsBoxName);
  }

  static Future<void> cacheData(String boxName, String key, dynamic value) async {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }
    final box = Hive.box(boxName);
    await box.put(key, value);
  }

  static dynamic getCachedData(String boxName, String key, {dynamic defaultValue}) {
    if (!Hive.isBoxOpen(boxName)) {
      return defaultValue;
    }
    final box = Hive.box(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  static Future<void> clearBox(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      final box = Hive.box(boxName);
      await box.clear();
    }
  }

  static Future<void> clearAllCache() async {
    await clearBox(profileBoxName);
    await clearBox(bookingsBoxName);
    await clearBox(notificationsBoxName);
    await clearBox(settingsBoxName);
  }
}
