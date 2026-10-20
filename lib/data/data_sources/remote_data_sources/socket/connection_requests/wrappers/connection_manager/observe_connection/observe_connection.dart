import 'dart:async';

import 'package:bms/data/data_sources/remote_data_sources/socket/connection_keeper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../../../../../../../../core/utils/globals.dart';

class ObserveConnection {
  late String? wifiBSSIDLookingFor;
  StreamSubscription<List<ConnectivityResult>>? _mSubscription;

  ObserveConnection();

  /// نوع شبکه و وای‌فای در لحظه‌ی آخرین بررسی؛ فقط «تغییر» شبکه اتصال را از نو می‌سازد
  String? _lastNetworkKey;

  void subscribe(String? wifiBSSIDLookingFor) {
    this.wifiBSSIDLookingFor = wifiBSSIDLookingFor;
    _logger('_subscribeToWifiChanges', 'do subscription');
    _mSubscription?.cancel();
    _lastNetworkKey = null;
    Connectivity().checkConnectivity().then((r) async {
      _lastNetworkKey ??= await _networkKey(r);
    });
    _mSubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<String> _networkKey(List<ConnectivityResult> result) async {
    final type = result.isEmpty ? ConnectivityResult.none : result.last;
    if (type == ConnectivityResult.wifi) {
      final bssid = await NetworkInfo().getWifiBSSID();
      return 'wifi:${bssid ?? '?'}';
    }
    return type.name;
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _logger('_updateConnectionStatus', 'Changed to: ${result.join('-')}');
    final type = result.isEmpty ? ConnectivityResult.none : result.last;

    if (type == ConnectivityResult.none) {
      // بدون شبکه: وقتی شبکه برگشت، رویداد بعدی اتصال را برقرار می‌کند
      _logger('_updateConnectionStatus', 'No network available');
      _lastNetworkKey = 'none';
      return;
    }

    final key = await _networkKey(result);
    if (_lastNetworkKey == null) {
      // اولین رویداد بعد از اتصال: فقط وضعیت فعلی ثبت شود
      _lastNetworkKey = key;
      return;
    }
    if (key == _lastNetworkKey) {
      _logger('_updateConnectionStatus', 'Same network ($key), nothing to do');
      return;
    }
    _logger('_updateConnectionStatus', 'Network changed: $_lastNetworkKey -> $key');
    _lastNetworkKey = key;

    if (type == ConnectivityResult.wifi && wifiBSSIDLookingFor != null &&
        key == 'wifi:$wifiBSSIDLookingFor') {
      // برگشت به همان وای‌فای: اگر اتصال قطع است، دوباره وصل شود
      ConnectionKeeper.instance.ensureConnected();
      return;
    }
    onDisconnected();
  }

  /// شبکه عوض شد یا وای‌فای قطع شد.
  /// قبلاً کاربر بلافاصله به صفحه‌ی خطا فرستاده می‌شد؛ حالا اتصال بی‌صدا
  /// با تعیین دوباره‌ی آدرس پنل (مستقیم، مودم یا آی‌پی ثابت) برقرار می‌شود.
  void onDisconnected() {
    _logger('onDisconnected', 'onDisconnected called');
    ConnectionKeeper.instance.onNetworkChanged();
  }

  void cancel() {
    _logger('cancel', 'Method called');
    _mSubscription?.cancel();
  }

  void _logger(String key, String value) {
    doLogGlobal('observe_connection. H:$hashCode', key, value);
  }
}
