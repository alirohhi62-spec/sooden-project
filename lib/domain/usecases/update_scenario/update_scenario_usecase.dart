

import '../../../data/data_sources/local_data_sources/database/model/scenario.dart';
import '../../../data/data_sources/local_data_sources/database/model/scenario_det.dart';

abstract class UpdateScenarioUseCase {
  Future<int> insertScenario(Scenario scenario);
  Future<int> insertScenarioDet(ScenarioDet scenarioDet);
  renameScenario(Scenario scenario, String newName) ;
  changeScenarioDetValue(ScenarioDet det, String newValue);
}

