import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/data_sources/local_data_sources/database/model/location.dart';
import '../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../data/repositories/location_repository.dart';
import '../panel12/panel12_controller.dart';
import '../presentation/logic/new_location_logic.dart';
import 'home_switch.dart';

/// «+» بالای صفحه‌ی پنل: پنل تازه‌ی همین خانه. گوشی به وای‌فای پنل تازه وصل می‌شود و فقط اسم پنل نوشته می‌شود؛
/// اسم و رمز مودم از مکان فعلی برداشته می‌شود (همان مراحل «مکان جدید»: NewLocationLogic با home).
/// تا پنل به مودم وصل نشده جزو خانه نیست: برگه بسته شود، مکان تازه پاک و پنل قبلی دوباره باز می‌شود.
const Color _bg = Color(0xFF15161B);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _faint = Color(0x80F2F4F7);
const Color _line = Color(0x29FFFFFF);
const Color _red = Color(0xFFFF3B4E);
const Color _green = Color(0xFF7EE2A8);
const Color _amber = Color(0xFFFFB648);
const String _latin = 'Roboto';
const String _tag = 'add-panel';

class AddPanelSheet extends StatefulWidget {
  final Location home;
  const AddPanelSheet({super.key, required this.home});

  static Future<void> open(Location home) async {
    if (Get.isRegistered<NewLocationLogic>(tag: _tag)) return;
    await Get.bottomSheet(AddPanelSheet(home: home), isScrollControlled: true, backgroundColor: Colors.transparent);
  }

  @override
  State<AddPanelSheet> createState() => _AddPanelSheetState();
}

class _AddPanelSheetState extends State<AddPanelSheet> {
  late final NewLocationLogic l = Get.put(NewLocationLogic(null, home: widget.home), tag: _tag);
  Timer? _wifiTimer;
  bool _started = false, _editModem = false, _done = false;

  String get _modem => l.modemNameController.text.trim();

