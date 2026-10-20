import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/device.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:get/get.dart';

class LocationRepository {
  var appDb = Get.find<AppDatabase>();

  Future<int> insertIfNotExistForTestData(Location location ) async {
      return insertLocation(location);
  }

  Future<int> insertIfNotExist(Location location ) async {
    bool exist = await appDb.locationDao.isExist(mac: location.mac!);

    if (!exist) {
      return insertLocation(location);
    }

    return 0;
  }

  Future<int> insertLocation(Location location) {
    return appDb.locationDao.insert(location);
  }

  Future<Location?> getLocation({required int id}) {
    return appDb.locationDao.get(id);
  }

  updateLocation(Location location) {
    appDb.locationDao.update(location);
  }

  Future<void> deleteLocation(Location location) async {
    //<editor-fold desc="delete devices">
    List<Device> locationDevices =
        await appDb.deviceDao.getDevicesByLocation(locationId: location.id!);
    for (var device in locationDevices) {
      appDb.deviceDao.deleteAllSameRowsByKeyValue('id', device.id!);
    }
    //</editor-fold>

    //<editor-fold desc="delete places">
    List<Place> locationPlaces = await appDb.placeDao.getPlaces(locationId: location.id!);
    for (var element in locationPlaces) {
      appDb.placeDao.deleteAllSameRowsByKeyValue('id', element.id!);
    }
    //</editor-fold>

    List<Scenario> scenarios = await appDb.scenarioDao.getAllScenarios(location.id!);
    for (var elementScenario in scenarios) {
      await appDb.scenarioDetDao.deleteAllSameRowsByKeyValue('scenarioId', elementScenario.id!);
    }
    await appDb.scenarioDao.deleteAllSameRowsByKeyValue('locationId', location.id!);

    return appDb.locationDao.deleteAllSameRowsByKeyValue('id', location.id!);
  }

  Future<List<Location>> getLocations() {
    return appDb.locationDao.all();
  }

  Future<Location?> getUserSelectedLocation() {
    return appDb.locationDao.getSelectedOrFirstLocation();
  }

  updateSelectedLocation(int id) async {
    await appDb.locationDao.updateSelectedLocation(id);
  }
}
