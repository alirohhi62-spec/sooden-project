import 'package:network_info_plus/network_info_plus.dart';

import '../../../../../../../../core/utils/communication_constants.dart';
import '../../../../../../../../core/utils/globals.dart';
import '../../../../../../../enums/connection_error_code.dart';
import '../../../../../../local_data_sources/database/model/location.dart';
import '../../../result.dart';

class IpConfig {
  late Function(Result) _mResultCallback;

  Future<String?> getConnectionInfo(Location location, Function(Result) resultCallback) async {
    _mResultCallback = resultCallback;
    String? ip;
    String? wifiName = await NetworkInfo().getWifiName();

    _logger('getConnectionInfo', 'wifiName = $wifiName');
    if (wifiName != null && wifiName.isNotEmpty) {
      wifiName = wifiName.substring(1, wifiName.length - 1);

      _logger('getConnectionInfo', 'Exact wifiName = $wifiName');

      _logger('getConnectionInfo', 'Location wifiName = ${location.panelWifiName}');

      if (wifiName == location.panelWifiName) {
        // On direct connect to the device
        ip = SocketConstants.ip;
        _logger('getConnectionInfo', 'ip = $ip');
      } else if (wifiName == location.modemName) {
        // On a known wifi that is already connect to the device
        ip = getIpOnModem(location);
      } else { // On a new wifi -> try ip static
        ip = getIpStatic(location);
      }
    } else { // On Mobile network -> try ip static
      ip = getIpStatic(location);
    }
    return ip;
  }

  String? getIpOnModem(Location location) {
    _logger('getIpOnModem', 'ip = ${location.panelIpOnModem}');

    if (location.panelIpOnModem != null) {
      return location.panelIpOnModem!;
    } else {
      _mResultCallback.call(Result.failure(ConnectionErrorCode.unableToGetIpOnModem));
      return null;
    }
  }

  String? getIpStatic(Location location) {
    _logger('getIpStatic', 'ip = ${location.staticIp}');

    if (location.staticIp != null) {
      return location.staticIp!;
    } else {
      _mResultCallback.call(Result.failure(ConnectionErrorCode.unableToGetIpStatic));
      return null;
    }
  }

  void _logger(String key, String value) {
    doLogGlobal('socket_config. H:$hashCode', key, value);
  }
}
