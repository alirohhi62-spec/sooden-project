import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../panel12/panel12_controller.dart';
import '../panel12/panel12_screen.dart' show askInstallerPin;
import 'net_controller.dart';

const Color _bg = Color(0xFF0B0C10);
const Color _text = Color(0xFFF2F4F7);
const Color _muted = Color(0xB8F2F4F7);
const Color _red = Color(0xFFFF3B4E);
const Color _amber = Color(0xFFFFB547);
const Color _ok = Color(0xFF7EE2AE);
const Color _bad = Color(0xFFFF7A86);

BoxDecoration _glass({double radius = 22, Color? border}) => BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x21FFFFFF), Color(0x0AFFFFFF), Color(0x05FFFFFF), Color(0x12FFFFFF)],
        stops: [0, .38, .62, 1],
      ),
      border: Border.all(color: border ?? const Color(0x29FFFFFF)),
    );

String _fa(int n) => Panel12Controller.faNum(n);

/// خانه با شبکه‌ی CPU: فهرست پنل‌ها؛ لمس یک پنل = صفحه‌ی همان پنل
/// نگه داشتن اسم خانه: حالت نصاب با جدول سلامت شبکه
class NetScreen extends StatelessWidget {
  const NetScreen({super.key});

  NetController get c => NetController.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          _header(),
          Obx(() => c.installer.value ? _healthBar() : _summary()),
          Expanded(
            child: Obx(() {
              final ps = c.panels.toList();
              final inst = c.installer.value;
              c.health.length;
              c.healthAsked.length;
              c.opening.value;
              if (ps.isEmpty) {
                return const Center(
                  child: Text('در حال خواندن پنل‌های خانه…', style: TextStyle(color: _muted, fontSize: 13)),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                itemCount: ps.length,
                itemBuilder: (_, i) => inst ? _healthCard(context, ps[i]) : _panelCard(ps[i]),
              );
            }),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String text, Color color, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: _glass(radius: 999, border: color),
          child: Text(text, style: TextStyle(color: color, fontSize: 12)),
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Row(children: [
        Expanded(
          child: GestureDetector(
            onLongPress: () => askInstallerPin(() => c.installer.value = true),
            child: const Text('خانه',
                maxLines: 1, style: TextStyle(color: _text, fontSize: 19, fontWeight: FontWeight.w700)),
          ),
        ),
        Obx(() {
          if (c.installer.value) return _chip('نصاب  ✕', _amber, () => c.installer.value = false);
          final online = ConnectionKeeper.instance.state.value == LinkState.connected;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: _glass(radius: 999),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: online ? _ok : _amber)),
              const SizedBox(width: 6),
              Text(online ? 'آنلاین' : 'در حال اتصال', style: TextStyle(color: online ? _ok : _amber, fontSize: 12)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _summary() {
    final n = c.panels.length, on = c.onlineCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        n == 0 ? '' : (on == n ? '${_fa(n)} پنل، همه وصل' : '${_fa(n)} پنل، ${_fa(n - on)} پنل جواب نمی‌دهد'),
        style: TextStyle(color: on == n ? _muted : _bad, fontSize: 12.5),
      ),
    );
  }

  Widget _panelCard(NetPanel p) {
    final busy = c.opening.value == p.n;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        c.open(p.n);
      },
      child: Container(
        key: ValueKey('netpanel${p.n}'),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _glass(border: busy ? _red.withValues(alpha: .8) : null),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (p.online ? _ok : _bad).withValues(alpha: .12),
              border: Border.all(color: (p.online ? _ok : _bad).withValues(alpha: .6)),
            ),
            child: Text(_fa(p.n), style: TextStyle(color: p.online ? _ok : _bad, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.panelTitle(p.n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(p.model.isEmpty ? '' : NetController.modelTitle(p.model),
                  style: const TextStyle(color: _muted, fontSize: 12)),
            ]),
          ),
          if (busy)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _amber))
          else
            Text(p.online ? 'وصل' : 'جواب نمی‌دهد', style: TextStyle(color: p.online ? _ok : _bad, fontSize: 12)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_left, color: _muted, size: 20),
        ]),
      ),
    );
  }

  // ---------- حالت نصاب: سلامت شبکه (فقط با درخواست، از CPU) ----------

  Widget _healthBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(children: [
        const Expanded(
          child: Text('گزارش سلامت شبکه از CPU', style: TextStyle(color: _muted, fontSize: 12.5)),
        ),
        _chip('گزارش همه', _amber, c.askAllHealth),
      ]),
    );
  }

  Widget _healthCard(BuildContext context, NetPanel p) {
    final h = c.health[p.n];
    final asked = c.healthAsked.contains(p.n);
    Widget row(String k, String v, {Color color = _text}) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Expanded(child: Text(k, style: const TextStyle(color: _muted, fontSize: 12))),
            Text(v, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        );
    return Container(
      key: ValueKey('nethealth${p.n}'),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: _glass(border: h == null ? null : (h.healthy ? _ok : _bad).withValues(alpha: .6)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text('${_fa(p.n)}. ${c.panelTitle(p.n)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          if (asked)
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _amber))
          else
            _chip(h == null ? 'گزارش' : 'دوباره', _amber, () => c.askHealth(p.n)),
        ]),
        if (h != null) ...[
          const SizedBox(height: 6),
          row('وضعیت', h.online ? 'وصل' : 'جواب نمی‌دهد', color: h.online ? _ok : _bad),
          row(h.online ? 'آخرین جواب' : 'قطع از',
              h.seenSecs >= 0xFFFE ? 'هرگز جواب نداده' : '${NetController.ago(h.seenSecs)} پیش',
              color: h.online ? _text : _bad),
          row('مدل / نسخه', '${h.modelName}  ·  ${_fa(h.version)}'),
          row('بی‌جواب', _fa(h.lost), color: h.lost >= 20 ? _bad : _text),
          row('فریم خراب', _fa(h.bad), color: h.bad >= 20 ? _bad : _text),
          row('فرمان دوباره', _fa(h.repeats)),
          row('روشن شدن', '${_fa(h.powerUps)} بار'),
          row('زمان جواب', '${_fa(h.rttMs)} میلی‌ثانیه'),
          if (!h.healthy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('سیم شبکه، تغذیه و آدرس این پنل را بررسی کنید',
                  style: TextStyle(color: _bad, fontSize: 11.5)),
            ),
        ],
      ]),
    );
  }
}
