import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/presentation/screens/tabs/settings/pages/qr_reader_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:bms/panel12/panel12_screen.dart';

import '../../../../../core/utils/globals.dart';
import '../../../../logic/new_location_logic.dart';
import '../../../logger/logger_screen.dart';

// همان ظاهر صفحه‌های تازه‌ی اپ (شیشه‌ای تیره)
const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _faint = Color(0x80F2F4F7);
const Color _line = Color(0x29FFFFFF);
const Color _red = Color(0xFFFF3B4E);
const Color _green = Color(0xFF7EE2A8);
const Color _amber = Color(0xFFFFB648);

/// اسم وای‌فای، آی‌پی و رمز: با رقم انگلیسی (فونت اصلی اپ رقم فارسی دارد)
const String _latin = 'Roboto';

class NewLocationScreen extends StatefulWidget {
  late Location? locationToEdit;

  NewLocationScreen({this.locationToEdit, super.key});

  @override
  State<StatefulWidget> createState() => _NewLocationScreenState();
}

class _NewLocationScreenState extends State<NewLocationScreen> with WidgetsBindingObserver {
  late NewLocationLogic logic;
  bool _showWifiPw = false, _showModemPw = false;

  @override
  void initState() {
    logic = Get.put(NewLocationLogic(widget.locationToEdit));
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// برگشت از تنظیمات وای‌فای گوشی: وای‌فای تازه را نشان بده
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) logic.refreshPhoneWifi();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NewLocationLogic>(
      assignId: true,
      builder: (logic) {
        final has = logic.visibleOtherFields();
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: _bg,
            body: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(center: Alignment(-1.1, -0.5), radius: 1.2, colors: [Color(0x40B0182A), Color(0x000B0C10)]),
              ),
              child: SafeArea(
                child: Column(children: [
                  _header(),
                  Expanded(
                    child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                      _wifiStatus(logic),
                      const SizedBox(height: 14),
                      if (logic.connError != null && !logic.isLoading) ...[_errorCard(logic), const SizedBox(height: 14)],
                      _placeCard(logic, has),
                      if (has) ...[
                        const SizedBox(height: 14),
                        _panelWifiCard(logic),
                        const SizedBox(height: 14),
                        _modemCard(logic),
                      ],
                    ]),
                  ),
                  if (has)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
                      child: _button('رفتن به صفحه اصلی', onTap: logic.goToMainClicked),
                    ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header() {
    final edit = widget.locationToEdit != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(children: [
        Expanded(
            child: Text(edit ? 'تنظیمات مکان' : 'تعریف مکان جدید',
                style: const TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w700))),
        _iconBtn(Icons.slideshow_outlined, 'حالت نمایشی', Panel12DemoPage.open),
        if (isLoggerEnable) ...[const SizedBox(width: 8), _iconBtn(Icons.history, 'گزارش', () => Get.to(() => LoggerScreen()))],
        if (Navigator.of(context).canPop()) ...[const SizedBox(width: 8), _iconBtn(Icons.arrow_forward, 'برگشت', () => Get.back())],
      ]),
    );
  }

