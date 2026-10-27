import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/utils/loc_store.dart';
import '../../data/data_sources/local_data_sources/database/model/location.dart';

/// گوشی در محدوده‌ی هیچ پنلی نیست (اینترنت همراه یا وای‌فای دیگر): به کدام مکان وصل شویم؟
/// (آی‌پی استاتیک یا سرور همان مکان)
class LocationPicker {
  static const Color _bg = Color(0xFF15161B), _text = Color(0xFFF2F4F7), _muted = Color(0xB8F2F4F7), _red = Color(0xFFFF3B4E);

  static Future<Location?> ask(List<Location> all, Location? last) async {
    final done = Completer<Location?>();
    final wifi = LocStore.wifiNow;
    await Get.bottomSheet(
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
              Center(
                  child: Container(
                      width: 40, height: 4, decoration: BoxDecoration(color: const Color(0x40FFFFFF), borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 12),
              const Text('به کدام مکان وصل شویم؟', style: TextStyle(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                  wifi.isEmpty
                      ? 'گوشی در محدوده‌ی وای‌فای هیچ‌کدام از پنل‌ها نیست (اینترنت همراه). اتصال از راه آی‌پی استاتیک / سرور همان مکان.'
                      : 'گوشی به «$wifi» وصل است که مال هیچ‌کدام از مکان‌ها نیست. اتصال از راه آی‌پی استاتیک / سرور همان مکان.',
                  style: const TextStyle(color: _muted, fontSize: 12.5, height: 1.7)),
              const SizedBox(height: 12),
              for (final l in all)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (!done.isCompleted) done.complete(l);
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: l.id == last?.id ? _red.withValues(alpha: .10) : const Color(0x0DFFFFFF),
                        border: Border.all(color: l.id == last?.id ? _red.withValues(alpha: .6) : const Color(0x29FFFFFF)),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l.name ?? 'مکان', style: const TextStyle(color: _text, fontSize: 14.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                                (l.staticIp ?? '').isNotEmpty ? 'آی‌پی استاتیک: ${l.staticIp}' : 'آی‌پی استاتیک ندارد (فقط در محدوده‌ی همان مکان)',
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(color: _muted, fontSize: 11.5)),
                          ]),
                        ),
                        if (l.id == last?.id) const Text('آخرین مکان', style: TextStyle(color: _muted, fontSize: 11.5)),
                      ]),
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
    if (!done.isCompleted) done.complete(last);
    return done.future;
  }
}
