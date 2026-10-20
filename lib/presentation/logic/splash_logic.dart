import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import '../../core/di/app_binding.dart';
import '../../data/data_sources/local_data_sources/database/app_database.dart';
import '../../data/data_sources/local_data_sources/pref/pref_helper.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../screens/tabs/main_screen.dart';
import '../screens/tabs/settings/pages/new_location_screen.dart';

class SplashLogic extends BaseLogic {
  @override
  void onInit() async {
    if (await checkForPreEstablishConnection()) {
      _preEstablishConnection();
    }
    super.onInit();
  }

  Future<bool>  checkForPreEstablishConnection() async {
    if (!isUserNameEmpty() && !(await  isLocationEmpty())) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _preEstablishConnection() async {
    _logger('_preEstablishConnection', 'Method called');
    ConnectionRequestsImpl.instance.multiConnectionRequest();
  }

  isUserNameEmpty() {
    return PrefHelper.getString(PrefHelper.userDisplayName).isEmpty;
  }

  Future<bool>  isLocationEmpty() async {
    return (await Get.find<AppDatabase>().locationDao.count()) == 0;
  }

  storeUserName(String userName) {
    PrefHelper.put(PrefHelper.userDisplayName, userName);
  }

  goNextScreen() async {
    if (await isLocationEmpty()) {
      Get.off(() => NewLocationScreen(), binding: AppBindings());
      _logger('goNextScreen', 'Start NewLocationScreen');
    } else {
      Get.off(() => MainScreen(), binding: AppBindings());
      _logger('goNextScreen', 'Start MainScreen');
    }
  }

  void _logger(String key, String value) {
    doLog('splash_logic.dart. H:$hashCode', key, value);
  }
}