  @override
  void initState() {
    super.initState();
    l.modemNameController.text = (widget.home.modemName ?? '').trim();
    l.modemPasswordController.text = widget.home.modemPassword ?? '';
    _wifiTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!l.isLoading && !l.mSetModemIpLoading) l.refreshPhoneWifi();
    });
  }

  @override
  void dispose() {
    _wifiTimer?.cancel();
    final added = l.locationToEdit;
    final ok = _done;
    Get.delete<NewLocationLogic>(tag: _tag);
    if (added != null && ok) {
      HomeSwitch.instance.openNew(added);
    } else if (_started) {
      _undo(added);
    }
    super.dispose();
  }

  /// بسته شد پیش از وصل شدن به مودم: مکان تازه پاک، پنل قبلی دوباره
  Future<void> _undo(Location? added) async {
    final repo = Get.find<LocationRepository>();
    if (added?.id != null && added!.id != widget.home.id) await repo.deleteLocation(added);
    if (widget.home.id != null) await repo.updateSelectedLocation(widget.home.id!);
    Panel12Controller.instance.prepareSwitch();
    ConnectionRequestsImpl.instance.forceReconnect();
  }

  /// گوشی روی مودم خانه است، نه روی پنل تازه
  bool _onModem(NewLocationLogic l) => l.phoneWifi.isNotEmpty && l.phoneWifi == _modem;

  void _start() {
    if (l.locationNameController.text.trim().isEmpty) {
      l.connError = 'اسم این پنل را بنویسید (مثلاً آشپزخانه).';
      l.update();
      return;
    }
    if (!_started) Panel12Controller.instance.prepareSwitch();   // صفحه‌ی زیر برگه: پنل قبلی پاک
    _started = true;
    l.connError = null;
    l.modemMsg = null;
    if (l.locationToEdit == null) {
      l.checkConnection();
    } else {
      l.setModemConfig();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          decoration: const BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            border: Border(top: BorderSide(color: _line)),
          ),
          child: SafeArea(
            top: false,
            child: GetBuilder<NewLocationLogic>(
              tag: _tag,
              builder: (l) => SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(4)))),
                  const SizedBox(height: 12),
                  ..._body(l),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(NewLocationLogic l) {
    final home = widget.home.name ?? 'این خانه';
    final name = l.locationNameController.text.trim();
    final busy = l.isLoading || l.mSetModemIpLoading;
    if (l.modemOk && l.locationToEdit != null) {
      _done = true;
      final back = _onModem(l);
      return [
        _title('«$name» به «$home» اضافه شد'),
        _steps(l),
        const SizedBox(height: 12),
        if (!back) ...[
          _hint('برای دیدن همه‌ی پنل‌های خانه، گوشی را به وای‌فای مودم «$_modem» برگردانید.'),
          const SizedBox(height: 10),
        ],
        Row(children: [
          Expanded(child: _button('باز کردن «$name»', primary: true, onTap: () => Get.back())),
          if (!back) ...[const SizedBox(width: 8), Expanded(child: _button('تنظیمات وای‌فای', onTap: l.openWifiSettings))],
        ]),
      ];
    }
    if (_started && (busy || (l.locationToEdit != null && l.modemMsg == null))) {
      return [_title('«$name» به مودم وصل می‌شود'), _steps(l)];
    }
    final failed = _started && (l.connError != null || (l.modemMsg != null && !l.modemOk));
    final onModem = _onModem(l);
    return [
      _title('افزودن پنل به «$home»'),
      if (failed) ...[_failCard(l), const SizedBox(height: 12)],
      if (!failed) ...[
        _hint('گوشی را به وای‌فای پنل تازه وصل کنید (کلید وای‌فای پنل را ۵ تا ۷ ثانیه نگه دارید).'),
        const SizedBox(height: 10),
        _wifiPill(l),
        const SizedBox(height: 12),
      ],
      if (l.connError != null && !_started) ...[
        Text(l.connError!, style: const TextStyle(color: Color(0xFFFF8A96), fontSize: 13)),
        const SizedBox(height: 8),
      ],
      _field('اسم این پنل', l.locationNameController, hint: 'مثلاً آشپزخانه', enabled: l.locationToEdit == null),
      if (!_editModem)
        _modemRow()
      else ...[
        _field('نام مودم', l.modemNameController, latin: true),
        _field('رمز مودم', l.modemPasswordController, latin: true),
      ],
      const SizedBox(height: 4),
      if (failed)
        Row(children: [
          Expanded(child: _button('دوباره', primary: true, onTap: onModem ? null : _start)),
          if (!_editModem) ...[
            const SizedBox(width: 8),
            Expanded(child: _button('نوشتن رمز مودم', onTap: () => setState(() => _editModem = true))),
          ],
        ])
      else
        Row(children: [
          Expanded(child: _button('افزودن و وصل کردن به مودم', primary: true, onTap: onModem ? null : _start)),
          if (onModem) ...[const SizedBox(width: 8), Expanded(child: _button('تنظیمات وای‌فای', onTap: l.openWifiSettings))],
        ]),
    ];
  }

  Widget _wifiPill(NewLocationLogic l) {
    final w = l.phoneWifi;
    final onModem = _onModem(l);
    final ok = w.isNotEmpty && !onModem;
    final c = ok ? _green : _amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: c.withValues(alpha: .08), border: Border.all(color: c.withValues(alpha: .4))),
      child: Row(children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 9),
        Expanded(
          child: w.isEmpty
              ? const Text('وای‌فای گوشی معلوم نیست (یا اجازه‌ی «موقعیت» به اپ داده نشده).', style: TextStyle(color: _muted, fontSize: 12.5))
              : Text.rich(TextSpan(style: const TextStyle(color: _muted, fontSize: 12.5), children: [
                  const TextSpan(text: 'گوشی به  '),
                  TextSpan(text: w, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontFamily: _latin)),
                  TextSpan(text: onModem ? '  (مودم خانه) وصل است، نه به پنل تازه' : '  وصل است'),
                ])),
        ),
      ]),
    );
  }

  Widget _modemRow() => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('مودم (از «${widget.home.name ?? ''}»)', style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x0AFFFFFF), border: Border.all(color: const Color(0x1FFFFFFF))),
            child: Row(children: [
              Expanded(child: Text(_modem, textDirection: TextDirection.ltr, textAlign: TextAlign.right, style: const TextStyle(color: _muted, fontSize: 15, fontFamily: _latin))),
              GestureDetector(
                key: const ValueKey('add-modem-edit'),
                onTap: () => setState(() => _editModem = true),
                child: const Text('تغییر', style: TextStyle(color: Color(0xFFFF8A96), fontSize: 13)),
              ),
            ]),
          ),
        ]),
      );

  /// مراحل: پنل جواب داد · اسم و رمز مودم به پنل رفت · پنل به مودم وصل شد · گوشی روی مودم
  Widget _steps(NewLocationLogic l) {
    final s1 = l.locationToEdit != null;
    final s2 = s1 && (l.mSetModemIpLoading || l.modemOk);
    final s3 = l.modemOk;
    final s4 = s3 && _onModem(l);
    Widget row(bool done, bool run, String t, [String? sub]) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 20,
              height: 20,
              child: done
                  ? Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: _green.withValues(alpha: .16)),
                      child: const Icon(Icons.check, size: 13, color: _green))
                  : run
                      ? const CircularProgressIndicator(strokeWidth: 2, color: _amber)
                      : Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _line))),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: TextStyle(color: done || run ? _text : _muted, fontSize: 13.5)),
                if (sub != null) Text(sub, style: const TextStyle(color: _faint, fontSize: 11.5)),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      row(s1, !s1, 'پنل جواب داد'),
      row(s2, false, 'اسم و رمز مودم به پنل رفت'),
      row(s3, s2 && !s3, 'پنل به «$_modem» وصل شد', s2 && !s3 ? 'تا ۴۵ ثانیه؛ گوشی را نزدیک پنل نگه دارید' : null),
      row(s4, false, 'گوشی روی وای‌فای مودم خانه'),
    ]);
  }

  Widget _failCard(NewLocationLogic l) {
    final name = l.locationNameController.text.trim();
    final conn = l.connError != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: _red.withValues(alpha: .07), border: Border.all(color: _red.withValues(alpha: .45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(conn ? (l.connError == 'پنل جواب نداد' ? 'پنل تازه جواب نداد' : 'توجه') : '«$name» به مودم وصل نشد',
            style: const TextStyle(color: Color(0xFFFF8A96), fontSize: 14.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
            conn
                ? (l.connError == 'پنل جواب نداد'
                    ? 'گوشی را به وای‌فای پنل تازه (⁦sooden-...⁩) وصل کنید، نزدیک پنل بروید و «دوباره» را بزنید.'
                    : l.connError!)
                : l.modemMsg!,
            style: const TextStyle(color: _text, fontSize: 13, height: 1.7)),
      ]),
    );
  }

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
      );

  Widget _hint(String t) => Text(t, style: const TextStyle(color: _muted, fontSize: 13, height: 1.7));

  Widget _field(String label, TextEditingController c, {String? hint, bool latin = false, bool enabled = true}) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x66000000), border: Border.all(color: _line)),
            child: TextField(
              controller: c,
              enabled: enabled,
              autocorrect: false,
              enableSuggestions: !latin,
              keyboardType: latin ? TextInputType.visiblePassword : TextInputType.text,
              textAlign: TextAlign.right,
              textDirection: latin ? TextDirection.ltr : null,
              style: TextStyle(color: enabled ? _text : _muted, fontSize: 16, fontFamily: latin ? _latin : null),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: _faint, fontSize: 15),
              ),
            ),
          ),
        ]),
      );

  Widget _button(String text, {bool primary = false, VoidCallback? onTap}) => InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .4 : 1,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: primary ? _red : const Color(0x14FFFFFF),
              border: primary ? null : Border.all(color: const Color(0x3DFFFFFF)),
            ),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
          ),
        ),
      );
}