  Widget _iconBtn(IconData i, String tip, VoidCallback onTap) => Tooltip(
        message: tip,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14), color: const Color(0x14FFFFFF), border: Border.all(color: _line)),
            child: Icon(i, color: _muted, size: 22),
          ),
        ),
      );

  /// گوشی الان به کدام وای‌فای وصل است
  Widget _wifiStatus(NewLocationLogic l) {
    final w = l.phoneWifi;
    final ok = l.onPanelWifi;
    final c = ok ? _green : _amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0x0DFFFFFF), border: Border.all(color: _line)),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: w.isEmpty
              ? const Text('گوشی به وای‌فای وصل نیست (یا اجازه‌ی «موقعیت» به اپ داده نشده).',
                  style: TextStyle(color: _muted, fontSize: 13))
              : Text.rich(
                  TextSpan(style: const TextStyle(color: _muted, fontSize: 13.5), children: [
                    const TextSpan(text: 'گوشی به  '),
                    TextSpan(text: w, style: TextStyle(color: c, fontWeight: FontWeight.w700, fontFamily: _latin)),
                    TextSpan(text: ok ? '  وصل است' : '  وصل است، نه به پنل'),
                  ]),
                ),
        ),
      ]),
    );
  }

  Widget _errorCard(NewLocationLogic l) {
    final noAnswer = l.connError == 'پنل جواب نداد';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(colors: [Color(0x40FF3B4E), Color(0x14FF3B4E)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        border: Border.all(color: _red.withValues(alpha: .55)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(noAnswer ? 'پنل جواب نداد' : 'توجه', style: const TextStyle(color: Color(0xFFFF8A96), fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (noAnswer) ...[
          _bullet('گوشی را به وای‌فای پنل (\u2066sooden-...\u2069) وصل کنید.'),
          _bullet('وای‌فای پنل روشن است؟ کلید وای‌فای پنل (در بیشتر پنل‌ها سناریوی سمت راست) را ۵ تا ۷ ثانیه نگه دارید.'),
          _bullet('گوشی را نزدیک پنل ببرید و «دوباره» را بزنید.'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _button('دوباره', primary: true, onTap: l.checkConnection)),
            const SizedBox(width: 10),
            Expanded(child: _button('تنظیمات وای‌فای', onTap: l.openWifiSettings)),
          ]),
        ] else
          Text(l.connError!, style: const TextStyle(color: _text, fontSize: 13.5, height: 1.7)),
      ]),
    );
  }

  Widget _bullet(String t) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 6, height: 6, margin: const EdgeInsets.only(top: 10, left: 10),
              decoration: const BoxDecoration(color: _text, shape: BoxShape.circle)),
          Expanded(child: Text(t, style: const TextStyle(color: _text, fontSize: 13.5, height: 1.7))),
        ]),
      );

  Widget _placeCard(NewLocationLogic l, bool has) {
    return _card(1, 'مشخصات مکان', has ? 'برای اتصال دوباره به همین پنل، «اتصال دوباره» را بزنید.' : 'اول گوشی را به وای‌فای پنل (\u2066sooden-...\u2069) وصل کنید، بعد یک اسم برای این مکان بنویسید و «ذخیره و اتصال به پنل» را بزنید.', [
      _field('نام مکان', l.locationNameController, hint: 'مثلاً منزل', help: 'هر اسمی که دوست دارید؛ مثلاً منزل، ویلا یا مغازه. در «مکان‌های من» با همین اسم دیده می‌شود.'),
      InkWell(
        onTap: () => setState(() => l.showMore = !l.showMore),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [
            const Expanded(child: Text('تنظیمات بیشتر (آی‌پی استاتیک)', style: TextStyle(color: _muted, fontSize: 13.5))),
            Icon(l.showMore ? Icons.expand_less : Icons.expand_more, color: _faint),
          ]),
        ),
      ),
      if (l.showMore) ...[
        _field('آی‌پی استاتیک', l.staticIpController,
            hint: '5.160.20.11',
            latin: true,
            keyboard: TextInputType.number,
            help: 'برای کنترل از بیرون منزل. لازم نیست خودتان بنویسید: هر بار که در منزل گوشی به وای‌فای مودم وصل است، '
                'اپ آی‌پی اینترنت مودم را می‌خواند و اینجا ذخیره می‌کند.'),
        if (l.outsideStatus != null) _msg(l.outsideStatus!, l.outsideOk),
        if (has) ...[
          _field('آدرس سرور', l.serverAddrController,
              hint: 'server.sooden.ir', latin: true, help: 'به‌زودی: اتصال از راه سرور سودن. فعلاً خالی بماند.'),
          _field('رمز سرور', l.serverPassController, latin: true, obscure: true),
          _button('ذخیره‌ی تنظیمات بیشتر', onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
            l.setStaticIpConfig();
            Get.snackbar('', 'ذخیره شد.', titleText: const SizedBox(), colorText: _text, backgroundColor: const Color(0xE6202228));
          }),
          const SizedBox(height: 10),
        ],
      ],
      if (l.isLoading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Column(children: [
            SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 4, color: _red, backgroundColor: Color(0x22FFFFFF))),
            SizedBox(height: 12),
            Text('در حال اتصال به پنل...', style: TextStyle(color: _muted, fontSize: 13.5)),
          ]),
        )
      else
        _button(has ? 'اتصال دوباره به پنل' : 'ذخیره و اتصال به پنل', primary: !has, onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          l.checkConnection();
        }),
    ]);
  }

  Widget _panelWifiCard(NewLocationLogic l) {
    return _card(2, 'وای‌فای پنل', 'اختیاری: اسم و رمز وای‌فای خود پنل را عوض کنید. بعد از ثبت، گوشی را به وای‌فای تازه وصل کنید.', [
      _field('اسم وای‌فای', l.wifiNameController,
          hint: 'sooden-3F2A', latin: true, help: 'هر حرفی (فارسی، انگلیسی، عدد، @ _ " و ...)؛ تا ۳۲ حرف انگلیسی یا حدود ۱۶ حرف فارسی.'),
      _field('رمز', l.wifiPasswordController,
          latin: true,
          obscure: !_showWifiPw,
          onEye: () => setState(() => _showWifiPw = !_showWifiPw),
          help: 'خالی بگذارید = وای‌فای بدون رمز. یا دست‌کم ۸ حرف (تا ۴۰ حرف، هر حرفی).'),
      if (l.wifiMsg != null) _msg(l.wifiMsg!, l.wifiOk),
      _button('ثبت روی پنل', onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        l.onSetDeviceNamePassword();
      }),
    ]);
  }

  Widget _modemCard(NewLocationLogic l) {
    return _card(3, 'اتصال پنل به مودم', 'اختیاری، برای کنترل با وای‌فای منزل: اسم و رمز وای‌فای مودم منزل را بنویسید و «تست اتصال» را بزنید. در این مدت گوشی به وای‌فای پنل وصل بماند.', [
      _field('مک آدرس پنل', l.macAddressController, hint: 'خودکار پر می‌شود', latin: true, enabled: false),
      _field('نام مودم', l.modemNameController,
          hint: 'MyHome-5G',
          latin: true,
          help: 'اسم وای‌فای منزل، دقیقاً همان که در گوشی دیده می‌شود (بزرگی و کوچکی حروف مهم است).',
          trailing: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              Get.to(() => QRReaderScreen((ssid, password) {
                    setState(() {
                      l.modemNameController.text = ssid;
                      l.modemPasswordController.text = password;
                    });
                    l.setModemConfig();
                  }));
            },
            child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPicture.asset('assets/icons/qr.svg', width: 22, colorFilter: const ColorFilter.mode(_muted, BlendMode.srcIn))),
          )),
      _field('رمز مودم', l.modemPasswordController,
          latin: true,
          obscure: !_showModemPw,
          onEye: () => setState(() => _showModemPw = !_showModemPw),
          help: 'رمز وای‌فای منزل. با دکمه‌ی QR کنار اسم مودم هم می‌شود بارکد وای‌فای مودم را خواند.'),
      _field('آی‌پی پنل روی مودم', l.panelIpOnModemController, hint: 'بعد از تست اتصال پر می‌شود', latin: true, enabled: false, dashed: true),
      if (l.modemMsg != null) _msg(l.modemMsg!, l.modemOk),
      _button(l.mSetModemIpLoading ? 'در حال وصل شدن پنل به مودم... (تا ۲۰ ثانیه)' : 'تست اتصال',
          onTap: l.mSetModemIpLoading
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  l.setModemConfig();
                }),
    ]);
  }

  Widget _msg(String t, bool ok) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: const EdgeInsets.only(top: 2, left: 6),
              child: Icon(ok ? Icons.check_circle_outline : Icons.error_outline, size: 18, color: ok ? _green : const Color(0xFFFF8A96))),
          Expanded(child: Text(t, style: TextStyle(color: ok ? _green : const Color(0xFFFF8A96), fontSize: 13, height: 1.6))),
        ]),
      );

  Widget _card(int n, String title, String guide, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: [Color(0x1FFFFFFF), Color(0x08FFFFFF)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        border: Border.all(color: _line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9), color: _red.withValues(alpha: .16), border: Border.all(color: _red.withValues(alpha: .6))),
            child: Text('$n', style: const TextStyle(color: _red, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: _text, fontSize: 17, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Text(guide, style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.7)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint,
      String? help,
      bool latin = false,
      bool enabled = true,
      bool obscure = false,
      bool dashed = false,
      VoidCallback? onEye,
      Widget? trailing,
      TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: enabled ? const Color(0x66000000) : const Color(0x0AFFFFFF),
            border: Border.all(color: dashed ? const Color(0x1FFFFFFF) : _line),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: c,
                enabled: enabled,
                obscureText: obscure,
                keyboardType: keyboard ?? (obscure || onEye != null ? TextInputType.visiblePassword : TextInputType.text),
                autocorrect: false,
                enableSuggestions: !latin,
                textAlign: TextAlign.right,
                textDirection: latin ? TextDirection.ltr : null,
                style: TextStyle(color: enabled ? _text : _muted, fontSize: 16, fontFamily: latin ? _latin : null),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: TextStyle(color: _faint, fontSize: 15, fontFamily: latin && hint != null && !RegExp('[آ-ی]').hasMatch(hint) ? _latin : null),
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (onEye != null)
              IconButton(
                onPressed: onEye,
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _faint, size: 22),
              ),
            const SizedBox(width: 4),
          ]),
        ),
        if (help != null) ...[
          const SizedBox(height: 5),
          Text(help, style: const TextStyle(color: _faint, fontSize: 12, height: 1.6)),
        ],
      ]),
    );
  }

  Widget _button(String text, {bool primary = false, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: primary ? const LinearGradient(colors: [Color(0xFFFF4B5C), Color(0xFFE0283C)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
          color: primary ? null : const Color(0x14FFFFFF),
          border: primary ? null : Border.all(color: const Color(0x3DFFFFFF)),
          boxShadow: primary ? [BoxShadow(color: _red.withValues(alpha: .35), blurRadius: 18, offset: const Offset(0, 6))] : null,
        ),
        child: Text(text,
            textAlign: TextAlign.center,
            style: TextStyle(color: onTap == null ? _muted : _text, fontSize: 15.5, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
