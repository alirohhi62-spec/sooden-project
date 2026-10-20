import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import 'panel12_controller.dart';
import 'panel12_icons.dart';
import '../sd23/sd23_screen.dart';

// ---------- رنگ‌های تم تیره‌ی بلوری ----------
const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _ok = Color(0xFF7EE2AE);
const Color _off = Color(0xEBF6F7F9);

BoxDecoration _glass({double radius = 28}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x21FFFFFF), Color(0x0AFFFFFF), Color(0x05FFFFFF), Color(0x12FFFFFF)],
        stops: [0, .38, .62, 1],
      ),
      border: Border.all(color: const Color(0x29FFFFFF)),
      boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 40, offset: Offset(0, 20), spreadRadius: -20)],
    );

/// ظاهر یک کلید بر اساس رنگ فعلی (null = خاموش)
class _Look {
  final Color fg;
  final Color? lit;
  final bool ready;

  _Look(this.lit, {this.ready = false}) : fg = lit ?? _off;

  BoxDecoration box(double radius) => BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: lit != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lit!.withValues(alpha: .20), lit!.withValues(alpha: .06)],
              )
            : null,
        color: lit == null ? (ready ? const Color(0x17FFFFFF) : const Color(0x09FFFFFF)) : null,
        border: Border.all(
            color: lit != null
                ? lit!.withValues(alpha: .6)
                : (ready ? _amber.withValues(alpha: .55) : const Color(0x14FFFFFF))),
        boxShadow: lit != null ? [BoxShadow(color: lit!.withValues(alpha: .27), blurRadius: 22)] : null,
      );

  List<Shadow>? get glow => lit != null ? [Shadow(color: lit!.withValues(alpha: .6), blurRadius: 8)] : null;
}

/// یک خانه‌ی پنل
class _Slot {
  final String kind; // light ، open ، close
  final int index; // شماره‌ی پل (۰ تا ۹) یا شماره‌ی متن (۱۰ و ۱۱ برای پرده)
  const _Slot(this.kind, this.index);
}

const List<_Slot> _leftSlots = [
  _Slot('light', 0), _Slot('light', 2), _Slot('light', 4), _Slot('light', 6), _Slot('light', 8), _Slot('open', 10),
];
const List<_Slot> _rightSlots = [
  _Slot('light', 1), _Slot('light', 3), _Slot('light', 5), _Slot('light', 7), _Slot('light', 9), _Slot('close', 11),
];

/// محتوای تب خانه: برای پنل‌های RF-12 صفحه‌ی آینه‌ی پنل، وگرنه صفحه‌ی قدیمی.
/// صفحه‌ی قدیمی پنهان می‌ماند ولی فعال است چون اتصال را مدیریت می‌کند.
/// StackFit.expand لازم است: صفحه‌ی پنهان اندازه‌ی صفر دارد و بدون آن صفحه‌ی پنل هم صفر می‌شد.
/// این ترکیب در test/panel12_test.dart بررسی می‌شود.
class Panel12TabHost extends StatelessWidget {
  final Widget home;

  const Panel12TabHost({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = Panel12Controller.instance;
      // تا نوع پنل معلوم نشده: اگر آخرین بار پنل RF-12 بود همان صفحه‌ی پنل، وگرنه صفحه‌ی تیره (نه صفحه‌ی قدیمی)
      final known = c.modelKnown.value;
      // پنل ۲۳ کلید: صفحه‌ی مخصوص همان پنل
      final sd = c.isSd23.value || (!known && c.lastSd23.value);
      final showPanel = !sd && (c.isRf12.value || (!known && c.lastRf12.value));
      final showOld = known && !c.isRf12.value && !c.isSd23.value;
      return Stack(fit: StackFit.expand, children: [
        Offstage(offstage: !showOld, child: home),
        if (sd) const Sd23Screen(),
        if (showPanel) const Panel12Screen(),
        if (showPanel || sd) const Panel12Overlay(),
        if (!showPanel && !showOld && !sd) const ColoredBox(color: _bg),
      ]);
    });
  }
}

