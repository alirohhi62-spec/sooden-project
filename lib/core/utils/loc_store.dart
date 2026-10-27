import 'package:get_storage/get_storage.dart';

/// مکان فعلی (منزل، ویلا، ...) و داده‌هایی که روی گوشی برای هر مکان جدا نگه داشته می‌شود
/// (شماره‌ی سیمکارت پنل، اسم کلیدهای پنل دوم، آخرین نوع پنل و ...).
/// کلیدها با شماره‌ی مکان ذخیره می‌شوند؛ مقدار قدیمی (پیش از چند مکان) فقط برای اولین مکان خوانده می‌شود.
class LocStore {
  LocStore._();

  static int? id;
  static int? firstId;               // اولین مکان: داده‌های قدیمی گوشی مال همین است
  static String name = '';

  /// مکان خودکار از روی وای‌فای فعلی گوشی انتخاب شد (برای پیام بالای صفحه)
  static bool autoPicked = false;
  static String wifiNow = '';

  static final List<void Function()> _listeners = [];

  static void listen(void Function() f) {
    if (!_listeners.contains(f)) _listeners.add(f);
  }

  static void set(int? newId, String newName) {
    final changed = newId != id;
    id = newId;
    name = newName;
    if (changed) {
      for (final f in List.of(_listeners)) {
        try {
          f();
        } catch (_) {}
      }
    }
  }

  static String key(String base) => id == null ? base : 'loc${id}_$base';

  static T? read<T>(String base) {
    try {
      final b = GetStorage();
      final v = b.read(key(base));
      if (v != null) return v as T?;
      if (id != null && firstId != null && id != firstId) return null;
      return b.read(base) as T?;
    } catch (_) {
      return null;
    }
  }

  static void write(String base, dynamic v) {
    try {
      GetStorage().write(key(base), v);
    } catch (_) {}
  }
}
