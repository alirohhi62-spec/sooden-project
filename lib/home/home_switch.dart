import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../core/utils/loc_store.dart';
import '../data/data_sources/local_data_sources/database/model/location.dart';
import '../data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import '../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../data/repositories/location_repository.dart';
import '../panel12/panel12_controller.dart';
import 'add_panel.dart';
import 'panel_switcher.dart';

/// پنل‌های یک خانه: مکان‌هایی که مودمشان یکی است. بالای صفحه‌ی پنل نشان داده می‌شوند و با یک لمس
/// اتصال به پنل دیگر عوض می‌شود (بدون شروع دوباره‌ی اپ). آخرین پنل هر مودم یادش می‌ماند.
class HomeSwitch extends GetxController {
  static HomeSwitch get instance {
    if (!Get.isRegistered<HomeSwitch>()) Get.put(HomeSwitch(), permanent: true);
    return Get.find<HomeSwitch>();
  }

  final RxList<Location> panels = <Location>[].obs;
  final RxInt current = (-1).obs;
  final RxBool onModem = false.obs;      // گوشی روی وای‌فای مودم این خانه است
  final RxBool switching = false.obs;

  static String _lastKey(String modem) => 'home_last_$modem';

  /// آخرین پنلی که روی این مودم باز بود
  static int? lastFor(String modem) {
    try {
      return GetStorage().read<int>(_lastKey(modem));
    } catch (_) {
      return null;
    }
  }

  static void setLast(String modem, int id) {
    try {
      GetStorage().write(_lastKey(modem), id);
    } catch (_) {}
  }

  /// اسم مدل هر پنل (زیر اسمش)، همان که پنل آخرین بار اعلام کرد
  static const String titleKey = 'home_title';
  String titleOf(Location l) => LocStore.readFor<String>(l.id, titleKey) ?? '';

  @override
  void onInit() {
    super.onInit();
    LocStore.listen(refreshList);
  }

  Future<void> refreshList() async {
    try {
      final all = await Get.find<LocationRepository>().getLocations();
      final cur = all.firstWhereOrNull((l) => l.id == LocStore.id);
      final modem = (cur?.modemName ?? '').trim();
      current.value = cur?.id ?? -1;
      if (cur == null || modem.isEmpty) {
        panels.clear();
        return;
      }
      panels.assignAll(all.where((l) => (l.modemName ?? '').trim() == modem));
      onModem.value = LocStore.wifiNow == modem;
      if (onModem.value && cur.id != null) setLast(modem, cur.id!);
    } catch (_) {
      panels.clear();
    }
  }

  /// یک پنل هم کافی است: «+» برای افزودن پنل دیگر به همین خانه
  bool get visible => panels.isNotEmpty;

  /// به پنل دیگر همین خانه
  Future<void> switchTo(int id) async {
    if (switching.value || id == current.value) return;
    final l = panels.firstWhereOrNull((x) => x.id == id);
    if (l == null) return;
    switching.value = true;
    try {
      final repo = Get.find<LocationRepository>();
      setLast((l.modemName ?? '').trim(), id);
      await repo.updateSelectedLocation(id);
      Panel12Controller.instance.prepareSwitch();          // صفحه‌ی پنل قبلی پاک؛ مدل را پنل تازه می‌گوید
      ConnectionRequestsImpl.instance.forceReconnect();      // همان مسیر اتصال: مکان، آدرس روی مودم، اتصال
    } finally {
      Future.delayed(const Duration(seconds: 2), () => switching.value = false);
    }
  }

  /// پنل تازه‌ای که با «+» اضافه شد (هنوز در فهرست نیست): همان را باز کن
  Future<void> openNew(Location l) async {
    if (l.id == null) return;
    setLast((l.modemName ?? '').trim(), l.id!);
    await Get.find<LocationRepository>().updateSelectedLocation(l.id!);
    Panel12Controller.instance.prepareSwitch();
    ConnectionRequestsImpl.instance.forceReconnect();
    await refreshList();
  }
}

/// نوار بالای صفحه‌ی پنل: پنل‌های این خانه و «+» برای افزودن (فقط وقتی مکان مودم دارد)
class HomeSwitchBar extends StatelessWidget {
  const HomeSwitchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final h = HomeSwitch.instance;
    return Obx(() {
      if (!h.visible) return const SizedBox.shrink();
      final link = ConnectionKeeper.instance.state.value;
      final onPanelWifi = LocStore.via == 'panel';
      final list = [
        for (final l in h.panels)
          HomePanel(l.id ?? 0, l.name ?? 'پنل', h.titleOf(l),
              online: l.id == h.current.value ? link == LinkState.connected : true,
              known: l.id == h.current.value,
              reachable: l.id == h.current.value || h.onModem.value),
      ];
      final cur = h.panels.firstWhereOrNull((l) => l.id == h.current.value);
      return SafeArea(
        bottom: false,
        child: PanelSwitcher(
          panels: list,
          current: h.current.value,
          style: SwitcherStyle.auto,
          onAdd: cur == null ? null : () => AddPanelSheet.open(cur),
          note: h.panels.length < 2
              ? null
              : !h.onModem.value
              ? (onPanelWifi
                  ? 'گوشی به وای‌فای خود «${cur?.name ?? ''}» وصل است؛ بقیه‌ی پنل‌ها فقط از راه مودم خانه'
                  : 'بقیه‌ی پنل‌های این خانه فقط وقتی گوشی روی وای‌فای مودم خانه است')
              : null,
          onPick: (p) => h.switchTo(p.id),
        ),
      );
    });
  }
}
