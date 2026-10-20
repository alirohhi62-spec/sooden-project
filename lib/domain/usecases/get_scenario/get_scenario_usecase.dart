import '../../../data/data_sources/local_data_sources/database/model/scenario.dart';
import '../../../data/data_sources/local_data_sources/database/model/scenario_det.dart';

abstract class GetScenarioUseCase {
  Future<List<Scenario>?> getGeneralScenarios();
  Future<List<Scenario>> getScenarioBothFloorAndPlace(int locationId,String? placeCode,  String? floor);
  Future<List<Scenario>> getScenarioFloorAndPlaceAndGeneral(int locationId,String? placeCode,  String? floor);
  Future<List<ScenarioDet>> getByScenarioId(int scenarioId, String placeCode);
  Future<List<ScenarioDet>> getScenarioValuesOfAPlace(int scenarioId, String floor, String place);
  Future<List<ScenarioDet>> getScenarioDet(int scenarioId);

}

