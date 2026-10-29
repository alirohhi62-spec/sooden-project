import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// پنل‌های یک خانه (مکان‌هایی با همان مودم): بالای صفحه‌ی پنل، برای جابه‌جا شدن بدون شروع دوباره‌ی اپ
/// دو شکل: زبانه‌ها، یا اسم پنل با فهرست کشویی
const Color _bg = Color(0xFF15161B);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _ok = Color(0xFF7EE2AE);

class HomePanel {
  final int id;
  final String name;
  final String model;       // اسم مدل برای زیر اسم (۲۳ کلید، ۱۲ اقتصادی، ...)
  final bool online;        // روی مودم جواب می‌دهد
  final bool reachable;     // از این شبکه می‌شود به آن رسید (روی وای‌فای یک پنل: فقط همان)
  const HomePanel(this.id, this.name, this.model, {this.online = true, this.reachable = true});
}

enum SwitcherStyle { tabs, dropdown }

class PanelSwitcher extends StatelessWidget {
  final List<HomePanel> panels;
  final int current;
  final SwitcherStyle style;
  final void Function(HomePanel p) onPick;
  final String? note;       // مثلاً «گوشی به وای‌فای خود پنل وصل است؛ بقیه فقط از راه مودم خانه»

  const PanelSwitcher({super.key, required this.panels, required this.current, required this.onPick, this.style = SwitcherStyle.tabs, this.note});

  HomePanel? get _cur => panels.firstWhereOrNull((p) => p.id == current);

  Widget _dot(HomePanel p) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(shape: BoxShape.circle, color: !p.reachable ? _muted.withValues(alpha: .35) : p.online ? _ok : _red),
      );

  @override
  Widget build(BuildContext context) {
    if (panels.length < 2) return const SizedBox.shrink();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
          style == SwitcherStyle.tabs ? _tabs() : _dropdown(context),
          if (note != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(note!, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 11.5)),
            ),
        ]),
      ),
    );
  }

  Widget _tabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final p in panels)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: GestureDetector(
              key: ValueKey('switch-tab-${p.id}'),
              onTap: p.reachable && p.id != current
                  ? () {
                      HapticFeedback.selectionClick();
                      onPick(p);
                    }
                  : null,
              child: Opacity(
                opacity: p.reachable ? 1 : .45,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: p.id == current ? _red.withValues(alpha: .16) : const Color(0x0AFFFFFF),
                    border: Border.all(color: p.id == current ? _red.withValues(alpha: .8) : const Color(0x1FFFFFFF)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _dot(p),
                    const SizedBox(width: 7),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                      Text(p.name, style: TextStyle(color: p.id == current ? _text : _muted, fontSize: 13.5, fontWeight: FontWeight.w700)),
                      Text(p.model, style: const TextStyle(color: _muted, fontSize: 10.5)),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _dropdown(BuildContext context) {
    final c = _cur;
    return GestureDetector(
      key: const ValueKey('switch-title'),
      onTap: () => openList(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0x0AFFFFFF),
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Row(children: [
          if (c != null) _dot(c),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(c?.name ?? '', style: const TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
              Text('${c?.model ?? ''}، ${panels.length} پنل در این خانه', style: const TextStyle(color: _muted, fontSize: 11)),
            ]),
          ),
          const CustomPaint(size: Size(14, 9), painter: _Chevron()),
        ]),
      ),
    );
  }

  /// فهرست پنل‌های خانه (از پایین صفحه)
  void openList(BuildContext context) {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: Color(0x29FFFFFF))),
          ),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 12),
              const Text('پنل‌های این خانه', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              for (final p in panels)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: p.reachable
                        ? () {
                            Get.back();
                            if (p.id != current) onPick(p);
                          }
                        : null,
                    child: Opacity(
                      opacity: p.reachable ? 1 : .45,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: p.id == current ? _red.withValues(alpha: .10) : const Color(0x0DFFFFFF),
                          border: Border.all(color: p.id == current ? _red.withValues(alpha: .6) : const Color(0x29FFFFFF)),
                        ),
                        child: Row(children: [
                          _dot(p),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(p.name, style: const TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
                              Text(p.model, style: const TextStyle(color: _muted, fontSize: 11.5)),
                            ]),
                          ),
                          Text(
                              p.id == current
                                  ? 'همین پنل'
                                  : !p.reachable
                                      ? 'فقط از راه مودم'
                                      : p.online
                                          ? 'جواب می‌دهد'
                                          : 'جواب نمی‌دهد',
                              style: TextStyle(color: p.reachable && !p.online && p.id != current ? _red : _muted, fontSize: 11.5)),
                        ]),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// the arrow of the list (drawn: no icon font needed)
class _Chevron extends CustomPainter {
  const _Chevron();
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = _muted
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(Path()..moveTo(1, 1)..lineTo(s.width / 2, s.height - 1)..lineTo(s.width - 1, 1), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
