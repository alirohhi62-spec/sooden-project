
import 'package:bms/data/data_sources/local_data_sources/database/app_database.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:get/get.dart';

class ScenarioRepository {


  Future<int> insertScenario(Scenario scenario) =>
      Get.find<AppDatabase>().scenarioDao.insert(scenario);

  Future<int> insertScenarioDet(ScenarioDet scenarioDet) =>
      Get.find<AppDatabase>().scenarioDetDao.insert(scenarioDet);

  Future<List<Scenario>> getGeneralScenarios(int id) {
    return Get.find<AppDatabase>().scenarioDao.getGeneralScenarios(id);
  }


  Future<List<Scenario>> getScenarioBothFloorAndPlace(int locationId, String? placeCode, String? floor) {
    return Get.find<AppDatabase>().scenarioDao
        .getScenarioBothFloorAndPlace(locationId: locationId, placeCode: placeCode, floor: floor);
  }

  Future<List<Scenario>> getScenarioFloorAndPlaceAndGeneral(int locationId, String? placeCode, String? floor) {
    return Get.find<AppDatabase>().scenarioDao
        .getScenarioFloorAndPlaceAndGeneral(locationId: locationId, placeCode: placeCode, floor: floor);
  }

  Future<List<ScenarioDet>> getByScenarioId(int scenarioId, String placeCode) =>
      Get.find<AppDatabase>().scenarioDetDao.getByScenarioId(scenarioId, placeCode);

  Future<List<ScenarioDet>> getScenarioValuesOfAPlace(int scenarioId, String floor, String place) =>
      Get.find<AppDatabase>().scenarioDetDao.getScenarioValuesOfAPlace(scenarioId, floor, place);

  updateScenario(Scenario scenario) {
    Get.find<AppDatabase>().scenarioDao.update(scenario);
  }

  updateScenarioDet(ScenarioDet det){
    Get.find<AppDatabase>().scenarioDetDao.update(det);
  }

  Future<List<ScenarioDet>> getScenarioDet(int scenarioId) =>
      Get.find<AppDatabase>().scenarioDetDao.getScenarioDet(scenarioId);

}
