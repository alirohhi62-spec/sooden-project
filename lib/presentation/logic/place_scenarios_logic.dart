import 'dart:async';

import 'package:bms/core/utils/communication_constants.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/place.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario.dart';
import 'package:bms/data/data_sources/local_data_sources/database/model/scenario_det.dart';
import 'package:bms/data/enums/headline_code.dart';
import 'package:bms/domain/usecases/get_scenario/get_scenario_usecase.dart';
import 'package:bms/domain/usecases/get_scenario/get_scenario_usecase_impl.dart';
import 'package:bms/domain/usecases/update_scenario/update_scenario_usecase_impl.dart';
import 'package:bms/presentation/logic/base_logic.dart';

import '../../core/eventbus/event_bus_const.dart';
import '../../core/eventbus/event_bus_model.dart';
import '../../core/utils/globals.dart';
import '../../data/enums/floor_code.dart';
import '../../domain/usecases/remove_scenario/remove_scenatio_impl.dart';

class PlaceScenariosLogic extends BaseLogic {
  late Place place;
  late FloorCode floor;
  late int currentLocationId;
  late GetScenarioUseCase _getScenarioUseCase;
  List<Scenario> scenarios = [];
  Scenario? currentScenario;
  List<ScenarioDet> devicesInScenario = [];
  StreamSubscription<EventBusModel>? _mSubscription;

  PlaceScenariosLogic({required this.place, required this.floor, required this.currentLocationId});

  @override
  void onInit() {
    _initVariable();
    _listenEventBus();
    _initScenariosHeader();

    super.onInit();
  }

  void _initVariable() {
    _getScenarioUseCase = GetScenarioUseCaseImpl();
  }

  void _listenEventBus() {
    _mSubscription = eventBus.on<EventBusModel>().listen((event) {
      if (event.event == EventBusConst.eventUpdatedScenario) {
        _onEventCreatedScenarioHappened();
      }
    });
  }

  _onEventCreatedScenarioHappened() {
    _logger('_onEventCreatedScenarioHappened', "No Value");

    _initScenariosHeader();
  }

  _initScenariosHeader() async {
    _logger(
        '_initScenariosHeader',
        'currentLocationId $currentLocationId '
            'place.code ${place.code} '
            'floor.value ${floor.value}');

    scenarios = await _getScenarioUseCase.getScenarioFloorAndPlaceAndGeneral(
        currentLocationId, place.code, floor.value);
    currentScenario = scenarios[0];

    _initLightsForCurrentScenarios();
  }

  changeScenario(Scenario scenario) {
    _logger(
        'changeScenario',
        'scenario.name ${scenario.name} '
            'scenario.code ${scenario.place} '
            'scenario.floor ${scenario.floor}');
    currentScenario = scenario;
    devicesInScenario.clear();
    update();
    _initLightsForCurrentScenarios();
  }

  _initLightsForCurrentScenarios() async {
    devicesInScenario =
        await _getScenarioUseCase.getByScenarioId(currentScenario!.id!, place.code!);

    update();
  }

  changeValue(ScenarioDet det, String newValue) {
    UpdateScenarioUseCaseImpl().changeScenarioDetValue(det, newValue);

    update();
  }

  void onPopInvoked(bool didPop) {
    _logger('onPopInvoked', 'didPop: $didPop');
  }

  bool isLight(int index) {
    return devicesInScenario[index].headline == HeadlineCode.light.value;
  }

  bool isHiddenLight(int index) {
    return devicesInScenario[index].code == SocketConstants.hiddenDevice;
  }

  void removeScenario(scenario) {
    RemoveScenarioUseCaseImpl().removeScenario(scenario);
  }

  renameScenario(Scenario currentScenario, String newName) {
    UpdateScenarioUseCaseImpl().renameScenario(currentScenario, newName);
  }

  getValue(ScenarioDet scenarioDet) {
    return scenarioDet.value;
  }

  @override
  void onClose() {
    _logger('onClose', 'method called.');
    _mSubscription?.cancel(); // Cancel the subscription
    super.onClose();
  }

  void _logger(String key, String value) {
    doLog('place_scenarios_logic. H:$hashCode', key, value);
  }
}
