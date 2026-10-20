import 'dart:async';

import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/domain/usecases/get_scenario/get_scenario_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/globals.dart';
import '../../domain/usecases/run_scenario/run_scenario_usecase_impl.dart';

class ScenarioLogic extends BaseLogic {
  List<Scenario>? generalScenarios = [];
 StreamSubscription<EventBusModel>? _mSubscription;

  @override
  void onInit() {
    _initScenarios();

    super.onInit();
  }

  @override
  onReady() async {
    _listenEventBus();
    super.onReady();
  }

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      _logger('_listenEventBus', 'event: ${event.event}');

      switch (event.event) {
        case EventBusConst.eventUpdatedScenario:
          _onEventUpdatedScenarioHappened();
          break;
      }
    });
  }

  _onEventUpdatedScenarioHappened() {
    _logger('_onEventCreatedScenarioHappened', "No Value");

    _initScenarios();
  }

  _initScenarios() async {
    generalScenarios = await GetScenarioUseCaseImpl().getGeneralScenarios();

    update();
  }

  runScenario(Scenario scenario) async {
    final globalScenario = RunScenarioUseCaseImpl();
    globalScenario.runScenario(scenario);
    update();
  }
  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }
  void _logger(String key, String value) {
    doLog('scenario_logic. H:$hashCode', key, value);
  }
}