/// روی همه‌ی صفحه‌های پنل RF-12:
/// - وقتی اتصال قطع است، صفحه کم‌رنگ می‌شود و لمس‌ها گرفته نمی‌شوند (وضعیت ممکن است قدیمی باشد)
/// - پیام نتیجه‌ی فرمان‌ها (فقط بر اساس جواب پنل)
class Panel12Overlay extends StatelessWidget {
  const Panel12Overlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final c = Panel12Controller.instance;
      final keeper = ConnectionKeeper.instance;
      final lost = !c.demo.value && keeper.hasSession && keeper.state.value != LinkState.connected;
      final text = c.notice.value;
      final type = c.noticeType.value;
      final color = type == 'err' ? const Color(0xFFFF7A86) : (type == 'ok' ? _ok : _amber);
      return Stack(fit: StackFit.expand, children: [
        if (lost)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: const Color(0xB30B0C10),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(32),
                child: const Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                      width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB547))),
                  SizedBox(height: 14),
                  Text('اتصال با پنل قطع است',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFF2F4F7), fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('وضعیت نمایش‌داده‌شده ممکن است قدیمی باشد؛ فرمانی ارسال نمی‌شود تا اتصال برقرار شود',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0xB8F2F4F7), fontSize: 12, height: 1.6)),
                ]),
              ),
            ),
          ),
        if (text.isNotEmpty)
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xF21A1B21),
                  border: Border.all(color: color.withValues(alpha: .7)),
                ),
                child: Text(text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ]);
    });
  }
}

class Panel12Screen extends StatelessWidget {
  const Panel12Screen({super.key});

  Panel12Controller get c => Panel12Controller.instance;

  // ---------- داده‌ی هر خانه ----------

  String _keyTitle(_Slot s) {
    final n = 'کلید ${Panel12Controller.faNum(s.index + 1)}';
    if (s.kind == 'open') return '$n (پرده باز)';
    if (s.kind == 'close') return '$n (پرده بسته)';
    return n;
  }

  String _label(_Slot s) => c.labelOf(s.index);

  String _iconKey(_Slot s) => c.iconOf(s.index);

  Color? _litOf(_Slot s) {
    // پیش‌نمایش برنامه‌ی مسافرت روی تصویر پنل
    final pv = c.previewLights.value;
    final pc = c.previewCurtain.value;
    final curtain = pc.isNotEmpty ? pc : c.curtainState.value;
    if (s.kind == 'open') return curtain == 'O' ? _red : null;
    if (s.kind == 'close') return curtain == 'C' ? _red : null;
    if (pv != null) return pv[s.index] ? _red : null;
    return c.lights[s.index] ? _red : null;
  }

  void _tap(_Slot s) {
    HapticFeedback.lightImpact();
    if (c.installer.value) {
      _editSheet(s);
      return;
    }
    if (s.kind == 'open') {
      c.curtain(true);
    } else if (s.kind == 'close') {
      c.curtain(false);
    } else {
      c.toggleLight(s.index);
    }
  }

