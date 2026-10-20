import 'package:bms/presentation/logic/base_logic.dart';
import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';

import 'package:get/get.dart';

import '../../core/di/app_binding.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../../data/data_sources/remote_data_sources/socket/socket.dart';
import '../../presentation/screens/tabs/settings/pages/new_location_screen.dart';

class SettingsLogic extends BaseLogic{

  logout(){
    _logger('logout', "do logout");

    Get.find<AppDatabase>().clearWholeTable();

    ConnectionRequestsImpl.instance.destroyConnections();

    Get.offAll(() => NewLocationScreen(), binding: AppBindings());
  }

  void _logger(String key, String value) {
    doLog('settings_logic. H:$hashCode', key, value);
  }
}