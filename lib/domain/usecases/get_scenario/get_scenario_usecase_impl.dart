import 'package:bms/data/data_sources/local_data_sources/database/model/location.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:bms/data/repositories/location_repository.dart';
import 'package:bms/data/repositories/scenario_repository.dart';
import 'package:get/get.dart';

import '../../../core/utils/globals.dart';
import 'get_scenario_usecase.dart';

class GetScenarioUseCaseImpl implements GetScenarioUseCase {
  late final ScenarioRepository scenarioRepository = Get.find<ScenarioRepository>();
  late final LocationRepository _mLocRepo = Get.find<LocationRepository>();

  GetScenarioUseCaseImpl();

  @override
  Future<List<Scenario>?> getGeneralScenarios() async {
    Location? selectedLoc = await _mLocRepo.getUserSelectedLocation();
    if (selectedLoc != null) {
      return scenarioRepository.getGeneralScenarios(selectedLoc.id!);
    }
    return null;
  }

  @override
  Future<List<ScenarioDet>> getByScenarioId(int scenarioId, String placeCode) {
    return scenarioRepository.getByScenarioId(scenarioId, placeCode);
  }

  @override
  Future<List<ScenarioDet>> getScenarioDet(int scenarioId) {
    return scenarioRepository.getScenarioDet(scenarioId);
  }

  @override
  Future<List<ScenarioDet>> getScenarioValuesOfAPlace(int scenarioId, String floor, String place) {
    return scenarioRepository.getScenarioValuesOfAPlace(scenarioId, floor, place);
  }

  void _logger(String key, String value) {
    doLogGlobal('get_scenario_usecase_impl. H:$hashCode', key, value);
  }

  @override
  Future<List<Scenario>> getScenarioBothFloorAndPlace(
      int locationId, String? placeCode, String? floor) async {
    var dataList =
        await scenarioRepository.getScenarioBothFloorAndPlace(locationId, placeCode, floor);
    return dataList;
  }

  @override
  Future<List<Scenario>> getScenarioFloorAndPlaceAndGeneral(
      int locationId, String? placeCode, String? floor) async {
    var dataList =
        await scenarioRepository.getScenarioFloorAndPlaceAndGeneral(locationId, placeCode, floor);
    return dataList;
  }
}
