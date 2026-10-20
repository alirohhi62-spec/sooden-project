import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'sooden_logo_data.dart';

/// موشن لوگوی سودن روی پس‌زمینه‌ی مشکی (طرح ۳: «روشن شدن خانه»):
/// اول پنجره با نور گرم روشن می‌شود، بعد خانه، مدار از بالا به پایین، نقطه‌های قرمز و در آخر وای‌فای.
class SoodenSplashLogo extends StatefulWidget {
  final double width;

  const SoodenSplashLogo({super.key, this.width = 230});

  @override
  State<SoodenSplashLogo> createState() => _SoodenSplashLogoState();
}

class _SoodenSplashLogoState extends State<SoodenSplashLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..forward();

  static const Color _white = Color(0xFFF2F2F2);
  static const Color _warm = Color(0xFFFFD27A);
  static const Color _red = Color(0xFFE5303E);

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  /// پیشرفت یک بخش بین دو لحظه‌ی [from] و [to] (۰ تا ۱ از کل زمان)
  double _p(double from, double to) => ((_a.value - from) / (to - from)).clamp(0.0, 1.0).toDouble();

  Widget _part(String key, Color color, {double opacity = 1}) => Opacity(
        opacity: opacity,
        child: SvgPicture.string(soodenLogoPart[key]!,
            width: widget.width, colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
      );

  @override
  Widget build(BuildContext context) {
    final h = widget.width * 791 / 881;
    return SizedBox(
      width: widget.width,
      height: h,
      child: AnimatedBuilder(
        animation: _a,
        builder: (context, _) {
          final halo = _p(0.05, 0.22);
          return Stack(clipBehavior: Clip.none, children: [
            // نور گرم پشت پنجره
            Positioned(
              left: widget.width * 0.30,
              top: h * 0.14,
              width: widget.width * 0.52,
              height: h * 0.48,
              child: Opacity(
                opacity: halo * (1 - 0.35 * _p(0.25, 0.6)),
                child: Transform.scale(
                  scale: 0.4 + 0.6 * halo,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color(0x8CFFC861), Color(0x00FFC861)]),
                    ),
                  ),
                ),
              ),
            ),
            _part('panes', const Color(0xFF2A2A2A)),
            _part('panes', _warm, opacity: _p(0.06, 0.14)),
            _part('house', _white, opacity: _p(0.24, 0.40)),
            // مدار: از بالا به پایین کشیده می‌شود
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _p(0.36, 0.56),
                child: _part('wire', _white),
              ),
            ),
            for (int k = 1; k <= 5; k++) _part('node$k', _red, opacity: _p(0.56 + (k - 1) * 0.03, 0.60 + (k - 1) * 0.03)),
            _part('wifi1', _white, opacity: _p(0.60, 0.66)),
            _part('wifi2', _white, opacity: _p(0.64, 0.70)),
            _part('wifi3', _white, opacity: _p(0.68, 0.74)),
          ]);
        },
      ),
    );
  }
}
