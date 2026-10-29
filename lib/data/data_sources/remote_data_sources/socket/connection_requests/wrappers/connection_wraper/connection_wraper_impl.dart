import 'package:bms/home/home_switch.dart';
import 'package:bms/domain/store_ip_config/store_ip_config_usecase.dart';
import 'package:bms/domain/store_ip_config/store_ip_config_usecase_impl.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../../../../../core/eventbus/event_bus_const.dart';
import '../../../../../../../core/eventbus/event_bus_model.dart';
import '../../../../../../../core/utils/globals.dart';
import '../../../../../../../core/utils/home_net.dart';
import '../../../../../../../core/utils/loc_store.dart';
import '../../../../../../enums/connection_error_code.dart';
import '../../../../../../repositories/location_repository.dart';
import '../../../../../local_data_sources/database/model/location.dart';
import '../../result.dart';
import '../connection_manager/connection_manager_data_model.dart';
import '../connection_manager/connection_manager_impl.dart';
import 'connection_wraper.dart';

class ConnectionWrapperImpl extends ConnectionWrapper {
  Location? _mCurrLocations;
  late Function(Result) _mResultCallback;

  // Private constructor
  ConnectionWrapperImpl._privateConstructor();

// Static private instance
  static final ConnectionWrapperImpl _instance = ConnectionWrapperImpl._privateConstructor();

  // Public static method to return the instance of the class
  static ConnectionWrapperImpl get instance => _instance;

  @override
  void requestForConnection(Function(Result) resultCallback) async {
    _mResultCallback = resultCallback;
    _doRequestForConnection();
  }

  _doRequestForConnection() async {
    setLoading();
    await _getUserSelectedLocation();
    _manageConnect();
  }

  void setLoading() {
    _mResultCallback.call(Result.loading());
    _logger('_sendEventStartConnecting', 'event: EventBusConst.eventSocketConnecting');
  }

  /// صفحه‌ی انتخاب مکان (از لایه‌ی نمایش گذاشته می‌شود): وقتی گوشی در محدوده‌ی هیچ پنلی نیست
  static Future<Location?> Function(List<Location> all, Location? last)? askWhich;

  /// انتخاب مکان در محدوده‌ی خارج از همه‌ی پنل‌ها برای همین شبکه یک بار پرسیده می‌شود
  String? _askedFor;
  int? _askedPick;

  /// اسم وای‌فای فعلی گوشی (بدون "")، یا '' (اینترنت همراه / نامعلوم)
  static Future<String> currentWifi() async {
    try {
      String? w = await NetworkInfo().getWifiName();
      if (w == null) return '';
      if (w.length >= 2 && w.startsWith('"') && w.endsWith('"')) w = w.substring(1, w.length - 1);
      if (w == '<unknown ssid>') return '';
      return w;
    } catch (_) {
      return '';
    }
  }

  /// مکانی که گوشی در محدوده‌اش است: اسم وای‌فای پنل یا مودم آن مکان، یا وای‌فای خود پنل
  /// با اسمی که اپ هنوز نمی‌شناسد (BSSID پنل با مک ذخیره‌شده فقط در بایت اول فرق دارد). null: هیچ‌کدام
  static Location? matchLocation(List<Location> all, String wifi, String bssid) {
    if (wifi.isEmpty) return null;
    for (final l in all) {
      if (l.panelWifiName == wifi) return l;                 // the panel's own Wi-Fi: that panel
    }
    final home = all.where((l) => l.modemName == wifi).toList();   // the home modem: the panel used last on it
    if (home.isNotEmpty) {
      final last = HomeSwitch.lastFor(wifi);
      return home.firstWhere((l) => l.id == last, orElse: () => home.first);
    }
    String tail(String? m) {
      final h = (m ?? '').toLowerCase().replaceAll(RegExp('[^0-9a-f]'), '');
      return h.length >= 12 ? h.substring(h.length - 10) : '';
    }
    final b = tail(bssid);
    if (b.isEmpty) return null;
    for (final l in all) {
      if (tail(l.mac) == b) return l;
    }
    return null;
  }

