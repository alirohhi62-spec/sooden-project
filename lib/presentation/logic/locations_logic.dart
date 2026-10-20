import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/data/data_sources/remote_data_sources/socket/socket.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/presentation/logic/base_logic.dart';
import 'package:get/get.dart';

import '../../core/di/app_binding.dart';
import '../../data/data_sources/remote_data_sources/socket/connection_requests/connection_requests_impl.dart';
import '../screens/splash/splash_screen.dart';


class LocationsLogic extends BaseLogic {
  List<Location> locationList = [];
  late final LocationRepository _mLocRepo = Get.find<LocationRepository>();

  @override
  onInit() async {
    _getLocations();

    super.onInit();
  }

  _getLocations() async {
    locationList = await Get.find<LocationRepository>().getLocations();

    update();
  }

  void connectToLocation(Location location) async {
    await _mLocRepo.updateSelectedLocation(location.id!);
    _restartApp();
  }

  _restartApp() {
    ConnectionRequestsImpl.instance.destroyConnections();
    Get.offAll(() => SplashScreen(), binding: AppBindings());
  }

  deleteLocation(Location location) async {
    if (location.isSelected! && locationList.length > 1) {
      locationList.remove(location);
      await _mLocRepo.updateSelectedLocation(locationList[0].id!);
    }

   await _mLocRepo.deleteLocation(location);
    _logger('deleteLocation', "do clear data");

    ConnectionRequestsImpl.instance.destroyConnections();

    _getLocations();
  }

  void _logger(String key, String value) {
    doLog('settings_logic. H:$hashCode', key, value);
  }


}