  // ---------- صفحه ----------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Stack(
        children: [
          // نور پشت شیشه: هر چه چراغ بیشتری روشن باشد، قرمزتر
          Positioned(
            left: -120,
            top: 40,
            child: Obx(() {
              final a = (0.12 + c.lightsOn * 0.05).clamp(0.0, 0.55).toDouble();
              return _glowCircle(360, _red.withValues(alpha: a));
            }),
          ),
          Positioned(right: -140, top: 420, child: _glowCircle(380, const Color(0x474660FF))),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _header(context),
                miniPanel(),
                Expanded(child: _zoneView()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
          ),
        ),
      );

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: () => _askInstallerPin(context),
            child: const Text('پذیرایی', style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700)),
          ),
          const Spacer(),
          Obx(() {
            if (c.installer.value) {
              return GestureDetector(
                onTap: () => c.installer.value = false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: _glass(radius: 999).copyWith(border: Border.all(color: _amber)),
                  child: const Text('حالت نصاب  ✕', style: TextStyle(color: _amber, fontSize: 12)),
                ),
              );
            }
            if (c.demo.value) {
              return GestureDetector(
                onTap: () => Get.back(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: _glass(radius: 999).copyWith(border: Border.all(color: const Color(0xFF7FD3FF))),
                  child: const Text('حالت نمایشی  ✕', style: TextStyle(color: Color(0xFF7FD3FF), fontSize: 12)),
                ),
              );
            }
            final online = ConnectionKeeper.instance.state.value == LinkState.connected;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: _glass(radius: 999),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: online ? _ok : _amber),
                ),
                const SizedBox(width: 6),
                Text(online ? 'آنلاین' : 'در حال اتصال',
                    style: TextStyle(color: online ? _ok : _amber, fontSize: 12)),
              ]),
            );
          }),
        ],
      ),
    );
  }

  // ---------- تصویر کامل پنل (بالا) ----------

  /// تصویر کامل پنل؛ در صفحه‌ی سناریو با zones: false (لمس بخش‌ها کاری نمی‌کند)
  Widget miniPanel({bool zones = true}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: _glass(radius: 22),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xD9FFFFFF), width: 1.5),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x8C363436), Color(0x8C141416)],
            ),
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            // IntrinsicHeight: هر سه بخش هم‌قد می‌شوند بدون اینکه ارتفاع نامحدود بخواهند
            // (قبلاً stretch در ارتفاع نامحدود باعث خالی ماندن کل صفحه می‌شد)
            child: Obx(() => IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                          flex: 2,
                          child: _miniZone(0, zones,
                              Column(mainAxisSize: MainAxisSize.min, children: _leftSlots.map(_miniSlot).toList()))),
                      const SizedBox(width: 6),
                      Expanded(flex: 3, child: _miniZone(1, zones, _miniCenter())),
                      const SizedBox(width: 6),
                      Expanded(
                          flex: 2,
                          child: _miniZone(2, zones,
                              Column(mainAxisSize: MainAxisSize.min, children: _rightSlots.map(_miniSlot).toList()))),
                    ],
                  ),
                )),
          ),
        ),
      ),
    );
  }

  Widget _miniZone(int z, bool zones, Widget child) {
    final touched = c.touchedZone.value == z;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: zones ? () => c.selectZone(z) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: touched ? const Color(0x14FFFFFF) : Colors.transparent,
          border: Border.all(color: touched ? const Color(0xBFFFFFFF) : Colors.transparent, width: 1.5),
        ),
        child: child,
      ),
    );
  }

  Widget _miniSlot(_Slot s) {
    final look = _Look(_litOf(s));
    // آیکون و نوشته‌ی هر کلید به هم چسبیده؛ فاصله‌ی بین کلیدها بیشتر (مثل شیشه‌ی پنل)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PanelIcons.icon(_iconKey(s), look.fg, 16),
          Text(_label(s),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: look.fg, fontSize: 7.5, height: 1.0, fontWeight: FontWeight.w600, shadows: look.glow)),
        ],
      ),
    );
  }

  Widget _miniText(String text, Color? lit, double size) {
    final look = _Look(lit);
    return SizedBox(
      height: 22,
      child: Center(
        child: Text(text,
            style: TextStyle(color: look.fg, fontSize: size, fontWeight: FontWeight.w600, shadows: look.glow)),
      ),
    );
  }

  Widget _miniCenter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: [
          Expanded(child: _miniText('ON / OFF', _onOffColor(), 7.5)),
          Expanded(child: _miniText('change pass', c.entry.value == 'new' ? _amber : null, 7.5)),
        ]),
        for (int r = 0; r < 3; r++)
          Row(children: [
            Expanded(child: _miniText('${r * 2 + 1}', _digitColor(r * 2 + 1), 12)),
            Expanded(child: _miniText('${r * 2 + 2}', _digitColor(r * 2 + 2), 12)),
          ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: _miniIcon('', 'Master', _masterColor())),
          Expanded(child: _miniIcon('elevator', 'Elevator', c.flashing.contains('elevator') ? _red : null)),
          Expanded(child: _miniIcon('', 'Exit', c.flashing.contains('exit') ? _red : null)),
        ]),
      ],
    );
  }

  Widget _miniIcon(String key, String label, Color? lit) {
    final look = _Look(lit);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      // بدون آیکون: فقط جای آیکون خالی می‌ماند تا نوشته هم‌راستای Elevator باشد
      key.isEmpty ? const SizedBox(height: 13) : PanelIcons.icon(key, look.fg, 13),
      Text(label, style: TextStyle(color: look.fg, fontSize: 7, fontWeight: FontWeight.w600, shadows: look.glow)),
    ]);
  }

  Color? _onOffColor() => c.entry.value == 'arm' ? _amber : (c.armed.value ? _red : null);

  Color? _digitColor(int d) => c.flashing.contains('d$d') ? _red : null;

  Color? _masterColor() =>
      (c.flashing.contains('master') || c.lights.every((e) => e)) ? _red : null;

  // ---------- بخش بزرگ (پایین) ----------

  Widget _zoneView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _glass(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Obx(() {
            switch (c.zone.value) {
              case 1:
                return _centerZone();
              case 2:
                return _columnZone(_rightSlots);
              default:
                return _columnZone(_leftSlots);
            }
          }),
        ),
      ),
    );
  }

  Widget _columnZone(List<_Slot> slots) {
    return Column(
      children: [
        for (int i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Expanded(child: _rowKey(slots[i])),
        ],
      ],
    );
  }

  Widget _rowKey(_Slot s) {
    final look = _Look(_litOf(s));
    final isCurtain = s.kind != 'light';
    final double closed = isCurtain ? c.curtainClosed.value.clamp(0.0, 1.0).toDouble() : 0.0;
    return GestureDetector(
      onTap: () => _tap(s),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: look.box(18),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          if (isCurtain) ...[
            // پارچه‌ی پرده از دو طرف کاشی، هم‌پای پرده‌ی واقعی
            Positioned.fill(
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(widthFactor: closed * 0.5, heightFactor: 1, child: _fabric()))),
            Positioned.fill(
                child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(widthFactor: closed * 0.5, heightFactor: 1, child: _fabric()))),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
          children: [
            PanelIcons.icon(_iconKey(s), look.fg, 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(s),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: look.fg, fontSize: 15, fontWeight: FontWeight.w600, shadows: look.glow)),
                  if (isCurtain) ...[
                    const SizedBox(height: 3),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(_curtainText(closed),
                          style: TextStyle(color: look.lit ?? _muted, fontSize: 11.5, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ],
              ),
            ),
            if (c.installer.value)
              const Icon(Icons.edit, color: _amber, size: 18)
            else
              Container(
                width: 6,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: look.lit ?? _off,
                  boxShadow: [
                    BoxShadow(color: (look.lit ?? _off).withValues(alpha: look.lit != null ? .8 : .3), blurRadius: 10)
                  ],
                ),
              ),
          ],
        ),
          ),
        ]),
      ),
    );
  }

  Widget _fabric() => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-1, 0),
            end: Alignment(-0.93, 0),
            colors: [Color(0x26FFFFFF), Color(0x26FFFFFF), Color(0x0AFFFFFF), Color(0x0AFFFFFF)],
            stops: [0, .5, .5, 1],
            tileMode: TileMode.repeated,
          ),
        ),
      );

  String _curtainText(double closed) {
    final pct = Panel12Controller.faNum((closed * 100).round());
    switch (c.curtainState.value) {
      case 'C':
        return 'در حال بسته شدن • $pct٪';
      case 'O':
        return 'در حال باز شدن • $pct٪';
    }
    if (closed <= 0.01) return 'کاملاً باز';
    if (closed >= 0.99) return 'کاملاً بسته';
    return 'ایستاده • $pct٪ بسته';
  }

  Widget _centerKey(String text, Color? lit,
      {double size = 15, VoidCallback? onTap, bool ready = false, String? icon, Widget? custom}) {
    final look = _Look(lit, ready: ready);
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: look.box(18),
        child: Center(
          child: icon == null
              ? Text(text,
                  style:
                      TextStyle(color: look.fg, fontSize: size, fontWeight: FontWeight.w600, shadows: look.glow))
              : Column(mainAxisSize: MainAxisSize.min, children: [
                  icon.isEmpty ? const SizedBox(height: 26) : PanelIcons.icon(icon, look.fg, 26),
                  const SizedBox(height: 4),
                  Text(text,
                      style:
                          TextStyle(color: look.fg, fontSize: 13, fontWeight: FontWeight.w600, shadows: look.glow)),
                ]),
        ),
      ),
    );
  }

  Widget _centerZone() {
    final entering = c.entry.value.isNotEmpty;
    Widget row(List<Widget> kids, {int flex = 1}) => Expanded(
          flex: flex,
          child: Row(children: [
            for (int i = 0; i < kids.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: kids[i]),
            ],
          ]),
        );

    final passKey = Listener(
      onPointerDown: (_) => c.passDown(),
      onPointerUp: (_) => c.passUp(),
      onPointerCancel: (_) => c.passUp(),
      child: _centerKey('change pass', c.entry.value == 'new' ? _amber : null),
    );

    return Column(
      children: [
        row([_centerKey('ON / OFF', _onOffColor(), onTap: c.onOff), passKey]),
        const SizedBox(height: 6),
        SizedBox(
          height: 28,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(children: [
              Expanded(
                child: Text(c.message.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: c.messageType.value == 'err'
                            ? const Color(0xFFFF7A86)
                            : (c.messageType.value == 'ok' ? _ok : _muted))),
              ),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Row(children: [
                  for (int i = 0; i < 4; i++)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: entering ? _amber : const Color(0x40FFFFFF), width: 1.5),
                        color: entering && c.buf.value.length > i ? _amber : Colors.transparent,
                      ),
                    ),
                ]),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        for (int r = 0; r < 3; r++) ...[
          if (r > 0) const SizedBox(height: 8),
          row([
            _centerKey('${r * 2 + 1}', _digitColor(r * 2 + 1),
                size: 26, ready: entering, onTap: () => c.digit(r * 2 + 1)),
            _centerKey('${r * 2 + 2}', _digitColor(r * 2 + 2),
                size: 26, ready: entering, onTap: () => c.digit(r * 2 + 2)),
          ], flex: 1),
        ],
        const SizedBox(height: 8),
        row([
          _centerKey('Master', _masterColor(), icon: '', onTap: c.master),
          _centerKey('Elevator', c.flashing.contains('elevator') ? _red : null,
              icon: 'elevator', onTap: c.elevator),
          _centerKey('Exit', c.flashing.contains('exit') ? _red : null, icon: '', onTap: c.exitScenario),
        ], flex: 1),
      ],
    );
  }

  // ---------- نصاب ----------

  void _askInstallerPin(BuildContext context) {
    askInstallerPin(() => c.installer.value = true);
  }

  void _editSheet(_Slot s) {
    final textCtrl = TextEditingController(text: c.labels[s.index]);
    String iconId = c.iconOf(s.index);

    Get.bottomSheet(
      StatefulBuilder(builder: (context, setState) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: const BoxDecoration(
            color: Color(0xFF14151A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_keyTitle(s),
                    style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                const Text('آیکون', style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 230,
                  child: GridView.count(
                    crossAxisCount: 5,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: .82,
                    children: PanelIcons.choices.map((t) {
                      final sel = t == iconId;
                      return GestureDetector(
                        onTap: () => setState(() => iconId = t),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: sel ? _red.withValues(alpha: .18) : const Color(0x0DFFFFFF),
                            border: Border.all(color: sel ? _red : const Color(0x1AFFFFFF)),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            PanelIcons.icon(t, sel ? _red : _off, 28),
                            const SizedBox(height: 4),
                            Text(PanelIcons.nameOf(t),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: _muted, fontSize: 9)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('متن روی کلید (فارسی یا انگلیسی)', style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: textCtrl,
                  style: const TextStyle(color: _text),
                  maxLength: 24,
                  decoration: const InputDecoration(
                    hintText: 'مثلاً لوستر پذیرایی',
                    hintStyle: TextStyle(color: Color(0x66FFFFFF)),
                    counterStyle: TextStyle(color: _muted),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  if (s.kind == 'light')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => c.identify(s.index),
                        child: const Text('شناسایی روی پنل'),
                      ),
                    ),
                  if (s.kind == 'light') const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
                      onPressed: () {
                        c.saveKey(labelIndex: s.index, iconId: iconId, label: textCtrl.text);
                        Get.back();
                      },
                      child: const Text('ذخیره روی پنل'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        );
      }),
      isScrollControlled: true,
    );
  }
}


/// رمز نصاب (ساعت گوشی به‌صورت برعکس). در صورت درستی، [onOk] اجرا می‌شود.
void askInstallerPin(VoidCallback onOk) {
  final ctrl = TextEditingController();
  Get.dialog(
    AlertDialog(
      backgroundColor: const Color(0xFF16171C),
      title: const Text('ورود نصاب', style: TextStyle(color: _text, fontSize: 16)),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        obscureText: true,
        maxLength: 4,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _text, fontSize: 22, letterSpacing: 8),
        decoration: const InputDecoration(counterText: '', hintText: '••••'),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('انصراف')),
        TextButton(
          onPressed: () {
            if (Panel12Controller.checkInstallerPin(ctrl.text.trim())) {
              Get.back();
              onOk();
            } else {
              ctrl.clear();
              Get.snackbar('رمز اشتباه است', 'دوباره امتحان کنید',
                  colorText: _text, backgroundColor: const Color(0xCC1E1F25));
            }
          },
          child: const Text('ورود'),
        ),
      ],
    ),
  );
}

/// صفحه‌ی حالت نمایشی: همان صفحه‌ی پنل، با پنل مجازی داخل گوشی
class Panel12DemoPage extends StatefulWidget {
  const Panel12DemoPage({super.key});

  /// ورود از صفحه‌ی «دستگاه پیدا نشد» (با رمز نصاب)
  static void open() {
    askInstallerPin(_choose);
  }

  /// انتخاب پنل مجازی: ۱۲ کلید RF-12 یا پنل‌های ۲۳ کلید
  static void _choose() {
    Widget item(String title, VoidCallback onTap) => ListTile(
          title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
          trailing: const Icon(Icons.chevron_left, color: _muted),
          onTap: () {
            Get.back();
            onTap();
          },
        );
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFF14151A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('حالت نمایشی: کدام پنل؟', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          item('پنل ۱۲ کلید (RF-12)', () => Get.to(() => const Panel12DemoPage())),
          item('پنل ۲۳ کلید دزدگیردار ۱۴ پل', () => Get.to(() => const Sd23DemoPage(model: 'a14'))),
          item('پنل ۲۳ کلید ۲۰ پل', () => Get.to(() => const Sd23DemoPage(model: 'p20'))),
          item('پنل ۲۰ پل سفارشی (کولر، پرده، سناریو)', () => Get.to(() => const Sd23DemoPage(model: 'pc'))),
        ]),
      ),
    );
  }

  @override
  State<Panel12DemoPage> createState() => _Panel12DemoPageState();
}

class _Panel12DemoPageState extends State<Panel12DemoPage> {
  @override
  void initState() {
    super.initState();
    Panel12Controller.instance.startDemo();
  }

  @override
  void dispose() {
    Panel12Controller.instance.stopDemo();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: _bg, body: Panel12Screen());
  }
}
