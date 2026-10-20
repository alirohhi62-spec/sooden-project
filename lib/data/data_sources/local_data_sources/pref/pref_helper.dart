import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class PrefHelper {
  static final box = GetStorage();

  static const String userDisplayName = 'user_display_name';

  static put(String key, dynamic value) {
    return box.write(key, value);
  }

  static dynamic get(String key) {
    return box.read(key);
  }

  static String getString(String key, {String defaultValue = ''}) {
    var res = box.read(key);
    if (res != null && res is String) {
      return res;
    }
    return defaultValue;
  }

  static dynamic getBool(String key, {bool defaultValue = false}) {
    var res = box.read(key);
    if (res != null && res is bool) {
      return res;
    }
    return defaultValue;
  }

  static dynamic getInt(String key, {int defaultValue = 0}) {
    var res = box.read(key);
    if (res != null && res is int) {
      return res;
    }
    return defaultValue;
  }

  static dynamic getJson(key) {
    String? jsonString = get(key);
    return jsonString != null ? jsonDecode(jsonString) : null;
  }

  static dynamic putJson(key, val) {
    var valString = jsonEncode(val);
    return put("$key", valString);
  }

  static remove(String key) {
    box.remove(key);
  }
}
