import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'sooden_icons_data.dart';

/// آیکون‌های پنل سودن.
/// همه‌ی آیکون‌ها از فایل اصلی (aykon.cdr) استخراج شده‌اند، به‌جز آسانسور که در آن فایل نبود.
class PanelIcons {
  PanelIcons._();

  /// آیکون پیش‌فرض برای هر «نوع دستگاه» که پنل اعلام می‌کند
  static const Map<String, String> _defaultForType = {
    'a': '16', 'b': '35', 'c': '34', 'd': '13', 'e': '23', 'f': '12', 'g': '01', 'h': '15',
    'i': '27', 'k': '05', 'l': '17', 'm': '00', 'p': '07', 'q': '47', 's': '03',
  };

  // آسانسور در فایل آیکون‌ها نبود؛ نسخه‌ی موقت تا رسیدن آیکون اصلی
  static const String _elevator =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" '
      'stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round">'
      '<rect x="5" y="3" width="14" height="18" rx="1"/><path d="M5 7h14"/><path d="M9 9.5h4v11.5"/>'
      '<path d="M11 9.5v11.5"/><path d="M16.5 11l.8-1 .8 1"/><path d="M16.5 14l.8 1 .8-1"/></svg>';

  /// همه‌ی آیکون‌هایی که نصاب می‌تواند انتخاب کند
  static List<String> get choices => soodenIconOrder;

  static String nameOf(String id) => soodenIconName[id] ?? '';

  /// آیکون پیش‌فرض یک پل بر اساس نوع اعلامی پنل
  static String forType(String type) => _defaultForType[type] ?? '16';

  /// نوع دستگاه متناظر با یک آیکون (برای Line#)
  static String typeOf(String id) => soodenIconType[id] ?? 'a';

  static String _svg(String key) {
    switch (key) {
      case 'elevator':
        return _elevator;
      case 'master':
        return soodenIconSvg['10']!;
      case 'exit':
        return soodenIconSvg['20']!;
      case 'po':
      case 'pc':
        return soodenIconSvg['07']!;
    }
    return soodenIconSvg[key] ?? soodenIconSvg['16']!;
  }

  static Widget icon(String key, Color color, double size) {
    // SizedBox: اندازه‌ی آیکون همیشه مشخص است (برای IntrinsicHeight و چیدمان‌های دیگر)
    return SizedBox(
      width: size,
      height: size,
      child: SvgPicture.string(
        _svg(key),
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
