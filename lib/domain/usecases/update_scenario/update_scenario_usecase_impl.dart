import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:get/get.dart';

import '../../../core/eventbus/event_bus_const.dart';
import '../../../core/eventbus/event_bus_model.dart';
import '../../../core/utils/globals.dart';
import '../../../data/repositories/scenario_repository.dart';
import 'update_scenario_usecase.dart';

class UpdateScenarioUseCaseImpl implements UpdateScenarioUseCase {
  late final ScenarioRepository _scenarioRepository = Get.find<ScenarioRepository>();

  @override
  Future<int> insertScenario(Scenario scenario) {
    return _scenarioRepository.insertScenario(scenario);
  }

  @override
  Future<int> insertScenarioDet(ScenarioDet scenarioDet) {
    return _scenarioRepository.insertScenarioDet(scenarioDet);
  }

  @override
  renameScenario(Scenario scenario, String newName) async {
    scenario.name = newName;
    await _scenarioRepository.updateScenario(scenario);
    _emitUpdateEventScenario();
  }

  void _emitUpdateEventScenario() {
    eventBus.fire(EventBusModel(event: EventBusConst.eventUpdatedScenario));
  }

  @override
  changeScenarioDetValue(ScenarioDet det, String newValue) {
    det.value = newValue;

    _scenarioRepository.updateScenarioDet(det);
  }

  void _logger(String key, String value) {
    doLogGlobal('update_scenario_usecase_impl. H:$hashCode', key, value);
  }
}
