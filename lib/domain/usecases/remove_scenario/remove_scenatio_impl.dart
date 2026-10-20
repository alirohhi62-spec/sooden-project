import 'package:bms/domain/usecases/remove_scenario/remove_scenatio.dart';
import 'package:get/get.dart';

import '../../../core/eventbus/event_bus_const.dart';
import '../../../core/eventbus/event_bus_model.dart';
import '../../../core/utils/globals.dart';
import '../../../data/data_sources/local_data_sources/database/app_database.dart';
import '../../../data/data_sources/local_data_sources/database/model/scenario.dart';

class RemoveScenarioUseCaseImpl extends RemoveScenarioUseCase {
  @override
  Future<void> removeScenario(Scenario scenario) async {
    var appDb = Get.find<AppDatabase>();
    await _doRemoveScenario(appDb, scenario.id);
    _emitUpdateEventScenario();
  }

  _doRemoveScenario(AppDatabase appDb, int? scenarioId) async {
    await appDb.scenarioDetDao.deleteAllSameRowsByKeyValue('scenarioId', scenarioId);
    await appDb.scenarioDao.deleteAllSameRowsByKeyValue('id', scenarioId);
  }

  void _emitUpdateEventScenario() {
    eventBus.fire(EventBusModel(event: EventBusConst.eventUpdatedScenario));
  }
}