  /// مکان این اتصال:
  /// - گوشی به وای‌فای پنل یا مودم یکی از مکان‌ها وصل است: همان مکان، خودکار
  /// - در محدوده‌ی هیچ پنلی نیست (اینترنت همراه، وای‌فای دیگر): با بیش از یک مکان از کاربر پرسیده می‌شود
  ///   (آی‌پی استاتیک / سرور همان مکان استفاده می‌شود)
  _getUserSelectedLocation() async {
    final repo = Get.find<LocationRepository>();
    final all = await repo.getLocations();
    final last = await repo.getUserSelectedLocation();
    Location? pick;
    final wifi = await currentWifi();
    LocStore.wifiNow = wifi;
    LocStore.autoPicked = false;
    if (all.isNotEmpty) LocStore.firstId = all.map((l) => l.id ?? 0).reduce((a, b) => a < b ? a : b);
    LocStore.moveLegacy();                                     // data of the time before locations: to the first one, once
    if (wifi.isNotEmpty) {
      String b = '';
      try {
        b = await NetworkInfo().getWifiBSSID() ?? '';
      } catch (_) {}
      pick = matchLocation(all, wifi, b);
      if (pick != null && pick.panelWifiName != wifi && pick.modemName != wifi) {
        pick.panelWifiName = wifi;                           // اسم تازه‌ی وای‌فای پنل از این به بعد شناخته می‌شود
        await repo.updateLocation(pick);
      }
    }
    if (pick != null) {
      LocStore.autoPicked = all.length > 1;
    } else if (all.length > 1) {
      final net = wifi.isEmpty ? '-mobile-' : wifi;
      if (_askedFor == net && _askedPick != null) {
        for (final l in all) {
          if (l.id == _askedPick) pick = l;
        }
      }
      if (pick == null && askWhich != null) {
        pick = await askWhich!(all, last);
        if (pick != null) {
          _askedFor = net;
          _askedPick = pick.id;
        }
      }
      pick ??= last;
    } else {
      pick = last;
    }
    if (pick != null && pick.id != null && pick.id != last?.id) await repo.updateSelectedLocation(pick.id!);
    // گوشی روی وای‌فای مودم همین مکان: آی‌پی پنل روی مودم (اگر عوض شده پیدا می‌شود)،
    // بعد پشت صحنه آی‌پی اینترنت مودم و باز کردن پورت (UPnP) برای اتصال از بیرون
    if (pick != null && wifi.isNotEmpty && wifi == pick.modemName && wifi != pick.panelWifiName) {
      final p = pick;
      try {
        await HomeNet.checkLanIp(p, repo).timeout(const Duration(seconds: 8));
      } catch (_) {}
      Future.delayed(const Duration(seconds: 6), () => HomeNet.refreshOutside(p, repo));
    }
    _mCurrLocations = pick;
    LocStore.set(pick?.id, pick?.name ?? '');
    HomeSwitch.instance.refreshList();
    _logger('_getUserSelectedLocation', 'wifi: $wifi, location: ${pick?.name} (auto ${LocStore.autoPicked})');
  }

  void _manageConnect() {
    if (_mCurrLocations != null) {
      _doConnect();
    } else {
      _mResultCallback.call(Result.failure(ConnectionErrorCode.emptyLocation));
    }
  }

  void _doConnect() {
    _logger('_doConnect', 'Method Called');
    ConnectionManagerImpl.instance.setData(_onResultCallback).connectByLocation(_mCurrLocations!);
  }

  _onResultCallback(Result result) async {
    if(result.isSuccess){
      await _collectIpData(result.successValue);
      (result.successValue as ConnectionManagerDataModel).referenceLocation = _mCurrLocations;
    }
    _mResultCallback.call(result);
  }

  _collectIpData(ConnectionManagerDataModel dataModel) async {
    _logger('_collectIpData', dataModel.getIpConfig().toString());

    StoreIpConfigDataUsecaseImpl().storeData(_mCurrLocations, dataModel.getIpConfig());
  }

  void _logger(String key, String value) {
    doLogGlobal('ConnectionWrapper. H:$hashCode', key, value);
  }
}
