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
      if (b.read(_moved) == true) return null;                 // the old data already belongs to the first location
      if (id != null && firstId != null && id != firstId) return null;
      return b.read(base) as T?;
    } catch (_) {
      return null;
    }
  }

  static const String _moved = 'loc_legacy_moved';

  /// داده‌های قدیمی گوشی (پیش از چند مکان، بدون شماره‌ی مکان) یک بار مال اولین مکان می‌شوند؛
  /// بعد از آن هیچ مکانی چیزی از آن‌ها به ارث نمی‌برد (مثلاً «آخرین پنل سیمکارتی بود»)
  static void moveLegacy() {
    try {
      final b = GetStorage();
      if (b.read(_moved) == true || firstId == null) return;
      for (final k in List<String>.from(b.getKeys<Iterable<String>>())) {
        if (k.startsWith('loc') && RegExp(r'^loc\d+_').hasMatch(k)) continue;
        if (k.startsWith('home_') || k == _moved) continue;
        final dst = 'loc${firstId}_$k';
        if (b.read(dst) == null) b.write(dst, b.read(k));
      }
      b.write(_moved, true);
    } catch (_) {}
  }

  /// داده‌ی یک مکان مشخص (نه لزوماً مکان فعلی)
  static T? readFor<T>(int? locId, String base) {
    try {
      return GetStorage().read(locId == null ? base : 'loc${locId}_$base') as T?;
    } catch (_) {
      return null;
    }
  }

  static void writeFor(int? locId, String base, dynamic v) {
    try {
      GetStorage().write(locId == null ? base : 'loc${locId}_$base', v);
    } catch (_) {}
  }

  /// این اتصال از کدام راه است: 'panel' وای‌فای خود پنل، 'modem' وای‌فای مودم همان مکان، 'static' از بیرون (آی‌پی استاتیک)
  static String via = '';

  static void write(String base, dynamic v) {
    try {
      GetStorage().write(key(base), v);
    } catch (_) {}
  }
}
