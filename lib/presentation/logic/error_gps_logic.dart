import 'package:bms/core/di/app_binding.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../core/utils/util.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../screens/splash/splash_screen.dart';

class ErrorGpsLogic extends BaseLogic {
  @override
  onReady() async {
    super.onReady();
    _logger('onReady', 'Method called');
    _destroyConnection();
  }

  void _destroyConnection() {
    _logger('_disconnectSocket', 'Method called');
    ConnectionRequestsImpl.instance.destroyConnections();
  }

  void onTryAgain() {
    Get.offAll(() => SplashScreen(), binding: AppBindings());
  }

  void openGps() async {
    var isPageOpened = await Geolocator.openLocationSettings();
    if (!isPageOpened) {
      Utils.toast('تنظیمات باز نشد، لطفا بصورت دستی GPS را روشن کنید.', Toast.LENGTH_LONG);
    }
  }

  void _logger(String key, String value) {
    doLog('error_gps_logic. H:$hashCode', key, value);
  }
}
